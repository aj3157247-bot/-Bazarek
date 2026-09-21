import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

String currentWebPath() => html.window.location.pathname ?? '/';

void setBrowserPath(String path) {
  try {
    html.window.history.pushState(null, '', path);
  } catch (_) {}
}

String _absoluteUrl(String path) {
  final base = html.window.location.origin;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '$base${path.startsWith('/') ? path : '/$path'}';
}

void _setMeta(String name, String content, {bool property = false}) {
  final selector = property
      ? 'meta[property="${name.replaceAll('"', '\\"')}"]'
      : 'meta[name="${name.replaceAll('"', '\\"')}"]';
  html.Element? el = html.document.querySelector(selector);
  if (el == null) {
    el = html.MetaElement()
      ..setAttribute(property ? 'property' : 'name', name);
    html.document.head?.append(el);
  }
  el.setAttribute('content', content);
}

void _setCanonical(String url) {
  html.LinkElement? link = html.document.querySelector('link[rel="canonical"]') as html.LinkElement?;
  if (link == null) {
    link = html.LinkElement()..rel = 'canonical';
    html.document.head?.append(link);
  }
  link.href = url;
}

void _setJsonLd(String id, Map<String, dynamic> data) {
  final selector = 'script[data-bazarek-seo="$id"]';
  html.ScriptElement? script = html.document.querySelector(selector) as html.ScriptElement?;
  if (script == null) {
    script = html.ScriptElement()
      ..type = 'application/ld+json'
      ..setAttribute('data-bazarek-seo', id);
    html.document.head?.append(script);
  }
  script.text = jsonEncode(data);
}

void setWebSeo({
  required String title,
  required String description,
  String? urlPath,
  String? imageUrl,
  Map<String, dynamic>? product,
}) {
  final path = urlPath ?? currentWebPath();
  final canonical = _absoluteUrl(path);
  html.document.title = title;
  _setMeta('description', description);
  _setMeta('robots', 'index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1');
  _setMeta('og:type', product == null ? 'website' : 'product', property: true);
  _setMeta('og:title', title, property: true);
  _setMeta('og:description', description, property: true);
  _setMeta('og:url', canonical, property: true);
  _setMeta('og:locale', 'fa_AF', property: true);
  if (imageUrl != null && imageUrl.isNotEmpty) {
    _setMeta('og:image', imageUrl, property: true);
  }
  _setMeta('twitter:card', 'summary_large_image');
  _setMeta('twitter:title', title);
  _setMeta('twitter:description', description);
  if (imageUrl != null && imageUrl.isNotEmpty) _setMeta('twitter:image', imageUrl);
  _setCanonical(canonical);

  _setJsonLd('webpage', {
    '@context': 'https://schema.org',
    '@type': 'WebPage',
    '@id': '$canonical#webpage',
    'url': canonical,
    'name': title,
    'description': description,
    'inLanguage': 'fa-AF',
  });

  if (product != null) {
    final name = (product['title'] ?? title).toString();
    final desc = (product['description'] ?? description).toString();
    final image = imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : <String>[];
    final price = num.tryParse(product['price']?.toString() ?? '');
    final currency = (product['currency']?.toString().toUpperCase() == 'USD') ? 'USD' : 'AFN';
    final offers = <String, dynamic>{
      '@type': 'Offer',
      'url': canonical,
      'priceCurrency': currency,
      if (price != null) 'price': price,
      'availability': 'https://schema.org/InStock',
    };
    _setJsonLd('product', {
      '@context': 'https://schema.org',
      '@type': 'Product',
      'name': name,
      'description': desc.length > 5000 ? desc.substring(0, 5000) : desc,
      if (image.isNotEmpty) 'image': image,
      'offers': offers,
    });
  } else {
    final old = html.document.querySelector('script[data-bazarek-seo="product"]');
    old?.remove();
  }
}

Future<bool> shareWeb({
  required String title,
  required String text,
  required String url,
}) async {
  try {
    final navigator = html.window.navigator;
    final canShare = js_util.getProperty<dynamic>(navigator, 'share');
    if (canShare == null) return false;
    // navigator.share انتظار یک Object واقعی جاوااسکریپت دارد؛ jsify کردن داده‌ها
    // از شکست بی‌صدای Web Share در بعضی نسخه‌های Android/Chrome جلوگیری می‌کند.
    final shareData = js_util.jsify(<String, String>{
      'title': title,
      'text': text,
      'url': url,
    });
    await js_util.promiseToFuture<dynamic>(
      js_util.callMethod<dynamic>(navigator, 'share', [shareData]),
    );
    return true;
  } catch (_) {
    return false;
  }
}
