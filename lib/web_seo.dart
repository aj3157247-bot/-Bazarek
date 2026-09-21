import 'dart:async';

import 'web_seo_stub.dart'
    if (dart.library.html) 'web_seo_html.dart' as impl;

String currentWebPath() => impl.currentWebPath();

void setBrowserPath(String path) => impl.setBrowserPath(path);

void setWebSeo({
  required String title,
  required String description,
  String? urlPath,
  String? imageUrl,
  Map<String, dynamic>? product,
}) {
  impl.setWebSeo(
    title: title,
    description: description,
    urlPath: urlPath,
    imageUrl: imageUrl,
    product: product,
  );
}

Future<bool> shareWeb({
  required String title,
  required String text,
  required String url,
}) {
  return impl.shareWeb(title: title, text: text, url: url);
}
