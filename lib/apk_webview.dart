import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

const _bazarekWebUrl = 'https://bazarek-web.onrender.com/';

class BazarekWebViewApp extends StatefulWidget {
  const BazarekWebViewApp({super.key});

  @override
  State<BazarekWebViewApp> createState() => _BazarekWebViewAppState();
}

class _BazarekWebViewAppState extends State<BazarekWebViewApp> {
  late final WebViewController _controller;
  late final Widget _webView;
  Timer? _loadTimer;
  bool _loading = true;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();

    final controllerParams = AndroidWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(controllerParams)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Mobile) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/140.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
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
            _loadTimer = Timer(const Duration(seconds: 25), () {
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
                _error = null;
                _progress = 100;
              });
            }
          },
          onHttpError: (error) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = 'خطای سرور بازارک (${error.response?.statusCode ?? 'نامشخص'})';
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              _loadTimer?.cancel();
              if (mounted) {
                setState(() {
                  _loading = false;
                  _error = 'اتصال به سایت بازارک برقرار نشد. اینترنت را بررسی کنید.';
                });
              }
            }
          },
        ),
      );

    final widgetParams = AndroidWebViewWidgetCreationParams(
      controller: _controller.platform,
      displayWithHybridComposition: true,
    );
    _webView = WebViewWidget.fromPlatformCreationParams(widgetParams);

    _controller.loadRequest(Uri.parse(_bazarekWebUrl));
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _error = null;
      _loading = true;
      _progress = 0;
    });
    await _controller.loadRequest(Uri.parse(_bazarekWebUrl));
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    await SystemNavigator.pop();
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
              Positioned.fill(child: _webView),
              if (_loading)
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
                            const Icon(Icons.wifi_off, size: 56),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh),
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
