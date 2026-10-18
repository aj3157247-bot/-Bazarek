import 'dart:async';

import 'analytics.dart';
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
  // هر صفحه‌ای که سئو می‌گیرد، یک بازدید ثبت می‌کند؛ آگهی‌ها علاوه بر آن «بازدید آگهی» هم دارند.
  try {
    final path = urlPath ?? currentWebPath();
    Analytics.track('page_view', path: path, category: product?['category']?.toString() ?? '');
    if (product != null && (product['id']?.toString() ?? '').isNotEmpty) {
      Analytics.track(
        'listing_view',
        path: path,
        listingId: product['id'].toString(),
        category: product['category']?.toString() ?? '',
      );
    }
  } catch (_) {}
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
