import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

// The APK is intentionally a thin shell around the live Bazarek Web app.
// Keep the website as the single source of truth: UI/features can change on
// bazarek-web.onrender.com without publishing a new APK.
const _bazarekWebOrigin = 'https://bazarek-web.onrender.com';
const _bazarekWebUrl = '$_bazarekWebOrigin/';

class BazarekWebViewApp extends StatefulWidget {
  const BazarekWebViewApp({super.key});

  @override
  State<BazarekWebViewApp> createState() => _BazarekWebViewAppState();
}

class _BazarekWebViewAppState extends State<BazarekWebViewApp>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  late final Widget _webView;
  final ImagePicker _imagePicker = ImagePicker();

  Timer? _loadTimer;
  bool _loading = true;
  bool _booting = true;
  int _progress = 0;
  String? _error;
  bool _externalLaunchInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWebView();
  }

  Future<void> _initWebView() async {
    final controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setVerticalScrollBarEnabled(false)
      ..enableZoom(false)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Mobile) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/140.0.0.0 Mobile Safari/537.36 BazarekApp/1.2',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            _loadTimer?.cancel();
            if (mounted) {
              setState(() {
                _loading = true;
                _error = null;
                _progress = 0;
              });
            }
            _loadTimer = Timer(const Duration(seconds: 30), () {
              if (!mounted || !_loading) return;
              setState(() {
                _loading = false;
                _error = 'بارگذاری بازارک بیشتر از حد معمول طول کشید.';
              });
            });
          },
          onPageFinished: (_) {
            _loadTimer?.cancel();
            if (mounted) {
              setState(() {
                _loading = false;
                _booting = false;
                _error = null;
                _progress = 100;
              });
            }
          },
          onHttpError: (error) {
            if (mounted) {
              setState(() {
                _loading = false;
                _booting = false;
                _error =
                    'خطای سرور بازارک (${error.response?.statusCode ?? 'نامشخص'})';
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              _loadTimer?.cancel();
              if (mounted) {
                setState(() {
                  _loading = false;
                  _booting = false;
                  _error =
                      'اتصال به سایت بازارک برقرار نشد. اینترنت را بررسی کنید.';
                });
              }
            }
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      await android.setUseWideViewPort(true);
      await android.setOverScrollMode(WebViewOverScrollMode.never);
      await android.setMediaPlaybackRequiresUserGesture(false);
      await android.setMixedContentMode(MixedContentMode.neverAllow);
      await android.setAllowContentAccess(true);
      await android.setAllowFileAccess(true);
      await android.setOnShowFileSelector(_selectFiles);
    }

    _controller = controller;
    _webView = WebViewWidget(controller: _controller);

    if (mounted) setState(() {});
    await _loadFreshWebsite();
  }

  Future<List<String>> _selectFiles(FileSelectorParams params) async {
    try {
      final accepts = params.acceptTypes
          .expand((value) => value.split(','))
          .map((value) => value.trim().toLowerCase())
          .where((value) => value.isNotEmpty)
          .toList();
      final wantsImage = accepts.isEmpty || accepts.any(
        (type) => type == 'image/*' || type.startsWith('image/'),
      );

      if (params.isCaptureEnabled && wantsImage) {
        final captured = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 92,
          maxWidth: 2400,
        );
        return captured?.path == null ? <String>[] : <String>[captured!.path];
      }

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: params.mode == FileSelectorMode.openMultiple,
        type: FileType.image,
      );
      return result?.files
              .map((file) => file.path)
              .whereType<String>()
              .toList() ??
          <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  Future<NavigationDecision> _onNavigationRequest(
    NavigationRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    if (_isInternalBazarekUrl(uri)) {
      return NavigationDecision.navigate;
    }

    if (_isExternalScheme(uri.scheme)) {
      await _openExternal(uri);
      return NavigationDecision.prevent;
    }

    // Keep unknown HTTPS destinations out of the embedded app. This makes the
    // APK behave like a native shell while links such as tel:/mailto: still
    // open with the user's installed apps.
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      await _openExternal(uri);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.prevent;
  }

  bool _isInternalBazarekUrl(Uri uri) {
    return uri.scheme == 'https' && uri.host == 'bazarek-web.onrender.com';
  }

  bool _isExternalScheme(String scheme) {
    return <String>{'tel', 'mailto', 'sms', 'whatsapp', 'geo'}
        .contains(scheme.toLowerCase());
  }

  Future<void> _openExternal(Uri uri) async {
    if (_externalLaunchInProgress) return;
    _externalLaunchInProgress = true;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } finally {
      _externalLaunchInProgress = false;
    }
  }

  Future<void> _loadFreshWebsite() async {
    try {
      // Do not clear local storage: that would remove login/session data.
      // Clearing WebView HTTP cache plus a cache-busting query makes the APK
      // prefer the newest deployed Web build without requiring an APK update.
      await _controller.clearCache();
      final uri = Uri.parse(_bazarekWebUrl).replace(
        queryParameters: <String, String>{
          'bazarek_app': '1',
          'shell': 'android',
          'v': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      await _controller.loadRequest(uri);
    } catch (_) {
      if (mounted) {
        setState(() {
          _booting = false;
          _loading = false;
          _error = 'بازارک فعلاً در دسترس نیست. لطفاً دوباره تلاش کنید.';
        });
      }
    }
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _error = null;
      _loading = true;
      _booting = true;
      _progress = 0;
    });
    await _loadFreshWebsite();
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    await SystemNavigator.pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading) {
      // Refresh the live shell when the user returns to the app, without
      // destroying the page/session state.
      _controller.reload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              if (!_booting || _error != null)
                Positioned.fill(child: _webView),
              if (_booting && _error == null)
                const Positioned.fill(child: _BazarekSplash()),
              if (!_booting && _loading)
                Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    value: _progress > 0 ? _progress / 100 : null,
                  ),
                ),
              if (_error != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 58,
                              color: Color(0xFF0066FF),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'بازارک',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0B2A55),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('تلاش دوباره'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Keeps the initial shell deliberately tiny and independent of the website.
class _BazarekSplash extends StatelessWidget {
  const _BazarekSplash();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0066FF), Color(0xFF003B99)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 30,
                    color: Color(0x55000000),
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: Image.asset(
                  'assets/icon/bazarek_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.shopping_bag_rounded,
                    size: 62,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'بازارک',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'خرید و فروش آسان در سراسر افغانستان',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 26),
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

