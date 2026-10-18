import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_env_stub.dart'
    if (dart.library.html) 'analytics_env_web.dart' as env;

/// آمار داخلی بازارک؛ بدون سرویس خارجی و بدون اطلاعات شخصی.
/// فقط یک شناسه‌ی تصادفی برای هر مرورگر ذخیره می‌شود تا «بازدیدکننده‌ی یکتا» شمرده شود.
class Analytics {
  /// در main() مقداردهی می‌شود: '<baseUrl>/analytics/event'
  static String endpoint = 'https://bazarek.onrender.com/api/analytics/event';

  static String? _visitorId;
  static Timer? _searchTimer;
  static String _lastKey = '';
  static DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<String> _getVisitorId() async {
    if (_visitorId != null) return _visitorId!;
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString('bz_visitor_id');
      if (id == null || id.length < 8) {
        const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
        final r = Random.secure();
        id = List.generate(22, (_) => chars[r.nextInt(chars.length)]).join();
        await prefs.setString('bz_visitor_id', id);
      }
      _visitorId = id;
    } catch (_) {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final r = Random();
      _visitorId = List.generate(22, (_) => chars[r.nextInt(chars.length)]).join();
    }
    return _visitorId!;
  }

  static void track(
    String event, {
    String path = '',
    String listingId = '',
    String category = '',
    String query = '',
  }) {
    // جلوگیری از شمارش دوباره‌ی یک رویداد در چند ثانیه
    final key = '$event|$path|$listingId|$query';
    final now = DateTime.now();
    if (key == _lastKey && now.difference(_lastAt).inSeconds < 3) return;
    _lastKey = key;
    _lastAt = now;
    if (event == 'search') {
      // کاربر هنگام تایپ مکث می‌کند؛ فقط عبارت نهایی (بعد از ۲٫۵ ثانیه سکوت) ثبت می‌شود.
      _searchTimer?.cancel();
      _searchTimer = Timer(const Duration(milliseconds: 2500), () => unawaited(_send(event, path, listingId, category, query)));
      return;
    }
    unawaited(_send(event, path, listingId, category, query));
  }

  static Future<void> _send(String event, String path, String listingId, String category, String query) async {
    try {
      final vid = await _getVisitorId();
      await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'event': event,
              'path': path,
              'listing_id': listingId,
              'category': category,
              'query': query,
              'referrer': event == 'page_view' ? env.referrerHost() : '',
              'device': env.deviceType(),
              'visitor_id': vid,
              'lang': 'fa',
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // آمار هرگز نباید روی تجربه‌ی کاربر اثر بگذارد.
    }
  }
}
