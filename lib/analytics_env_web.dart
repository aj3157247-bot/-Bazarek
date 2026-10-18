import 'dart:html' as html;

/// دامنه‌ی منبع ورود (مثلاً google.com)؛ اگر از خود سایت آمده باشد خالی است.
String referrerHost() {
  try {
    final ref = html.document.referrer;
    if (ref.isEmpty) return '';
    final host = Uri.parse(ref).host.toLowerCase();
    if (host.isEmpty || host == html.window.location.hostname) return '';
    return host.startsWith('www.') ? host.substring(4) : host;
  } catch (_) {
    return '';
  }
}

String deviceType() {
  try {
    return (html.window.innerWidth ?? 0) < 700 ? 'mobile' : 'desktop';
  } catch (_) {
    return 'mobile';
  }
}
