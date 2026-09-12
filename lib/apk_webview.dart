import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

const _bazarekWebOrigin = 'https://bazarek-web.onrender.com';

class BazarekWebViewApp extends StatefulWidget {
  const BazarekWebViewApp({super.key});

  @override
  State<BazarekWebViewApp> createState() => _BazarekWebViewAppState();
}

class _BazarekWebViewAppState extends State<BazarekWebViewApp> {
  InAppWebViewController? _controller;
  Timer? _loadTimer;
  bool _loading = true;
  int _progress = 0;
  String? _error;

  Uri _freshUri() => Uri.parse('$_bazarekWebOrigin/?bazarek_app=1&shell=android&v=${DateTime.now().millisecondsSinceEpoch}');

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  void _startLoadWatchdog() {
    _loadTimer?.cancel();
    _loadTimer = Timer(const Duration(seconds: 35), () {
      if (!mounted || !_loading) return;
      setState(() {
        _loading = false;
        _error = 'بارگذاری بازارک بیشتر از حد معمول طول کشید.';
      });
    });
  }

  void _finishLoading() {
    _loadTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _progress = 100;
      _error = null;
    });
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _progress = 0;
      _error = null;
    });
    _startLoadWatchdog();
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(_freshUri().toString())));
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'اتصال به سایت بازارک برقرار نشد. اینترنت را بررسی کنید.'; });
    }
  }

  Future<bool> _openExternal(WebUri url) async {
    final uri = Uri.tryParse(url.toString());
    if (uri == null) return false;
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    if (uri.scheme == 'tel' || uri.scheme == 'mailto' || uri.scheme == 'sms' || uri.scheme == 'whatsapp' || uri.scheme == 'geo') {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final controller = _controller;
        if (controller != null && await controller.canGoBack()) {
          await controller.goBack();
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_freshUri().toString())),
              initialSettings: InAppWebViewSettings(
                useShouldOverrideUrlLoading: true,
                javaScriptEnabled: true,
                javaScriptCanOpenWindowsAutomatically: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                supportZoom: false,
                builtInZoomControls: false,
                displayZoomControls: false,
                useWideViewPort: true,
                loadWithOverviewMode: true,
                userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36',
                clearCache: false,
                cacheEnabled: true,
                transparentBackground: false,
                hardwareAcceleration: true,
                offscreenPreRaster: true,
                useHybridComposition: true,
                cacheMode: CacheMode.LOAD_NO_CACHE,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onLoadStart: (controller, url) {
                _startLoadWatchdog();
                if (mounted) setState(() { _loading = true; _progress = 0; _error = null; });
              },
              onProgressChanged: (controller, progress) {
                if (mounted) setState(() => _progress = progress);
              },
              onLoadStop: (controller, url) {
                _finishLoading();
              },
              onReceivedError: (controller, request, error) {
                if (!mounted) return;
                if (request.isForMainFrame == true) {
                  _loadTimer?.cancel();
                  setState(() { _loading = false; _error = 'اتصال به سایت بازارک برقرار نشد. اینترنت را بررسی کنید.'; });
                }
              },
              onReceivedHttpError: (controller, request, response) {
                if (!mounted || request.isForMainFrame != true) return;
                final code = response.statusCode;
                if (code != null && code >= 400) {
                  setState(() { _loading = false; _error = 'خطای سرور بازارک ($code)'; });
                }
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url;
                if (url == null) return NavigationActionPolicy.ALLOW;
                final host = url.host.toLowerCase();
                final trusted = host == 'bazarek-web.onrender.com' || host.endsWith('.bazarek-web.onrender.com');
                if (trusted && (url.scheme == 'http' || url.scheme == 'https')) {
                  return NavigationActionPolicy.ALLOW;
                }
                final handled = await _openExternal(url);
                return handled ? NavigationActionPolicy.CANCEL : NavigationActionPolicy.ALLOW;
              },
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(resources: request.resources, action: PermissionResponseAction.GRANT);
              },
            ),
            if (_loading)
              Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(minHeight: 3, value: _progress > 0 ? _progress / 100 : null),
              ),
            if (_error != null)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.white,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.wifi_off_rounded, size: 56),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 18),
                        FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('تلاش دوباره')),
                      ]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
