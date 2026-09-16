import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_panel_screen.dart';
import 'apk_webview_stub.dart' if (dart.library.io) 'apk_webview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BazarekEntryApp());
}

class BazarekEntryApp extends StatelessWidget {
  const BazarekEntryApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const BazarekWebViewApp();
    }
    return const BazarBuzurgApp();
  }
}

class BazarBuzurgApp extends StatefulWidget {
  const BazarBuzurgApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    final state = context.findAncestorStateOfType<_BazarBuzurgAppState>();
    state?.setLocale(newLocale);
  }

  static void toggleTheme(BuildContext context) {
    final state = context.findAncestorStateOfType<_BazarBuzurgAppState>();
    state?.toggleTheme();
  }

  @override
  State<BazarBuzurgApp> createState() => _BazarBuzurgAppState();
}

class _BazarBuzurgAppState extends State<BazarBuzurgApp> {
  Locale _locale = const Locale('fa');
  ThemeMode _themeMode = ThemeMode.light;
  bool _authReady = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'fa';
    final isDark = prefs.getBool('isDark') ?? false;
    AuthService.token = prefs.getString('auth_token');
    AuthService.userName = prefs.getString('user_name');
    AuthService.userContact = prefs.getString('user_contact');
    AuthService.avatarUrl = prefs.getString('avatar_url');
    AuthService.refreshToken = prefs.getString('refresh_token');
    AuthService.userId = prefs.getString('user_id');

    // Restore the real Supabase session after app/web restart.
    // Do not delete legacy-looking tokens here: the backend is the source of truth.
    if (AuthService.token != null && AuthService.token!.isNotEmpty &&
        AuthService.refreshToken != null && AuthService.refreshToken!.isNotEmpty) {
      try {
        await ApiService.refreshSession().timeout(const Duration(seconds: 8));
      } catch (_) {
        // Keep the stored session locally; normal API calls can retry later.
      }
    }

    if (!mounted) return;
    setState(() {
      _locale = Locale(lang);
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _authReady = true;
    });
    AuthService.authVersion.value++;
  }

  void setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
    setState(() => _locale = locale);
  }

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = _themeMode == ThemeMode.light;
    await prefs.setBool('isDark', isDark);
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بازار بزرگ',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('fa'),
        Locale('ps'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
          brightness: Brightness.light,
        ),
        fontFamily: 'Vazirmatn',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Vazirmatn',
      ),
      home: _authReady
          ? const MainLayout()
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

// Translations Helper
String tr(BuildContext context, String key) {
  final lang = Localizations.localeOf(context).languageCode;
  final map = lang == 'ps' ? _psMap : _faMap;
  return map[key] ?? key;
}

String localizedProvince(BuildContext context, String value) {
  if (Localizations.localeOf(context).languageCode != 'ps') return value;
  const ps = {
    'کابل':'کابل','هرات':'هرات','بلخ (مزارشریف)':'بلخ (مزار شریف)','قندهار':'کندهار','ننگرهار (جلال‌آباد)':'ننګرهار (جلال اباد)',
    'پکتیا':'پکتیا','خوست':'خوست','غزنی':'غزني','بامیان':'بامیان','پنجشیر':'پنجشېر','بدخشان':'بدخشان','پروان':'پروان','کاپیسا':'کاپیسا',
    'میدان وردک':'میدان وردګ','لوگر':'لوګر','دایکندی':'دایکندي','ارزگان':'اروزګان','زابل':'زابل','پکتیکا':'پکتیکا','هلمند':'هلمند',
    'فراه':'فراه','نیمروز':'نیمروز','بادغیس':'بادغیس','غور':'غور','سرپل':'سرپل','فاریاب':'فاریاب','جوزجان':'جوزجان',
    'سمنگان':'سمنګان','تخار':'تخار','کندز':'کندز','بغلان':'بغلان','نورستان':'نورستان','کنر':'کونړ','لغمان':'لغمان',
  };
  return ps[value] ?? value;
}

String localizedCategoryTitle(BuildContext context, String id, String fallback) {
  final lang = Localizations.localeOf(context).languageCode;
  if (lang == 'ps') {
    const ps = {
      'real_estate':'املاک او کور', 'vehicles':'وسایط نقلیه', 'electronics':'برېښنایي وسایل',
      'home_goods':'د کور وسایل', 'fashion':'کالي او جامې', 'jobs':'استخدام او د کارموندنه',
      'services':'خدمتونه', 'personal':'شخصي وسایل', 'social_pages':'مجازی پاڼې',
      'afghan_stores':'هټۍ او کاروبارونه', 'animals_pets':'کورني حیوانات',
      'agriculture_livestock':'کرنه او مالداري', 'food_grocery':'خوراکي توکي',
      'health':'روغتیا او هوساینه', 'education':'زده کړه او روزنه',
      'kids_family':'د ماشومانو وسایل', 'construction_tools':'ساختمان او وسایل',
      'wedding_events':'واده او مراسم', 'travel_tickets':'سفر او ټکټونه',
      'lost_found':'ورک او موندل شوي', 'sports_hobbies':'ورزش او ساعتېري',
    };
    return ps[id] ?? fallback;
  }
  return fallback;
}

String localizedSubcategoryTitle(BuildContext context, String categoryId, String id, String fallback) {
  if (Localizations.localeOf(context).languageCode != 'ps') return fallback;
  const ps = {
    'house_rent':'کرایي کور', 'house_mortgage':'ګروي کور', 'house_sale':'د خرڅلاو کور', 'apartment':'اپارتمان',
    'land_sale':'د خرڅلاو ځمکه', 'land_rent':'کرایي ځمکه', 'shop':'دوکان', 'office':'دفتر', 'garden':'باغ',
    'car':'موټر', 'motorcycle':'موټرسایکل', 'rickshaw':'ریکشا', 'parts':'پرزې', 'mobile':'موبایل', 'laptop':'لېپټاپ',
    'computer':'کمپیوټر', 'tv':'تلویزیون', 'camera':'کمره', 'furniture':'فرنیچر', 'appliances':'برقي وسایل',
    'kitchen':'د پخلنځي وسایل', 'mens':'د نارینه وو جامې', 'womens':'د ښځو جامې', 'kids':'د ماشومانو جامې', 'shoes':'بوټان',
    'full_time':'بشپړ وخت کار', 'part_time':'نیمه وخت کار', 'remote':'آنلاین کار', 'repair':'ترمیمات', 'transport':'ترانسپورت',
    'education':'زده کړه', 'other':'نور شخصي وسایل', 'youtube':'یوټیوب', 'tiktok':'ټیک ټاک', 'instagram':'انسټاګرام',
    'facebook_page':'فیسبوک پاڼه', 'telegram':'ټیلیګرام چینل', 'snapchat':'سنپ‌چټ', 'x_page':'د X پاڼه', 'other_social':'نورې پاڼې',
    'cats':'پیشوګانې', 'dogs':'سپي', 'birds':'مرغان', 'ornamental_fish':'زینتي کبان', 'pet_supplies':'د حیواناتو وسایل',
    'cattle':'غوا او غویي', 'sheep_goats':'پسونه او وزې', 'horses':'آسونه', 'poultry':'چرګان او مرغان', 'farm_equipment':'کرنیز وسایل',
    'grocery':'خوراکي توکي', 'fruit_vegetables':'مېوې او سبزي', 'water_drinks':'اوبه او څښاک', 'bakery':'نانوایي او شیریني',
    'pharmacy':'درمل او روغتیا', 'medical_equipment':'طبي وسایل', 'fitness_wellness':'روغتیا او فټنس',
    'courses':'کورسونه', 'books':'کتابونه', 'school_supplies':'د ښوونځي وسایل', 'tutoring':'خصوصي زده کړه',
    'baby_gear':'د ماشومانو وسایل', 'toys':'لوبې او اسباب‌بازي', 'strollers':'کالسکه او څوکۍ', 'kids_furniture':'د ماشومانو فرنیچر',
    'building_materials':'ساختماني مواد', 'tools':'وسایل او ابزار', 'generators':'جنراتورونه', 'solar':'لمریز سیستمونه',
    'wedding_dresses':'د واده کالي', 'wedding_services':'د واده خدمات', 'halls':'تالارونه', 'photography':'عکاسي او ویډیو',
    'air_tickets':'د الوتنې ټکټونه', 'bus_tickets':'د بس ټکټونه', 'hotels':'هوټل او استوګنه', 'tours':'سفرونه او سیاحت',
    'lost_items':'ورک شوي توکي', 'found_items':'موندل شوي توکي', 'documents':'موندل شوي اسناد',
    'sports_equipment':'ورزشي وسایل', 'gaming':'لوبې او کنسول', 'bicycles':'بایسکل', 'music':'د موسیقۍ وسایل',
  };
  return ps[id] ?? fallback;
}

String psText(BuildContext context, String fa, String ps) => Localizations.localeOf(context).languageCode == 'ps' ? ps : fa;

String friendlyNetworkError(BuildContext context, Object error) {
  final raw = error.toString().toLowerCase();
  final networkFailure = raw.contains('failed to fetch') ||
      raw.contains('clientexception') ||
      raw.contains('socketexception') ||
      raw.contains('connection refused') ||
      raw.contains('connection reset') ||
      raw.contains('network is unreachable') ||
      raw.contains('no internet') ||
      raw.contains('network error') ||
      raw.contains('timed out') ||
      raw.contains('timeout') ||
      raw.contains('failed host lookup') ||
      raw.contains('connection closed') ||
      raw.contains('connection terminated');
  if (networkFailure) {
    return Localizations.localeOf(context).languageCode == 'ps'
        ? 'مهرباني وکړئ د انټرنېټ له وصلېدو ډاډ ترلاسه کړئ او بیا هڅه وکړئ.'
        : 'لطفاً از وصل بودن اینترنت خود مطمئن شوید و دوباره تلاش کنید.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}

class OfflineErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  const OfflineErrorView({super.key, required this.onRetry, this.message});
  @override
  Widget build(BuildContext context) {
    final ps = Localizations.localeOf(context).languageCode == 'ps';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 14),
            Text(
              message ?? (ps
                  ? 'مهرباني وکړئ د انټرنېټ له وصلېدو ډاډ ترلاسه کړئ او بیا هڅه وکړئ.'
                  : 'لطفاً از وصل بودن اینترنت خود مطمئن شوید و دوباره تلاش کنید.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(tr(context, 'retry')),
            ),
          ],
        ),
      ),
    );
  }
}
String localizedBoostLabel(BuildContext context, String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  if (value.contains('توربو')) return boostBadgeText(context, 1);
  if (value.contains('انفجاری')) return boostBadgeText(context, 2);
  if (value.contains('قدرتی')) return boostBadgeText(context, 3);
  if (value.contains('فروشنده ویژه')) return boostBadgeText(context, 4);
  if (value.contains('فروشنده طلایی')) return boostBadgeText(context, 5);
  return value;
}

String boostBadgeText(BuildContext context, int level) {
  if (level >= 5) return psText(context, '🏆 فروشنده طلایی', '🏆 زرین پلورونکی');
  if (level == 4) return psText(context, '👑 فروشنده ویژه', '👑 ځانګړی پلورونکی');
  if (level == 3) return psText(context, '💥 قدرتی', '💥 پیاوړی');
  if (level == 2) return psText(context, '🔥 انفجاری', '🔥 چاودېدونکی');
  if (level == 1) return psText(context, '⚡ توربو', '⚡ توربو');
  return '';
}

class LocalizedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  const LocalizedText(this.text, {super.key, this.style, this.maxLines, this.overflow, this.textAlign});
  @override
  Widget build(BuildContext context) {
    if (Localizations.localeOf(context).languageCode != 'ps' || text.trim().isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow, textAlign: textAlign);
    }
    return FutureBuilder<String>(
      future: ApiService.translateText(text, 'ps'),
      builder: (_, snap) => Text(snap.data ?? text, style: style, maxLines: maxLines, overflow: overflow, textAlign: textAlign),
    );
  }
}

const Map<String, String> _faMap = {
  'app_title': 'بازار بزرگ افغانستان',
  'home': 'خانه',
  'chat': 'گفتگو',
  'add': 'ثبت آگهی',
  'my_ads': 'آگهی‌های من',
  'profile': 'حساب من',
  'search_hint': 'جستجو در بین هزاران آگهی...',
  'all_provinces': 'همه ولایت‌ها',
  'all_categories': 'همه دسته‌ها',
  'price': 'قیمت',
  'afghani': 'افغانی',
  'free': 'رایگان',
  'chat_seller': 'چت با فروشنده',
  'call_seller': 'تماس تلفنی',
  'login': 'ورود به حساب',
  'signup': 'ثبت‌نام حساب جدید',
  'logout': 'خروج از حساب',
  'dark_mode': 'حالت شب',
  'language': 'زبان / ژبه',
  'location': 'موقعیت',
  'details': 'جزئیات آگهی',
  'description': 'توضیحات',
  'seller_info': 'اطلاعات فروشنده',
  'price_negotiable': 'توافقی',
  'vip_badge': 'ویژه (VIP)',
  'full_name': 'نام کامل',
  'phone_or_email': 'شماره تلفن یا ایمیل معتبر',
  'password': 'رمز عبور (حداقل ۶ کاراکتر)',
  'no_account': 'حساب کاربری ندارید؟ ثبت نام کنید',
  'have_account': 'قبلاً ثبت‌نام کرده‌اید؟ وارد شوید',
  'categories': 'دسته‌بندی‌ها',
  'retry': 'تلاش دوباره',
  'boost': 'بوست آگهی‌ها',
  'boost_short': 'بوست کوتاه‌مدت — فقط یک آگهی',
  'boost_global': 'بوست ویژه — تمام آگهی‌های شما',
  'boost_week_desc': '۷ روز؛ همه آگهی‌های فعال شما با نشان توربو و اولویت بیشتر نمایش داده می‌شوند.',
  'boost_month_desc': '۳۰ روز؛ همه آگهی‌های فعال شما با نشان توربو و اولویت بیشتر نمایش داده می‌شوند.',
  'boost_year_desc': '۳۶۵ روز؛ همه آگهی‌های فعال شما با نشان توربو و بالاترین اولویت نمایش داده می‌شوند.',
  'social_pages': 'صفحات مجازی',
  'social_link': 'لینک صفحه',
  'social_link_hint': 'مثلاً https://instagram.com/yourpage',
  'open_link': 'باز کردن صفحه',
  'saved': 'علاقه‌مندی‌ها',
  'saved_empty': 'هنوز آگهی‌ای ذخیره نکرده‌اید.',
  'boost_home_title': 'آگهی‌ات را ویژه کن!',
  'boost_home_desc': 'با ویژه‌سازی، آگهی‌ات بیشتر دیده می‌شود و سریع‌تر مشتری پیدا می‌کنی.',
  'boost_home_button': 'ویژه‌سازی آگهی',
  'download_app': 'اپلیکیشن بازارک را دریافت کنید',
  'download_app_desc': 'سریع‌تر، راحت‌تر و همیشه همراه شما',
  'download': 'دانلود اپلیکیشن',
  'fresh_ads': 'جدیدترین آگهی‌ها',
  'special_ads': 'آگهی‌های ویژه',
  'view_all': 'مشاهده همه',
  'publish_success': 'آگهی با موفقیت منتشر شد.',
  'publish_error': 'خطا در انتشار آگهی.',
};

const Map<String, String> _psMap = {
  'app_title': 'د افغانستان لوی بازار',
  'home': 'کور',
  'chat': 'خبرې اترې',
  'add': 'اعلان درج کول',
  'my_ads': 'زما اعلانونه',
  'profile': 'زما حساب',
  'search_hint': 'په زرګونو اعلانونو کې لټون...',
  'all_provinces': ' ټول ولایتونه',
  'all_categories': 'ټولې ډلې',
  'price': 'قیمت',
  'afghani': 'افغانۍ',
  'free': 'وړیا',
  'chat_seller': 'له پلورونکي سره چت',
  'call_seller': 'تلیفون کول',
  'login': 'حساب ته ننوتل',
  'signup': 'نوې نوم لیکنه',
  'logout': 'وتل',
  'dark_mode': 'د شپې بڼه',
  'language': 'زبان / ژبه',
  'location': 'موقعیت',
  'details': 'د اعلان تفصیلات',
  'description': 'تشریحات',
  'seller_info': 'د پلورونکي معلومات',
  'price_negotiable': 'جور جاړ',
  'vip_badge': 'مخصوص (VIP)',
  'full_name': 'بشپړ نوم',
  'phone_or_email': 'د تلیفون شمیره یا بریښنالیک',
  'password': 'پټنوم',
  'no_account': 'حساب نه لرئ؟ نوم لیکنه وکړئ',
  'have_account': 'دمخه مو نوم لیکنه کړې؟ ننوځئ',
  'categories': 'ډلې',
  'retry': 'بیا هڅه',
  'boost': 'د اعلان Boost',
  'boost_short': 'لنډمهاله Boost — یوازې یو اعلان',
  'boost_global': 'ځانګړی Boost — ستاسو ټول اعلانونه',
  'boost_week_desc': '۷ ورځې؛ ستاسو ټول فعال اعلانونه د توربو نښان او لوړ لومړیتوب سره ښودل کېږي.',
  'boost_month_desc': '۳۰ ورځې؛ ستاسو ټول فعال اعلانونه د توربو نښان او لوړ لومړیتوب سره ښودل کېږي.',
  'boost_year_desc': '۳۶۵ ورځې؛ ستاسو ټول فعال اعلانونه د توربو نښان او تر ټولو لوړ لومړیتوب سره ښودل کېږي.',
  'social_pages': 'مجازی پاڼې',
  'social_link': 'د پاڼې لینک',
  'social_link_hint': 'لکه https://instagram.com/yourpage',
  'open_link': 'پاڼه پرانیزئ',
  'saved': 'علاقه‌مندي',
  'saved_empty': 'تر اوسه مو کوم اعلان نه دی خوندي کړی.',
  'boost_home_title': 'خپل اعلان ځانګړی کړئ!',
  'boost_home_desc': 'د ځانګړي کولو له لارې ستاسو اعلان ډېر لیدل کېږي او ژر پېرودونکي پیدا کوي.',
  'boost_home_button': 'اعلان ځانګړی کړئ',
  'download_app': 'د بازارک اپلېکېشن ترلاسه کړئ',
  'download_app_desc': 'چټک، اسانه او تل ستاسو ملګری',
  'download': 'اپلېکېشن ډاونلوډ کړئ',
  'fresh_ads': 'تازه اعلانونه',
  'special_ads': 'ځانګړي اعلانونه',
  'view_all': 'ټول وګورئ',
  'publish_success': 'اعلان په بریالیتوب خپور شو.',
  'publish_error': 'د اعلان په خپرولو کې ستونزه رامنځته شوه.',
};

const List<String> provinces = [
  'کابل', 'هرات', 'بلخ (مزارشریف)', 'قندهار', 'ننگرهار (جلال‌آباد)', 'پکتیا',
  'خوست', 'غزنی', 'بامیان', 'پنجشیر', 'بدخشان', 'پروان', 'کاپیسا', 'میدان وردک',
  'لوگر', 'دایکندی', 'ارزگان', 'زابل', 'پکتیکا', 'هلمند', 'فراه', 'نیمروز',
  'بادغیس', 'غور', 'سرپل', 'فاریاب', 'جوزجان', 'سمنگان', 'تخار', 'کندز',
  'بغلان', 'نورستان', 'کنر', 'لغمان',
];

const List<Map<String, dynamic>> categories = [
  {'id': 'real_estate', 'title': 'املاک و خانه', 'icon': Icons.home},
  {'id': 'vehicles', 'title': 'وسایط نقلیه', 'icon': Icons.directions_car},
  {'id': 'electronics', 'title': 'لوازم الکترونیکی', 'icon': Icons.smartphone},
  {'id': 'home_goods', 'title': 'لوازم خانه', 'icon': Icons.chair},
  {'id': 'fashion', 'title': 'لباس و پوشاک', 'icon': Icons.checkroom},
  {'id': 'jobs', 'title': 'استخدام و کاریابی', 'icon': Icons.work},
  {'id': 'services', 'title': 'خدمات', 'icon': Icons.build},
  {'id': 'personal', 'title': 'وسایل شخصی', 'icon': Icons.person},
  {'id': 'social_pages', 'title': 'صفحات مجازی', 'icon': Icons.public},
  {'id': 'afghan_stores', 'title': 'فروشگاه‌ها و کسب‌وکارها', 'icon': Icons.storefront},
  {'id': 'animals_pets', 'title': 'حیوانات خانگی', 'icon': Icons.pets},
  {'id': 'agriculture_livestock', 'title': 'زراعت و مالداری', 'icon': Icons.agriculture},
  {'id': 'food_grocery', 'title': 'مواد غذایی', 'icon': Icons.local_grocery_store},
  {'id': 'health', 'title': 'صحت و تندرستی', 'icon': Icons.health_and_safety},
  {'id': 'education', 'title': 'تعلیم و آموزش', 'icon': Icons.school},
  {'id': 'kids_family', 'title': 'وسایل اطفال و خانواده', 'icon': Icons.child_friendly},
  {'id': 'construction_tools', 'title': 'ساختمان و ابزار', 'icon': Icons.construction},
  {'id': 'wedding_events', 'title': 'عروسی و مراسم', 'icon': Icons.celebration},
  {'id': 'travel_tickets', 'title': 'سفر و تکت', 'icon': Icons.flight_takeoff},
  {'id': 'lost_found', 'title': 'گمشده و پیدا شده', 'icon': Icons.find_in_page},
  {'id': 'sports_hobbies', 'title': 'ورزش و سرگرمی', 'icon': Icons.sports_soccer},
];


const Map<String, List<Map<String, String>>> subcategories = {
  'real_estate': [
    {'id':'house_rent','title':'خانه کرایی'},
    {'id':'house_mortgage','title':'خانه گروی'},
    {'id':'house_sale','title':'خانه فروشی'},
    {'id':'apartment','title':'آپارتمان'},
    {'id':'land_sale','title':'زمین فروشی'},
    {'id':'land_rent','title':'زمین کرایی'},
    {'id':'shop','title':'دکان'},
    {'id':'office','title':'دفتر'},
    {'id':'garden','title':'باغ'},
  ],
  'vehicles': [
    {'id':'car','title':'موتر'}, {'id':'motorcycle','title':'موتورسایکل'}, {'id':'rickshaw','title':'رکشا'}, {'id':'parts','title':'پرزه‌جات'},
  ],
  'electronics': [
    {'id':'mobile','title':'موبایل'}, {'id':'laptop','title':'لپ‌تاپ'}, {'id':'computer','title':'کمپیوتر'}, {'id':'tv','title':'تلویزیون'}, {'id':'camera','title':'دوربین'},
  ],
  'home_goods': [
    {'id':'furniture','title':'مبلمان'}, {'id':'appliances','title':'لوازم برقی'}, {'id':'kitchen','title':'لوازم آشپزخانه'},
  ],
  'fashion': [
    {'id':'mens','title':'لباس مردانه'}, {'id':'womens','title':'لباس زنانه'}, {'id':'kids','title':'لباس کودک'}, {'id':'shoes','title':'کفش'},
  ],
  'jobs': [
    {'id':'full_time','title':'کار تمام‌وقت'}, {'id':'part_time','title':'کار نیمه‌وقت'}, {'id':'remote','title':'کار آنلاین'},
  ],
  'services': [
    {'id':'repair','title':'تعمیرات'}, {'id':'transport','title':'ترانسپورت'}, {'id':'education','title':'آموزش'},
  ],
  'personal': [
    {'id':'other','title':'سایر وسایل شخصی'},
  ],
  'social_pages': [
    {'id':'youtube','title':'یوتیوب'}, {'id':'tiktok','title':'تیک‌تاک'}, {'id':'instagram','title':'اینستاگرام'},
    {'id':'facebook_page','title':'صفحه فیسبوک'}, {'id':'telegram','title':'کانال تلگرام'}, {'id':'snapchat','title':'اسنپ‌چت'},
    {'id':'x_page','title':'صفحه X'}, {'id':'other_social','title':'سایر صفحات'},
  ],
  'afghan_stores': [
    {'id':'clothing_stores','title':'فروشگاه‌های لباس'}, {'id':'shoe_stores','title':'فروشگاه‌های کفش'},
    {'id':'gold_stores','title':'طلافروشی و جواهرات'}, {'id':'mobile_stores','title':'فروشگاه‌های موبایل و لوازم جانبی'},
    {'id':'electronics_stores','title':'فروشگاه‌های لوازم برقی'}, {'id':'home_stores','title':'فروشگاه‌های لوازم خانه'},
    {'id':'furniture_stores','title':'فروشگاه‌های مبلمان'}, {'id':'cosmetics_stores','title':'فروشگاه‌های آرایشی و بهداشتی'},
    {'id':'supermarkets','title':'سوپرمارکت و مواد غذایی'}, {'id':'car_parts_stores','title':'فروشگاه‌های پرزه‌جات موتر'},
    {'id':'children_stores','title':'فروشگاه‌های کودک'}, {'id':'other_stores','title':'سایر فروشگاه‌ها'},
  ],
  'animals_pets': [
    {'id':'cats','title':'پیشک / گربه'}, {'id':'dogs','title':'سگ'}, {'id':'birds','title':'پرنده‌های خانگی'},
    {'id':'ornamental_fish','title':'ماهی زینتی'}, {'id':'pet_supplies','title':'غذا و لوازم حیوانات'},
  ],
  'agriculture_livestock': [
    {'id':'cattle','title':'گاو و گوساله'}, {'id':'sheep_goats','title':'گوسفند و بز'}, {'id':'horses','title':'اسب'},
    {'id':'poultry','title':'مرغ و پرنده'}, {'id':'farm_equipment','title':'ماشین‌آلات و ابزار زراعت'},
  ],
  'food_grocery': [
    {'id':'grocery','title':'مواد غذایی'}, {'id':'fruit_vegetables','title':'میوه و سبزی'}, {'id':'water_drinks','title':'آب و نوشیدنی'},
    {'id':'bakery','title':'نان و شیرینی'},
  ],
  'health': [
    {'id':'pharmacy','title':'محصولات صحی'}, {'id':'medical_equipment','title':'تجهیزات طبی'}, {'id':'fitness_wellness','title':'ورزش و تندرستی'},
  ],
  'education': [
    {'id':'courses','title':'کورس و آموزش'}, {'id':'books','title':'کتاب و جزوه'}, {'id':'school_supplies','title':'لوازم مکتب'}, {'id':'tutoring','title':'استاد خصوصی'},
  ],
  'kids_family': [
    {'id':'baby_gear','title':'لوازم نوزاد'}, {'id':'toys','title':'اسباب‌بازی'}, {'id':'strollers','title':'کالسکه و چوکی طفل'}, {'id':'kids_furniture','title':'اثاثیه اطفال'},
  ],
  'construction_tools': [
    {'id':'building_materials','title':'مصالح ساختمانی'}, {'id':'tools','title':'ابزار و ماشین‌آلات'}, {'id':'generators','title':'جنراتور'}, {'id':'solar','title':'سیستم‌های سولری'},
  ],
  'wedding_events': [
    {'id':'wedding_dresses','title':'لباس عروسی'}, {'id':'wedding_services','title':'خدمات عروسی'}, {'id':'halls','title':'تالار و محل مراسم'}, {'id':'photography','title':'عکاسی و فیلمبرداری'},
  ],
  'travel_tickets': [
    {'id':'air_tickets','title':'تکت هواپیما'}, {'id':'bus_tickets','title':'تکت بس'}, {'id':'hotels','title':'هوتل و اقامت'}, {'id':'tours','title':'تور و گردشگری'},
  ],
  'lost_found': [
    {'id':'lost_items','title':'اشیای گمشده'}, {'id':'found_items','title':'اشیای پیدا شده'}, {'id':'documents','title':'اسناد پیدا شده'},
  ],
  'sports_hobbies': [
    {'id':'sports_equipment','title':'تجهیزات ورزشی'}, {'id':'gaming','title':'گیم و کنسول'}, {'id':'bicycles','title':'بایسکل'}, {'id':'music','title':'آلات موسیقی'},
  ],
};

class ApiConfig {
  static const String baseUrl = 'https://bazarek.onrender.com/api';
}

class AuthService {
  static final ValueNotifier<int> authVersion = ValueNotifier<int>(0);
  static String? token;
  static String? userName;
  static String? userContact;
  static String? avatarUrl;
  static String? refreshToken;
  static String? userId;

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  static Future<void> saveUser(String tokenVal, String nameVal, String contactVal, {String? refreshTokenVal, String? userIdVal}) async {
    token = tokenVal;
    userName = nameVal;
    userContact = contactVal;
    refreshToken = refreshTokenVal;
    if (userIdVal != null && userIdVal.isNotEmpty) userId = userIdVal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', tokenVal);
    await prefs.setString('user_name', nameVal);
    await prefs.setString('user_contact', contactVal);
    if (avatarUrl != null && avatarUrl!.isNotEmpty) await prefs.setString('avatar_url', avatarUrl!);
    if (refreshTokenVal != null && refreshTokenVal.isNotEmpty) {
      await prefs.setString('refresh_token', refreshTokenVal);
    }
    if (userId != null && userId!.isNotEmpty) await prefs.setString('user_id', userId!);
    authVersion.value++;
  }

  static Future<void> logout() async {
    token = null;
    userName = null;
    userContact = null;
    avatarUrl = null;
    refreshToken = null;
    userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_contact');
    await prefs.remove('avatar_url');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    authVersion.value++;
  }
}

Future<bool> requireAccount(BuildContext context) async {
  if (AuthService.isLoggedIn) return true;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('برای ثبت آگهی و ارسال پیام، ابتدا حساب خود را بسازید یا وارد حساب شوید.'),
      duration: Duration(seconds: 3),
    ),
  );
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AuthScreen()),
  );
  return AuthService.isLoggedIn;
}

class _DetectedImageType {
  final String mime;
  final String ext;
  const _DetectedImageType(this.mime, this.ext);
}

_DetectedImageType? _detectImageType(Uint8List b, String? reportedMime, String reportedName) {
  final m = (reportedMime ?? '').toLowerCase().trim();
  if (m == 'image/jpeg') return const _DetectedImageType('image/jpeg', 'jpg');
  if (m == 'image/png') return const _DetectedImageType('image/png', 'png');
  if (m == 'image/webp') return const _DetectedImageType('image/webp', 'webp');
  if (m == 'image/gif') return const _DetectedImageType('image/gif', 'gif');
  final n = reportedName.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return const _DetectedImageType('image/jpeg', 'jpg');
  if (n.endsWith('.png')) return const _DetectedImageType('image/png', 'png');
  if (n.endsWith('.webp')) return const _DetectedImageType('image/webp', 'webp');
  if (n.endsWith('.gif')) return const _DetectedImageType('image/gif', 'gif');
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return const _DetectedImageType('image/jpeg', 'jpg');
  if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47 && b[4] == 0x0D && b[5] == 0x0A && b[6] == 0x1A && b[7] == 0x0A) return const _DetectedImageType('image/png', 'png');
  if (b.length >= 12 && String.fromCharCodes(b.sublist(0,4)) == 'RIFF' && String.fromCharCodes(b.sublist(8,12)) == 'WEBP') return const _DetectedImageType('image/webp', 'webp');
  if (b.length >= 6) { final sig = String.fromCharCodes(b.sublist(0,6)); if (sig == 'GIF87a' || sig == 'GIF89a') return const _DetectedImageType('image/gif', 'gif'); }
  return null;
}


class ApiService {
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (AuthService.token != null) 'Authorization': 'Bearer ${AuthService.token}',
      };

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase(), 'password': password}),
      ).timeout(const Duration(seconds: 30));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return data;
      return {'error': data['error'] ?? 'ایمیل یا رمز عبور اشتباه است.'};
    } catch (e) {
      return {'error': 'اتصال به سرور برقرار نشد. اینترنت و آدرس Backend را بررسی کنید.'};
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase(), 'password': password, 'full_name': name.trim()}),
      ).timeout(const Duration(seconds: 30));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) return data;
      return {'error': data['error'] ?? 'خطا در ثبت‌نام.'};
    } catch (e) {
      return {'error': 'اتصال به سرور برقرار نشد. اینترنت و آدرس Backend را بررسی کنید.'};
    }
  }

  static Future<bool> refreshSession() async {
    final rt = AuthService.refreshToken;
    if (rt == null || rt.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'refresh_token': rt}),
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body);
      if (data['token'] == null) return false;
      final user = data['user'] is Map ? data['user'] as Map : <String, dynamic>{};
      final metadata = user['user_metadata'] is Map ? user['user_metadata'] as Map : <String, dynamic>{};
      await AuthService.saveUser(
        data['token'].toString(),
        metadata['full_name']?.toString() ?? AuthService.userName ?? 'کاربر بازارک',
        user['email']?.toString() ?? AuthService.userContact ?? '',
        refreshTokenVal: data['refresh_token']?.toString() ?? rt,
        userIdVal: user['id']?.toString(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static final Map<String, String> _translationCache = {};

  static Future<String> translateText(String text, String targetLanguage) async {
    final value = text.trim();
    if (value.isEmpty || targetLanguage != 'ps') return text;
    final key = '$targetLanguage|$value';
    if (_translationCache.containsKey(key)) return _translationCache[key]!;
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/translate').replace(queryParameters: {
        'text': value, 'target': targetLanguage,
      }), headers: {'Accept':'application/json'}).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final translated = data['text']?.toString();
        if (translated != null && translated.trim().isNotEmpty) {
          _translationCache[key] = translated.trim();
          return translated.trim();
        }
      }
    } catch (_) {}
    return text;
  }

  static Future<Map<String, dynamic>> startConversation(String listingId) async {
    Future<http.Response> request() => http.post(
      Uri.parse('${ApiConfig.baseUrl}/conversations'),
      headers: headers,
      body: jsonEncode({'listing_id': listingId}),
    ).timeout(const Duration(seconds: 20));

    var res = await request();
    if (res.statusCode == 401 && await refreshSession()) {
      res = await request();
    }
    dynamic decoded;
    try { decoded = jsonDecode(res.body); } catch (_) { decoded = null; }
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(decoded is Map ? (decoded['error'] ?? 'خطا در شروع گفتگو.') : 'خطا در شروع گفتگو.');
    }
    if (decoded is! Map) throw Exception('پاسخ گفتگو از سرور نامعتبر است.');
    return Map<String, dynamic>.from(decoded);
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    Future<http.Response> request() => http.get(
      Uri.parse('${ApiConfig.baseUrl}/conversations'),
      headers: headers,
    ).timeout(const Duration(seconds: 20));

    var res = await request();
    if (res.statusCode == 401 && await refreshSession()) {
      res = await request();
    }
    dynamic decoded;
    try { decoded = jsonDecode(res.body); } catch (_) { decoded = null; }
    if (res.statusCode != 200) {
      throw Exception(decoded is Map ? (decoded['error'] ?? 'خطا در دریافت گفتگوها.') : 'خطا در دریافت گفتگوها.');
    }
    if (decoded is! List) throw Exception('پاسخ گفتگوها از سرور نامعتبر است.');
    return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    Future<http.Response> request() => http.get(
      Uri.parse('${ApiConfig.baseUrl}/conversations/$conversationId/messages'),
      headers: headers,
    ).timeout(const Duration(seconds: 20));

    var res = await request();
    if (res.statusCode == 401 && await refreshSession()) {
      res = await request();
    }
    dynamic decoded;
    try { decoded = jsonDecode(res.body); } catch (_) { decoded = null; }
    if (res.statusCode != 200) {
      throw Exception(decoded is Map ? (decoded['error'] ?? 'خطا در دریافت پیام‌ها.') : 'خطا در دریافت پیام‌ها.');
    }
    if (decoded is! List) throw Exception('پاسخ پیام‌ها از سرور نامعتبر است.');
    return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<Map<String, dynamic>> sendMessage(String conversationId, String message) async {
    final text = message.trim();
    if (text.isEmpty) throw Exception('متن پیام خالی است.');

    Future<http.Response> request() => http.post(
      Uri.parse('${ApiConfig.baseUrl}/conversations/$conversationId/messages'),
      headers: headers,
      body: jsonEncode({'message': text}),
    ).timeout(const Duration(seconds: 20));

    var res = await request();
    if (res.statusCode == 401 && await refreshSession()) {
      res = await request();
    }
    dynamic decoded;
    try { decoded = jsonDecode(res.body); } catch (_) { decoded = null; }
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(decoded is Map ? (decoded['error'] ?? 'خطا در ارسال پیام.') : 'خطا در ارسال پیام.');
    }
    if (decoded is! Map) throw Exception('پاسخ ارسال پیام از سرور نامعتبر است.');
    return Map<String, dynamic>.from(decoded);
  }

  static Future<Map<String, dynamic>> getSellerProfile(String sellerId) async {
    Future<http.Response> request() => http.get(Uri.parse('${ApiConfig.baseUrl}/sellers/$sellerId'), headers: headers).timeout(const Duration(seconds: 15));
    var res = await request();
    if (res.statusCode == 401 && await refreshSession()) res = await request();
    dynamic data; try { data = jsonDecode(res.body); } catch (_) { data = null; }
    if (res.statusCode != 200) throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت پروفایل فروشنده.') : 'خطا در دریافت پروفایل فروشنده.');
    return Map<String,dynamic>.from(data as Map);
  }

  static Future<List<dynamic>> getSellerListings(String sellerId) async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/sellers/$sellerId/listings'), headers: headers).timeout(const Duration(seconds: 15));
    dynamic data; try { data = jsonDecode(res.body); } catch (_) { data = null; }
    if (res.statusCode != 200) throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت آگهی‌های فروشنده.') : 'خطا در دریافت آگهی‌های فروشنده.');
    return data is List ? data : List<dynamic>.from((data as Map)['data'] ?? const []);
  }

  static Future<Map<String,dynamic>> toggleSellerFollow(String sellerId, bool follow) async {
    Future<http.Response> request() => follow
      ? http.post(Uri.parse('${ApiConfig.baseUrl}/sellers/$sellerId/follow'), headers: headers)
      : http.delete(Uri.parse('${ApiConfig.baseUrl}/sellers/$sellerId/follow'), headers: headers);
    var res = await request();
    if (res.statusCode == 401 && await refreshSession()) res = await request();
    dynamic data; try { data=jsonDecode(res.body); } catch (_) { data=null; }
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(data is Map ? (data['error'] ?? 'تغییر دنبال‌کردن فروشنده ناموفق بود.') : 'تغییر دنبال‌کردن فروشنده ناموفق بود.');
    return data is Map ? Map<String,dynamic>.from(data) : <String,dynamic>{};
  }

  static Future<Map<String,dynamic>> toggleListingLike(String listingId, bool like) async {
    Future<http.Response> request() => like
      ? http.post(Uri.parse('${ApiConfig.baseUrl}/listings/$listingId/like'), headers: headers)
      : http.delete(Uri.parse('${ApiConfig.baseUrl}/listings/$listingId/like'), headers: headers);
    var res = await request();
    if (res.statusCode == 401 && await refreshSession()) res = await request();
    dynamic data; try { data=jsonDecode(res.body); } catch (_) { data=null; }
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(data is Map ? (data['error'] ?? 'تغییر پسندیدن ناموفق بود.') : 'تغییر پسندیدن ناموفق بود.');
    return data is Map ? Map<String,dynamic>.from(data) : <String,dynamic>{};
  }

  static Future<List<dynamic>> getSellerComments(String sellerId) async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/sellers/$sellerId/comments'), headers: headers).timeout(const Duration(seconds: 15));
    dynamic data; try { data=jsonDecode(res.body); } catch (_) { data=null; }
    if (res.statusCode != 200) throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت دیدگاه‌ها.') : 'خطا در دریافت دیدگاه‌ها.');
    return data is List ? data : List<dynamic>.from((data as Map)['data'] ?? const []);
  }

  static Future<Map<String,dynamic>> addSellerComment(String sellerId, String text) async {
    Future<http.Response> request() => http.post(Uri.parse('${ApiConfig.baseUrl}/sellers/$sellerId/comments'), headers: headers, body: jsonEncode({'comment': text.trim()}));
    var res = await request();
    if (res.statusCode == 401 && await refreshSession()) res = await request();
    dynamic data; try { data=jsonDecode(res.body); } catch (_) { data=null; }
    if (res.statusCode != 201) throw Exception(data is Map ? (data['error'] ?? 'ثبت دیدگاه ناموفق بود.') : 'ثبت دیدگاه ناموفق بود.');
    return Map<String,dynamic>.from(data as Map);
  }

  static Future<Map<String,dynamic>> rateSeller(String sellerId, int rating) async {
    Future<http.Response> request() => http.post(Uri.parse('${ApiConfig.baseUrl}/sellers/$sellerId/rating'), headers: headers, body: jsonEncode({'rating': rating}));
    var res = await request();
    if (res.statusCode == 401 && await refreshSession()) res = await request();
    dynamic data; try { data=jsonDecode(res.body); } catch (_) { data=null; }
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(data is Map ? (data['error'] ?? 'ثبت امتیاز ناموفق بود.') : 'ثبت امتیاز ناموفق بود.');
    return Map<String,dynamic>.from(data as Map);
  }

  static Future<List<dynamic>> getProducts({
    String? category,
    String? subcategory,
    String? province,
    String? query,
    int page = 1,
  }) async {
    final queryParams = {
      if (category != null && category.isNotEmpty) 'category': category,
      if (subcategory != null && subcategory.isNotEmpty) 'subcategory': subcategory,
      if (province != null && province.isNotEmpty) 'province': province,
      if (query != null && query.isNotEmpty) 'q': query,
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}/listings').replace(queryParameters: queryParams);
    try {
      final res = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        if (data is List) return data;
        if (data is Map && data['data'] is List) return List<dynamic>.from(data['data']);
        throw Exception('پاسخ آگهی‌ها از سرور نامعتبر است.');
      }
      throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت آگهی‌ها.') : 'خطا در دریافت آگهی‌ها.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('اتصال به سرور برقرار نشد.');
    }
  }

  static Future<Map<String, dynamic>> submitReport({required String listingId, required String reason}) async {
    var res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/reports'),
      headers: headers,
      body: jsonEncode({'listing_id': listingId, 'reason': reason}),
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reports'),
        headers: headers,
        body: jsonEncode({'listing_id': listingId, 'reason': reason}),
      ).timeout(const Duration(seconds: 20));
    }
    final data = jsonDecode(res.body);
    if (res.statusCode != 201) {
      throw Exception(data is Map ? (data['error'] ?? 'خطا در ثبت گزارش آگهی.') : 'خطا در ثبت گزارش آگهی.');
    }
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<dynamic>> getMyProducts() async {
    var res = await http.get(Uri.parse('${ApiConfig.baseUrl}/products'), headers: headers).timeout(const Duration(seconds: 15));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.get(Uri.parse('${ApiConfig.baseUrl}/products'), headers: headers).timeout(const Duration(seconds: 15));
    }
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت آگهی‌های شما.') : 'خطا در دریافت آگهی‌های شما.');
    return data is List ? data : List<dynamic>.from(data['data'] ?? const []);
  }

  static Future<Map<String, dynamic>> setMyProductStatus({required String id, required bool isActive}) async {
    var res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/products/$id/status'),
      headers: headers,
      body: jsonEncode({'is_active': isActive}),
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/products/$id/status'),
        headers: headers,
        body: jsonEncode({'is_active': isActive}),
      ).timeout(const Duration(seconds: 20));
    }
    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data is! Map) {
      throw Exception(data is Map ? (data['error'] ?? 'خطا در تغییر وضعیت آگهی.') : 'خطا در تغییر وضعیت آگهی.');
    }
    return Map<String, dynamic>.from(data);
  }


  static Future<void> deleteMyAccount() async {
    var res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/me/account'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/me/account'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
    }
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) data = Map<String, dynamic>.from(decoded);
    } catch (_) {}
    if (res.statusCode != 200) {
      throw Exception(data?['error'] ?? 'حذف حساب انجام نشد.');
    }
  }

  static Future<void> deleteMyProduct({required String id}) async {
    var res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/products/$id'),
      headers: headers,
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/products/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 20));
    }
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) data = Map<String, dynamic>.from(decoded);
    } catch (_) {}
    if (res.statusCode != 200) {
      throw Exception(data?['error'] ?? 'حذف آگهی ناموفق بود.');
    }
  }

  static Future<Map<String, dynamic>> getMyProfile() async {
    var res = await http.get(Uri.parse('${ApiConfig.baseUrl}/me'), headers: headers).timeout(const Duration(seconds: 15));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.get(Uri.parse('${ApiConfig.baseUrl}/me'), headers: headers).timeout(const Duration(seconds: 15));
    }
    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data is! Map) {
      throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت پروفایل.') : 'خطا در دریافت پروفایل.');
    }
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> updateMyProfile({
    required String fullName,
    required String phone,
    required String city,
    required String shopName,
    required String bio,
  }) async {
    var res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/me'),
      headers: headers,
      body: jsonEncode({
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'city': city.trim(),
        'shop_name': shopName.trim(),
        'bio': bio.trim(),
      }),
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/me'),
        headers: headers,
        body: jsonEncode({
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'city': city.trim(),
          'shop_name': shopName.trim(),
          'bio': bio.trim(),
        }),
      ).timeout(const Duration(seconds: 20));
    }
    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data is! Map) {
      throw Exception(data is Map ? (data['error'] ?? 'خطا در ذخیره پروفایل.') : 'خطا در ذخیره پروفایل.');
    }
    final profile = Map<String, dynamic>.from(data);
    AuthService.userName = profile['full_name']?.toString() ?? fullName;
    if (profile['phone']?.toString().trim().isNotEmpty == true) {
      AuthService.userContact = profile['phone'].toString();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', AuthService.userName ?? fullName);
    await prefs.setString('user_contact', AuthService.userContact ?? phone);
    AuthService.authVersion.value++;
    return profile;
  }

  static Future<Map<String, dynamic>> getPaymentInfo() async {
    var res = await http.get(Uri.parse('${ApiConfig.baseUrl}/payment-info'), headers: headers).timeout(const Duration(seconds: 15));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.get(Uri.parse('${ApiConfig.baseUrl}/payment-info'), headers: headers).timeout(const Duration(seconds: 15));
    }
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت اطلاعات پرداخت.') : 'خطا در دریافت اطلاعات پرداخت.');
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<String> uploadAvatar(PickedProfileImage image) async {
    Future<http.Response> send() async {
      final req = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/profile/avatar'));
      if (AuthService.token != null) req.headers['Authorization'] = 'Bearer ${AuthService.token}';
      final bytes = image.bytes;
      final detected = _detectImageType(bytes, image.mimeType, image.name);
      if (detected == null) {
        throw Exception('فایل انتخاب‌شده یک تصویر معتبر نیست. لطفاً JPG، PNG یا WEBP انتخاب کنید.');
      }
      final mime = detected.mime;
      final filename = 'avatar-${DateTime.now().millisecondsSinceEpoch}.${detected.ext}';
      req.headers['X-Image-Mime-Type'] = mime;
      req.headers['X-Image-Extension'] = detected.ext;
      req.files.add(http.MultipartFile.fromBytes(
        'avatar', bytes, filename: filename, contentType: MediaType.parse(mime),
      ));
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      return http.Response.fromStream(streamed);
    }
    var res = await send();
    if (res.statusCode == 401 && await refreshSession()) res = await send();
    final data = jsonDecode(res.body);
    if (res.statusCode != 201) throw Exception(data is Map ? (data['error'] ?? 'آپلود تصویر پروفایل ناموفق بود.') : 'آپلود تصویر پروفایل ناموفق بود.');
    final url = data['url']?.toString() ?? '';
    if (url.isEmpty) throw Exception('آدرس تصویر پروفایل از سرور دریافت نشد.');
    AuthService.avatarUrl = url;
    AuthService.authVersion.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_url', url);
    return url;
  }

  static Future<List<dynamic>> getBoostPackages() async {
    var res = await http.get(Uri.parse('${ApiConfig.baseUrl}/monetization/packages'), headers: headers).timeout(const Duration(seconds: 15));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.get(Uri.parse('${ApiConfig.baseUrl}/monetization/packages'), headers: headers).timeout(const Duration(seconds: 15));
    }
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت بسته‌های بوست.') : 'خطا در دریافت بسته‌های بوست.');
    final list = data is List ? data : List<dynamic>.from(data['data'] ?? const []);
    // Legacy per-listing Boost packages remain in the API for backward compatibility,
    // but the current monetization flow uses seller-wide weekly/monthly/yearly plans.
    return const <dynamic>[];
  }

  static Future<Map<String,dynamic>> createBoostOrder(String listingId, String packageId, String reference) async {
    var res = await http.post(Uri.parse('${ApiConfig.baseUrl}/promotions/orders'), headers: headers, body: jsonEncode({
      'listing_id': listingId, 'package_id': packageId, 'payment_method': 'manual', 'payment_reference': reference.trim(),
    })).timeout(const Duration(seconds: 20));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.post(Uri.parse('${ApiConfig.baseUrl}/promotions/orders'), headers: headers, body: jsonEncode({
        'listing_id': listingId, 'package_id': packageId, 'payment_method': 'manual', 'payment_reference': reference.trim(),
      })).timeout(const Duration(seconds: 20));
    }
    final data = jsonDecode(res.body);
    if (res.statusCode != 201) throw Exception(data is Map ? (data['error'] ?? 'ثبت سفارش بوست ناموفق بود.') : 'ثبت سفارش بوست ناموفق بود.');
    return Map<String,dynamic>.from(data);
  }

  static Future<Map<String,dynamic>> createGlobalBoost(String plan, String reference) async {
    var res = await http.post(Uri.parse('${ApiConfig.baseUrl}/subscriptions'), headers: headers, body: jsonEncode({
      'plan': plan, 'payment_reference': reference.trim(),
    })).timeout(const Duration(seconds: 20));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.post(Uri.parse('${ApiConfig.baseUrl}/subscriptions'), headers: headers, body: jsonEncode({
        'plan': plan, 'payment_reference': reference.trim(),
      })).timeout(const Duration(seconds: 20));
    }
    final data = jsonDecode(res.body);
    if (res.statusCode != 201) throw Exception(data is Map ? (data['error'] ?? 'ثبت درخواست اشتراک ناموفق بود.') : 'ثبت درخواست اشتراک ناموفق بود.');
    return Map<String,dynamic>.from(data);
  }


  static Future<List<dynamic>> getSupportRequests() async {
    var res = await http.get(Uri.parse('${ApiConfig.baseUrl}/support/requests'), headers: headers).timeout(const Duration(seconds: 15));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.get(Uri.parse('${ApiConfig.baseUrl}/support/requests'), headers: headers).timeout(const Duration(seconds: 15));
    }
    dynamic data;
    try { data = jsonDecode(res.body); } catch (_) {
      throw Exception('سرور پشتیبانی پاسخ JSON معتبر برنگرداند. لطفاً Backend بازارک را Deploy کنید.');
    }
    if (res.statusCode != 200) throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت درخواست‌های پشتیبانی.') : 'خطا در دریافت درخواست‌های پشتیبانی.');
    return data is List ? data : List<dynamic>.from(data['data'] ?? const []);
  }

  static Future<Map<String, dynamic>> createSupportRequest({
    required String type,
    required String subject,
    required String message,
  }) async {
    var res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/support'),
      headers: headers,
      body: jsonEncode({'type': type, 'title': subject, 'message': message}),
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/support'),
        headers: headers,
        body: jsonEncode({'type': type, 'title': subject, 'message': message}),
      ).timeout(const Duration(seconds: 20));
    }
    dynamic data;
    try { data = jsonDecode(res.body); } catch (_) {
      throw Exception('سرور پشتیبانی پاسخ JSON معتبر برنگرداند. لطفاً Backend بازارک را Deploy کنید.');
    }
    if (res.statusCode != 201) throw Exception(data is Map ? (data['error'] ?? 'ارسال درخواست ناموفق بود.') : 'ارسال درخواست ناموفق بود.');
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<dynamic>> getNotifications() async {
    var res = await http.get(Uri.parse('${ApiConfig.baseUrl}/me/notifications'), headers: headers).timeout(const Duration(seconds: 15));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.get(Uri.parse('${ApiConfig.baseUrl}/me/notifications'), headers: headers).timeout(const Duration(seconds: 15));
    }
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت اعلان‌ها.') : 'خطا در دریافت اعلان‌ها.');
    return data is List ? data : List<dynamic>.from(data['data'] ?? const []);
  }

  static Future<void> markNotificationRead(String id) async {
    var res = await http.patch(Uri.parse('${ApiConfig.baseUrl}/me/notifications/$id/read'), headers: headers);
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.patch(Uri.parse('${ApiConfig.baseUrl}/me/notifications/$id/read'), headers: headers);
    }
    if (res.statusCode != 200) throw Exception('خواندن اعلان ناموفق بود.');
  }

  static Future<void> deleteNotification(String id) async {
    var res = await http.delete(Uri.parse('${ApiConfig.baseUrl}/me/notifications/$id'), headers: headers);
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.delete(Uri.parse('${ApiConfig.baseUrl}/me/notifications/$id'), headers: headers);
    }
    if (res.statusCode != 200) throw Exception('حذف اعلان ناموفق بود.');
  }

  static Future<List<dynamic>> getSubscriptions() async {
    var res = await http.get(Uri.parse('${ApiConfig.baseUrl}/subscriptions'), headers: headers).timeout(const Duration(seconds: 15));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.get(Uri.parse('${ApiConfig.baseUrl}/subscriptions'), headers: headers).timeout(const Duration(seconds: 15));
    }
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت اشتراک‌ها.') : 'خطا در دریافت اشتراک‌ها.');
    return data is List ? data : List<dynamic>.from(data['data'] ?? const []);
  }
}



class SavedAdsScreen extends StatefulWidget {
  const SavedAdsScreen({super.key});

  @override
  State<SavedAdsScreen> createState() => _SavedAdsScreenState();
}

class _SavedAdsScreenState extends State<SavedAdsScreen> {
  List<dynamic> _saved = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('saved_ad_ids') ?? <String>[];
      if (ids.isEmpty) {
        if (mounted) setState(() { _saved = []; _loading = false; });
        return;
      }

      final all = await ApiService.getProducts();
      final wanted = ids.toSet();
      final result = all.where((item) => wanted.contains(item['id']?.toString())).toList();

      // Keep the user's saved order where possible and remove listings that no longer exist.
      final byId = <String, dynamic>{
        for (final item in result) item['id'].toString(): item,
      };
      final ordered = <dynamic>[];
      for (final id in ids) {
        final item = byId[id];
        if (item != null) ordered.add(item);
      }
      final existingIds = ordered.map((e) => e['id'].toString()).toSet();
      await prefs.setStringList('saved_ad_ids', ids.where(existingIds.contains).toList());

      if (mounted) setState(() { _saved = ordered; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = friendlyNetworkError(context, e);
        _loading = false;
      });
    }
  }

  Future<void> _remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('saved_ad_ids') ?? <String>[];
    ids.remove(id);
    await prefs.setStringList('saved_ad_ids', ids);
    if (mounted) {
      setState(() {
        _saved.removeWhere((item) => item['id']?.toString() == id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPs = Localizations.localeOf(context).languageCode == 'ps';
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'saved')),
        actions: [
          IconButton(onPressed: _loadSaved, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 52),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _loadSaved,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(tr(context, 'retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : _saved.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite_border_rounded,
                                size: 64, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 14),
                            Text(
                              tr(context, 'saved_empty'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSaved,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                        itemCount: _saved.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _saved[index];
                          final id = item['id']?.toString() ?? '';
                          return Stack(
                            children: [
                              _DivarStyleListing(item: item),
                              Positioned(
                                left: 0,
                                top: 8,
                                child: IconButton(
                                  tooltip: isPs ? 'لرې کول' : 'حذف از علاقه‌مندی‌ها',
                                  onPressed: id.isEmpty ? null : () => _remove(id),
                                  icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    SavedAdsScreen(),
    AddProductScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: AuthService.authVersion,
        builder: (_, __, ___) => IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) async {
          if ((idx == 2 || idx == 3) && !AuthService.isLoggedIn) {
            await requireAccount(context);
            return;
          }
          setState(() {
            _currentIndex = idx;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: tr(context, 'home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border_rounded),
            selectedIcon: const Icon(Icons.favorite_rounded),
            label: tr(context, 'saved'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: tr(context, 'add'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: tr(context, 'chat'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: tr(context, 'profile'),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedProvince = '';
  String selectedCategory = '';
  String searchQuery = '';
  String sortMode = 'newest';
  List<dynamic> products = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (mounted) setState(() { isLoading = true; loadError = null; });
    try {
      final data = await ApiService.getProducts(
        category: selectedCategory,
        province: selectedProvince,
        query: searchQuery,
      );
      final sorted = List<dynamic>.from(data);
      if (sortMode == 'price_low') {
        sorted.sort((a, b) => _priceValue(a).compareTo(_priceValue(b)));
      } else if (sortMode == 'price_high') {
        sorted.sort((a, b) => _priceValue(b).compareTo(_priceValue(a)));
      }
      if (mounted) setState(() { products = sorted; isLoading = false; });
    } catch (e) {
      if (mounted) setState(() {
        products = [];
        loadError = _friendlyNetworkError(e);
        isLoading = false;
      });
    }
  }

  String _friendlyNetworkError(Object error) => friendlyNetworkError(context, error);

  double _priceValue(dynamic item) => double.tryParse('${item['price'] ?? 0}'.replaceAll(',', '')) ?? 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCategory(Map<String, dynamic> category) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SubcategoryScreen(category: category)));
  }

  void _toggleLanguage() {
    final current = Localizations.localeOf(context).languageCode;
    BazarBuzurgApp.setLocale(context, Locale(current == 'fa' ? 'ps' : 'fa'));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final isTablet = width >= 620;
    final visibleCategories = categories.take(isWide ? 10 : (isTablet ? 8 : 6)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(isWide ? 22 : 12, 10, isWide ? 22 : 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BazarekTopBar(
                          selectedProvince: selectedProvince,
                          onProvinceChanged: (val) { setState(() => selectedProvince = val ?? ''); _loadProducts(); },
                          onLanguage: _toggleLanguage,
                        ),
                        const SizedBox(height: 10),
                        _BazarekSearchBar(
                          controller: _searchController,
                          onChanged: (value) {
                            searchQuery = value;
                            Future.delayed(const Duration(milliseconds: 450), () {
                              if (!mounted || searchQuery != value) return;
                              _loadProducts();
                            });
                          },
                          onSubmit: () => _loadProducts(),
                        ),
                        const SizedBox(height: 12),
                        _CategoryStrip(
                          categories: visibleCategories,
                          onCategory: _openCategory,
                          onMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                        ),
                        const SizedBox(height: 12),
                        _HomeQuickActions(
                          sortMode: sortMode,
                          onSort: (mode) { setState(() => sortMode = mode); _loadProducts(); },
                          onBoost: () async {
                            if (!await requireAccount(context)) return;
                            if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProductsScreen()));
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: Text(
                              selectedCategory.isEmpty && selectedProvince.isEmpty && searchQuery.trim().isEmpty
                                  ? tr(context, 'fresh_ads')
                                  : (Localizations.localeOf(context).languageCode == 'ps' ? 'د اعلانونو پایلې' : 'نتایج جستجو'),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                            )),
                            if (products.isNotEmpty)
                              Text('${products.length} ${Localizations.localeOf(context).languageCode == 'ps' ? 'اعلان' : 'آگهی'}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 7),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isLoading)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
            else if (loadError != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: OfflineErrorView(onRetry: _loadProducts, message: loadError),
              )
            else if (products.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(psText(context, 'هنوز هیچ آگهی فعالی ثبت نشده است.', 'تر اوسه کوم فعال اعلان نشته.'), textAlign: TextAlign.center))))
            else
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(isWide ? 22 : 12, 0, isWide ? 22 : 12, 30),
                      child: Column(
                        children: [
                          for (var i = 0; i < products.length; i++) ...[
                            _DivarStyleListing(item: products[i]),
                            if (i == 4) ...[
                              const SizedBox(height: 8),
                              _InlineBoostCard(onTap: () async {
                                if (!await requireAccount(context)) return;
                                if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProductsScreen()));
                              }),
                            ],
                            if (i != products.length - 1) const Divider(height: 1, indent: 0, endIndent: 0),
                          ],
                        ],
                      ),
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

class _BazarekSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  const _BazarekSearchBar({required this.controller, required this.onChanged, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmit(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: tr(context, 'search_hint'),
            prefixIcon: const Icon(Icons.search_rounded, size: 29),
            suffixIcon: IconButton(onPressed: onSubmit, icon: const Icon(Icons.tune_rounded)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.black.withOpacity(.07))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.black.withOpacity(.07))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'province') {
            showModalBottomSheet(context: context, showDragHandle: true, builder: (_) => SafeArea(child: ListView(padding: const EdgeInsets.only(bottom: 18), children: [
              ListTile(title: Text(tr(context, 'all_provinces')), leading: const Icon(Icons.public), onTap: () { Navigator.pop(context, ''); }),
              ...provinces.map((p) => ListTile(title: Text(localizedProvince(context, p)), leading: const Icon(Icons.location_on_outlined), onTap: () { Navigator.pop(context, p); })),
            ]))).then((value) {
              if (value is String) {
                final state = context.findAncestorStateOfType<_HomeScreenState>();
                state?.setState(() => state.selectedProvince = value);
                state?._loadProducts();
              }
            });
          }
        },
        itemBuilder: (_) => [PopupMenuItem(value: 'province', child: Text(psText(context, 'انتخاب ولایت', 'ولایت وټاکئ')))],
        child: Container(width: 52, height: 52, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.location_on_outlined, color: Colors.white)),
      ),
    ]);
  }
}

class _BazarekTopBar extends StatelessWidget {
  final String selectedProvince;
  final ValueChanged<String?> onProvinceChanged;
  final VoidCallback onLanguage;
  const _BazarekTopBar({required this.selectedProvince, required this.onProvinceChanged, required this.onLanguage});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      PopupMenuButton<String>(
        onSelected: onProvinceChanged,
        itemBuilder: (context) => [PopupMenuItem<String>(value: '', child: Text(tr(context, 'all_provinces'))), ...provinces.map((p) => PopupMenuItem<String>(value: p, child: Text(localizedProvince(context, p))))],
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.black.withOpacity(.07))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.location_on_outlined, size: 20), const SizedBox(width: 5), Text(selectedProvince.isEmpty ? tr(context, 'all_provinces') : localizedProvince(context, selectedProvince), style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(width: 2), const Icon(Icons.keyboard_arrow_down_rounded, size: 18)])),
      ),
      const Spacer(),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('بازارک', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
        Text(psText(context, 'خرید و فروش در سراسر افغانستان', 'په ټول افغانستان کې پېر او پلور'), style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ]),
      const SizedBox(width: 8),
      Container(width: 50, height: 50, padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 10)]), child: Image.asset('assets/icon/bazarek_icon.png', fit: BoxFit.cover)),
      IconButton(tooltip: psText(context, 'زبان', 'ژبه'), onPressed: onLanguage, icon: const Icon(Icons.translate_rounded)),
    ]);
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final ValueChanged<Map<String, dynamic>> onCategory;
  final VoidCallback onMore;
  const _CategoryStrip({required this.categories, required this.onCategory, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text(tr(context, 'categories'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))), TextButton(onPressed: onMore, child: Text(tr(context, 'view_all')))]),
      SizedBox(height: 86, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: categories.length + 1, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) {
        if (i == categories.length) return InkWell(onTap: onMore, child: Container(width: 92, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.black.withOpacity(.06))), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.apps_rounded, size: 28), SizedBox(height: 5), Text('بیشتر', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))])));
        final c = categories[i];
        return InkWell(onTap: () => onCategory(c), borderRadius: BorderRadius.circular(17), child: Container(width: 92, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.black.withOpacity(.06))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle), child: Icon(c['icon'] as IconData, color: Theme.of(context).colorScheme.primary, size: 21)), const SizedBox(height: 4), Text(localizedCategoryTitle(context, c['id'] as String, c['title'] as String), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800))])));
      }))
    ]);
  }
}

class _HomeQuickActions extends StatelessWidget {
  final String sortMode;
  final ValueChanged<String> onSort;
  final VoidCallback onBoost;
  const _HomeQuickActions({required this.sortMode, required this.onSort, required this.onBoost});

  @override
  Widget build(BuildContext context) {
    final ps = Localizations.localeOf(context).languageCode == 'ps';
    return Row(children: [
      _FilterChip(label: ps ? 'نوي' : 'جدیدترین', selected: sortMode == 'newest', onTap: () => onSort('newest')),
      const SizedBox(width: 6),
      _FilterChip(label: ps ? 'ارزانه' : 'ارزان‌ترین', selected: sortMode == 'price_low', onTap: () => onSort('price_low')),
      const SizedBox(width: 6),
      _FilterChip(label: ps ? 'ګران' : 'گران‌ترین', selected: sortMode == 'price_high', onTap: () => onSort('price_high')),
      const Spacer(),
      OutlinedButton.icon(onPressed: onBoost, icon: const Icon(Icons.rocket_launch_rounded, size: 16), label: Text(ps ? 'ځانګړی کول' : 'ویژه‌سازی'), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9))),
    ]);
  }
}

class _FilterChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: selected ? Theme.of(context).colorScheme.primary : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.black.withOpacity(.07))), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: selected ? Colors.white : Colors.black87))));
}

class _InlineBoostCard extends StatelessWidget {
  final VoidCallback onTap;
  const _InlineBoostCard({required this.onTap});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF173C91), Color(0xFF0B72E7)]), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Text('🚀', style: TextStyle(fontSize: 22)), const SizedBox(width: 8), Expanded(child: Text(psText(context, 'آگهی‌ات را ویژه کن و بیشتر دیده شو.', 'خپل اعلان ځانګړی کړه او ډېر ولیدل شه.'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))), TextButton(onPressed: onTap, child: Text(psText(context, 'ویژه‌سازی', 'ځانګړی کول'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))]));
}

Widget _bazarekImageLoading(BuildContext context, Widget child, ImageChunkEvent? progress) {
  if (progress == null) return child;
  final expected = progress.expectedTotalBytes;
  final value = expected != null && expected > 0
      ? (progress.cumulativeBytesLoaded / expected).clamp(0.0, 1.0)
      : null;
  return Container(
    color: const Color(0xFFEAF2FF),
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(strokeWidth: 3.5),
        ),
        const SizedBox(height: 7),
        Text(
          'در حال بارگذاری عکس...',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF174A8B)),
        ),
        if (value != null) ...[
          const SizedBox(height: 5),
          SizedBox(width: 90, child: LinearProgressIndicator(value: value, minHeight: 4)),
        ],
      ],
    ),
  );
}

String _optimizedImageUrl(String url, {int width = 720, int quality = 78}) {
  final u = url.trim();
  if (u.isEmpty) return u;
  // Supabase Storage Image Transformations keep original files intact while
  // delivering smaller, faster images to browsers and phones.
  final marker = '/storage/v1/object/public/';
  if (!u.contains(marker)) return u;
  final transformed = u.replaceFirst(marker, '/storage/v1/render/image/public/');
  final separator = transformed.contains('?') ? '&' : '?';
  return '$transformed${separator}width=$width&quality=$quality';
}


String _displayListingPrice(BuildContext context, dynamic item) {
  final raw = item['price'];
  final n = num.tryParse(raw?.toString() ?? '') ?? 0;
  final negotiable = item['is_negotiable'] == true;
  final currency = (item['currency']?.toString().toUpperCase() == 'USD') ? 'USD' : 'AFN';
  final amount = n <= 0 ? tr(context, 'free') : (currency == 'USD' ? '\$${NumberFormatHelper.format(n)}' : '${NumberFormatHelper.format(n)} ${tr(context, 'afghani')}');
  return negotiable ? '$amount • ${tr(context, 'price_negotiable')}' : amount;
}

class _DivarStyleListing extends StatelessWidget {
  final dynamic item;
  const _DivarStyleListing({required this.item});

  @override
  Widget build(BuildContext context) {
    List<dynamic> images = [];
    try {
      final raw = item['image_url'];
      if (raw is String && raw.isNotEmpty) images = jsonDecode(raw);
      if (raw is List) images = raw;
    } catch (_) {}
    final imageUrl = images.isNotEmpty ? images.first.toString() : '';
    final priceRaw = item['price'];
    final priceText = _displayListingPrice(context, item);
    final province = localizedProvince(context, item['province']?.toString() ?? '');
    final location = (item['location_text'] ?? '').toString().trim();
    final boost = localizedBoostLabel(context, item['boost_label']?.toString() ?? '');
    final count = images.length;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: item))),
      child: Container(
        constraints: const BoxConstraints(minHeight: 128),
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 126, height: 112, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Stack(fit: StackFit.expand, children: [
            imageUrl.isNotEmpty ? Image.network(_optimizedImageUrl(imageUrl), fit: BoxFit.cover, loadingBuilder: _bazarekImageLoading, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE9EDF3), child: Icon(Icons.image_not_supported_outlined, size: 34))) : const ColoredBox(color: Color(0xFFE9EDF3), child: Icon(Icons.image_outlined, size: 34)),
            if (count > 1) Positioned(left: 7, top: 7, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(.62), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.photo_library_outlined, color: Colors.white, size: 13), const SizedBox(width: 3), Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))]))),
            if (boost.isNotEmpty)
  Positioned(
    right: 7,
    top: 7,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8A00),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        boost,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  ),

if (item['turbo_active'] == true)
  Positioned(
    left: 7,
    bottom: 7,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.58),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        psText(context, '⚡ توربو', '⚡ توربو'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  ),
          ]))),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: LocalizedText(item['title']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1.25))), const SizedBox(width: 4), _SaveButton(item: item)]),
            const SizedBox(height: 8),
            Text(priceText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 7),
            if (province.isNotEmpty || location.isNotEmpty) Text([province, location].where((x) => x.isNotEmpty).join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            Row(children: [const Icon(Icons.schedule_rounded, size: 13, color: Colors.black45), const SizedBox(width: 4), Expanded(child: Text(_listingTime(item['created_at']), style: const TextStyle(fontSize: 10, color: Colors.black45))), if (item['seller_name']?.toString().trim().isNotEmpty == true) Text(item['seller_name'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w700))]),
          ])),
        ]),
      ),
    );
  }

  String _listingTime(dynamic raw) {
    final value = DateTime.tryParse(raw?.toString() ?? '');
    if (value == null) return '';
    final d = DateTime.now().difference(value.toLocal());
    if (d.inMinutes < 60) return '${d.inMinutes.clamp(1, 59)} دقیقه پیش';
    if (d.inHours < 24) return '${d.inHours} ساعت پیش';
    if (d.inDays < 7) return '${d.inDays} روز پیش';
    return '${value.toLocal().year}/${value.toLocal().month.toString().padLeft(2, '0')}/${value.toLocal().day.toString().padLeft(2, '0')}';
  }
}

class _SaveButton extends StatefulWidget {
  final dynamic item;
  const _SaveButton({required this.item});
  @override State<_SaveButton> createState() => _SaveButtonState();
}
class _SaveButtonState extends State<_SaveButton> {
  bool saved = false;
  @override void initState() { super.initState(); _read(); }
  Future<void> _read() async { final p = await SharedPreferences.getInstance(); final id = widget.item['id']?.toString(); if (mounted) setState(() => saved = id != null && (p.getStringList('saved_ad_ids') ?? []).contains(id)); }
  Future<void> _toggle() async { final id = widget.item['id']?.toString(); if (id == null) return; final p = await SharedPreferences.getInstance(); final ids = p.getStringList('saved_ad_ids') ?? []; if (ids.contains(id)) { ids.remove(id); saved = false; } else { ids.add(id); saved = true; } await p.setStringList('saved_ad_ids', ids); if (mounted) setState(() {}); }
  @override Widget build(BuildContext context) => IconButton(onPressed: _toggle, visualDensity: VisualDensity.compact, icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: saved ? Colors.red : Colors.black45, size: 21));
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, required this.icon, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 7),
        Expanded(child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
        if (actionText != null)
          TextButton(onPressed: onAction, child: Text(actionText!, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700))),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 112,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(.05)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 12, offset: const Offset(0, 5))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle), child: Icon(category['icon'] as IconData, color: theme.colorScheme.primary, size: 26)),
          const SizedBox(height: 7),
          Text(localizedCategoryTitle(context, category['id'] as String, category['title'] as String), maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _MoreCategoryTile extends StatelessWidget {
  final VoidCallback onTap;
  const _MoreCategoryTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 112,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(.12))),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.apps_rounded, size: 34),
          SizedBox(height: 10),
          Text('بیشتر', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _SpecialBoostSection extends StatelessWidget {
  final List<dynamic> products;
  const _SpecialBoostSection({required this.products});

  @override
  Widget build(BuildContext context) {
    final special = products.where((item) {
      final featured = item['is_featured'] == true || item['is_featured'] == 1;
      final pinned = item['is_pinned'] == true || item['is_pinned'] == 1;
      final level = int.tryParse('${item['effective_boost_level'] ?? item['boost_level'] ?? 0}') ?? 0;
      return featured || pinned || level > 0;
    }).take(8).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF2F6FED).withOpacity(.10))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Text('✨', style: TextStyle(fontSize: 21)),
          const SizedBox(width: 7),
          const Expanded(child: Text('آگهی‌های ویژه و بوست‌شده', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
          if (AuthService.isLoggedIn) TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProductsScreen())), icon: const Icon(Icons.rocket_launch_rounded, size: 17), label: const Text('بوست آگهی')),
        ]),
        const SizedBox(height: 3),
        Text(special.isEmpty ? 'آگهی خودت را با بوست در این بخش برجسته کن.' : 'آگهی‌های برجسته برای دیده‌شدن سریع‌تر.', style: Theme.of(context).textTheme.bodySmall),
        if (special.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Row(children: [
              const Expanded(child: Text('هنوز آگهی ویژه‌ای اینجا نیست. اولین آگهی ویژه بازارک را تو بساز!', style: TextStyle(fontWeight: FontWeight.w600))),
              if (AuthService.isLoggedIn) FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProductsScreen())), child: const Text('شروع')),
            ]),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: special.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _SpecialCard(item: special[index]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _SpecialCard extends StatelessWidget {
  final dynamic item;
  const _SpecialCard({required this.item});

  @override
  Widget build(BuildContext context) {
    List<dynamic> images = [];
    try {
      final raw = item['image_url'];
      if (raw is String && raw.isNotEmpty) images = jsonDecode(raw);
      if (raw is List) images = raw;
    } catch (_) {}
    final imageUrl = images.isNotEmpty ? images.first.toString() : '';
    final label = localizedBoostLabel(context, item['boost_label']?.toString() ?? '');
    return SizedBox(
      width: 220,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: item))),
          child: Row(children: [
            SizedBox(width: 86, height: 188, child: imageUrl.isNotEmpty ? Image.network(_optimizedImageUrl(imageUrl), fit: BoxFit.cover, loadingBuilder: _bazarekImageLoading, errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12, child: Icon(Icons.image_not_supported))) : const ColoredBox(color: Colors.black12, child: Icon(Icons.image, size: 30))),
            Expanded(child: Padding(padding: const EdgeInsets.all(9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(8)), child: Text(label.isEmpty ? '✨ ویژه' : label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
              const SizedBox(height: 8),
              LocalizedText(item['title']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 8),
              Text(_displayListingPrice(context, item), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF00695C), fontSize: 13)),
            ]))),
          ]),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic item;
  const _ProductCard({required this.item});

  @override
  Widget build(BuildContext context) {
    List<dynamic> images = [];
    try {
      final raw = item['image_url'];
      if (raw is String && raw.isNotEmpty) images = jsonDecode(raw);
      if (raw is List) images = raw;
    } catch (_) {}
    final imageUrl = images.isNotEmpty ? images.first.toString() : '';
    final price = _displayListingPrice(context, item);
    final boostLabel = localizedBoostLabel(context, item['boost_label']?.toString() ?? '');
    final location = '${localizedProvince(context, item['province']?.toString() ?? '')}${(item['location_text'] ?? '').toString().isNotEmpty ? ' • ${item['location_text']}' : ''}';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      shadowColor: const Color(0x220B2A55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x0D0B2A55))),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: item))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            flex: 7,
            child: Stack(fit: StackFit.expand, children: [
              imageUrl.isNotEmpty
                  ? Image.network(_optimizedImageUrl(imageUrl), fit: BoxFit.cover, loadingBuilder: _bazarekImageLoading, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE9EDF4), child: Icon(Icons.image_not_supported_outlined, size: 36)))
                  : const ColoredBox(color: Color(0xFFE9EDF4), child: Icon(Icons.image_outlined, size: 36)),
              if (boostLabel.isNotEmpty)
                Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(9)), child: Text(boostLabel, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
              if (item['turbo_active'] == true)
                Positioned(left: 8, bottom: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(.58), borderRadius: BorderRadius.circular(9)), child: Text(psText(context, '⚡ توربو', '⚡ توربو'), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)))),
              Positioned(top: 8, left: 8, child: _SaveAdButton(item: item)),
            ]),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LocalizedText(item['title']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF102A43), height: 1.2)),
                const Spacer(),
                Text(price, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF00695C), fontSize: 14)),
                const SizedBox(height: 4),
                Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}


class _SaveAdButton extends StatefulWidget {
  final dynamic item;
  const _SaveAdButton({required this.item});
  @override State<_SaveAdButton> createState() => _SaveAdButtonState();
}
class _SaveAdButtonState extends State<_SaveAdButton> {
  bool saved = false;
  @override void initState() { super.initState(); _read(); }
  Future<void> _read() async { final p = await SharedPreferences.getInstance(); final id = widget.item['id']?.toString(); if (mounted) setState(() => saved = id != null && (p.getStringList('saved_ad_ids') ?? []).contains(id)); }
  Future<void> _toggle() async {
    final id = widget.item['id']?.toString(); if (id == null) return;
    final p = await SharedPreferences.getInstance(); final ids = p.getStringList('saved_ad_ids') ?? [];
    if (ids.contains(id)) { ids.remove(id); saved = false; } else { ids.add(id); saved = true; }
    await p.setStringList('saved_ad_ids', ids); if (mounted) setState(() {});
  }
  @override Widget build(BuildContext context) => Material(child: InkWell(onTap: _toggle, borderRadius: BorderRadius.circular(20), child: Container(width: 31, height: 31, decoration: BoxDecoration(color: Colors.white.withOpacity(.92), shape: BoxShape.circle), child: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 18, color: saved ? Colors.red : null))));
}

class NumberFormatHelper {
  static String format(dynamic value) {
    final n = num.tryParse(value?.toString() ?? '') ?? 0;
    final raw = n.toInt().toString();
    return raw.replaceAllMapped(RegExp(r'(?<=\d)(?=(\d{3})+$)'), (_) => '.');
  }
}

class _ProductImageGallery extends StatefulWidget {
  final List<dynamic> images;
  const _ProductImageGallery({required this.images});

  @override
  State<_ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<_ProductImageGallery> {
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return SizedBox(
      height: 250,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) => setState(() => currentPage = index),
            itemBuilder: (_, i) => Image.network(
              _optimizedImageUrl(images[i].toString(), width: 1200, quality: 82),
              fit: BoxFit.cover,
              loadingBuilder: _bazarekImageLoading,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFE9EDF3),
                child: Center(child: Icon(Icons.image_not_supported_outlined, size: 52)),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(.62), borderRadius: BorderRadius.circular(14)),
                child: Text('${currentPage + 1} / ${images.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length > 12 ? 12 : images.length,
                  (i) => Container(
                    width: i == currentPage ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(color: i == currentPage ? Colors.white : Colors.white54, borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final dynamic product;
  const ProductDetailScreen({super.key, required this.product});

  Future<void> _reportListing(BuildContext context) async {
    if (!await requireAccount(context)) return;
    if (!context.mounted) return;

    final ps = Localizations.localeOf(context).languageCode == 'ps';
    final reasons = ps
        ? <String>['درغلي اعلان', 'جعلي/ناسم اعلان', 'نامناسب يا سپکاوی کوونکی محتوا', 'منع شوی توکی یا خدمت', 'سپیم یا تکراري اعلان', 'نور']
        : <String>['کلاهبرداری یا فریب', 'آگهی جعلی یا اطلاعات نادرست', 'محتوای نامناسب یا توهین‌آمیز', 'کالای یا خدمات ممنوع', 'اسپم یا آگهی تکراری', 'سایر'];
    String selected = reasons.first;
    final other = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(ps ? 'د اعلان راپور' : 'گزارش آگهی'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ps ? 'د دې اعلان د ستونزې دلیل وټاکئ:' : 'دلیل گزارش را انتخاب کنید:'),
                  const SizedBox(height: 8),
                  ...reasons.map((reason) => RadioListTile<String>(
                        value: reason,
                        groupValue: selected,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(reason),
                        onChanged: (value) {
                          if (value != null) setLocal(() => selected = value);
                        },
                      )),
                  if (selected == reasons.last) ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: other,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: ps ? 'تفصیل' : 'توضیحات',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(ps ? 'لغوه' : 'انصراف')),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.send_outlined),
              label: Text(ps ? 'راپور لېږل' : 'ارسال گزارش'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true) {
      other.dispose();
      return;
    }

    final reason = selected == reasons.last && other.text.trim().isNotEmpty
        ? '${selected}: ${other.text.trim()}'
        : selected;
    try {
      await ApiService.submitReport(listingId: product['id']?.toString() ?? '', reason: reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ps ? 'ستاسو راپور ثبت شو او مدیریت به یې وڅېړي.' : 'گزارش شما ثبت شد و توسط مدیریت بررسی می‌شود.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      other.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> images = [];
    try {
      if (product['image_url'] != null) {
        images = jsonDecode(product['image_url']);
      }
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'details')),
        actions: [
          IconButton(
            tooltip: Localizations.localeOf(context).languageCode == 'ps' ? 'د اعلان راپور' : 'گزارش آگهی',
            onPressed: () => _reportListing(context),
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              _ProductImageGallery(images: images)
            else
              Container(
                height: 200,
                color: Colors.grey.shade300,
                child: const Center(child: Icon(Icons.image, size: 80)),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    product['title']?.toString() ?? '',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF102A43), height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _displayListingPrice(context, product),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF00695C),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SellerCard(product: product),
                  const SizedBox(height: 10),
                  _ListingLikeBar(listingId: product['id']?.toString() ?? ''),
                  const Divider(height: 32),
                  Text(
                    tr(context, 'description'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LocalizedText(product['description']?.toString() ?? 'بدون توضیحات'),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(localizedProvince(context, product['province']?.toString() ?? '')),
                    subtitle: LocalizedText(product['location_text']?.toString() ?? ''),
                  ),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _reportListing(context),
                      icon: const Icon(Icons.flag_outlined),
                      label: Text(psText(context, 'گزارش آگهی', 'د اعلان راپور')),
                    ),
                  ),
                  if ((product['external_link'] ?? '').toString().trim().isNotEmpty) ...[
                    const Divider(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final raw = product['external_link'].toString().trim();
                          final uri = Uri.tryParse(raw);
                          if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لینک صفحه معتبر نیست.')));
                            return;
                          }
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: Text(tr(context, 'open_link')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (product['show_phone'] == true || product['show_phone'] == 1)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    var phone = product['contact_phone']?.toString().trim() ?? '';
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(psText(context, 'شماره تماس ثبت نشده است.', 'د اړیکې شمېره نه ده ثبت شوې.'))),
                      );
                      return;
                    }

                    // تبدیل ارقام فارسی/عربی به ارقام انگلیسی برای tel:
                    const fa = '۰۱۲۳۴۵۶۷۸۹';
                    const ar = '٠١٢٣٤٥٦٧٨٩';
                    const en = '0123456789';
                    for (var i = 0; i < 10; i++) {
                      phone = phone.replaceAll(fa[i], en[i]).replaceAll(ar[i], en[i]);
                    }
                    phone = phone.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', '');

                    final uri = Uri(scheme: 'tel', path: phone);
                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(psText(context, 'امکان تماس با $phone وجود ندارد.', 'له $phone سره اړیکه نه شي نیول کېدای.'))),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(psText(context, 'باز کردن تماس تلفنی ناموفق بود.', 'تلیفوني اړیکه پرانیستل شوه نه.'))),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.phone),
                  label: Text(tr(context, 'call_seller')),
                ),
              ),
            if (product['allow_chat'] == true || product['allow_chat'] == 1) ...[
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    if (!await requireAccount(context)) return;
                    try {
                      final conversation = await ApiService.startConversation(product['id'].toString());
                      final conversationId = conversation['id']?.toString();
                      if (!context.mounted) return;
                      if (conversationId == null || conversationId.isEmpty) {
                        throw Exception('گفتگو ایجاد نشد.');
                      }
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          conversationId: conversationId,
                          title: product['title']?.toString() ?? 'گفتگو با فروشنده',
                        ),
                      ));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(friendlyNetworkError(context, e))),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat),
                  label: Text(tr(context, 'chat_seller')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  final dynamic product;
  const _SellerCard({required this.product});
  @override
  Widget build(BuildContext context) {
    final sellerId = product['vendor_id']?.toString() ?? '';
    final name = product['seller_name']?.toString().trim().isNotEmpty == true ? product['seller_name'].toString() : 'فروشنده بازارک';
    if (sellerId.isEmpty) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: const Text('مشاهده پروفایل فروشنده، آگهی‌ها و امتیاز'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SellerProfileScreen(sellerId: sellerId, sellerName: name))),
      ),
    );
  }
}

class _ListingLikeBar extends StatefulWidget {
  final String listingId;
  const _ListingLikeBar({required this.listingId});
  @override State<_ListingLikeBar> createState() => _ListingLikeBarState();
}
class _ListingLikeBarState extends State<_ListingLikeBar> {
  bool liked = false;
  int count = 0;
  bool loading = false;
  @override
  void initState() { super.initState(); }
  Future<void> _toggle() async {
    if (widget.listingId.isEmpty || loading) return;
    if (!AuthService.isLoggedIn) { await requireAccount(context); return; }
    setState(() { loading = true; });
    try {
      final result = await ApiService.toggleListingLike(widget.listingId, !liked);
      if (mounted) setState(() { liked = result['liked'] == true; count = int.tryParse('${result['likes_count'] ?? count}') ?? count; loading = false; });
    } catch (e) {
      if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyNetworkError(context, e)))); }
    }
  }
  @override Widget build(BuildContext context) => Card(child: ListTile(onTap: _toggle, leading: Icon(liked ? Icons.thumb_up : Icons.thumb_up_outlined), title: Text(liked ? 'پسندیده شد' : 'پسندیدن آگهی'), trailing: Text('$count پسند', style: const TextStyle(fontWeight: FontWeight.w800))));
}

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  const SellerProfileScreen({super.key, required this.sellerId, this.sellerName = 'فروشنده بازارک'});
  @override State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}
class _SellerProfileScreenState extends State<SellerProfileScreen> {
  bool loading = true, following = false, busy = false;
  Map<String,dynamic> profile = {};
  List<dynamic> listings = [], comments = [];
  String? error;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final p = await ApiService.getSellerProfile(widget.sellerId);
      final l = await ApiService.getSellerListings(widget.sellerId);
      final c = await ApiService.getSellerComments(widget.sellerId);
      if (mounted) setState(() { profile=p; listings=l; comments=c; following=p['is_following']==true; loading=false; error=null; });
    } catch(e) { if(mounted) setState(() {loading=false; error=friendlyNetworkError(context,e);}); }
  }
  Future<void> _follow() async {
    if (!AuthService.isLoggedIn) { await requireAccount(context); return; }
    setState(()=>busy=true);
    try { final r=await ApiService.toggleSellerFollow(widget.sellerId,!following); if(mounted)setState(()=>following=r['following']==true); }
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyNetworkError(context,e))));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> _rate() async {
    if (!AuthService.isLoggedIn) { await requireAccount(context); return; }
    int value=5;
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('امتیاز به فروشنده'),content:StatefulBuilder(builder:(c,set)=>Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(5,(i)=>IconButton(onPressed:()=>set(()=>value=i+1),icon:Icon(i<value?Icons.star:Icons.star_border,color:Colors.amber,size:30)))),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('ثبت'))]));
    if(ok!=true)return;
    try{await ApiService.rateSeller(widget.sellerId,value);await _load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('امتیاز شما ثبت شد.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyNetworkError(context,e))));}
  }
  Future<void> _comment() async {
    if (!AuthService.isLoggedIn) { await requireAccount(context); return; }
    final c=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('دیدگاه شما'),content:TextField(controller:c,maxLines:4,maxLength:500,decoration:const InputDecoration(hintText:'نظر خود را بنویسید...')),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(d,c.text.trim().isNotEmpty),child:const Text('ثبت دیدگاه'))]));
    if(ok!=true)return;
    try{await ApiService.addSellerComment(widget.sellerId,c.text);await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyNetworkError(context,e))));}finally{c.dispose();}
  }
  @override Widget build(BuildContext context){
    if(loading)return Scaffold(appBar:AppBar(title:Text(widget.sellerName)),body:const Center(child:CircularProgressIndicator()));
    if(error!=null)return Scaffold(appBar:AppBar(title:Text(widget.sellerName)),body:Center(child:Text(error!,textAlign:TextAlign.center)));
    final name=profile['shop_name']?.toString().trim().isNotEmpty==true?profile['shop_name'].toString():(profile['full_name']?.toString().trim().isNotEmpty==true?profile['full_name'].toString():widget.sellerName);
    final avatar=profile['avatar_url']?.toString()??''; final followers=int.tryParse('${profile['followers_count']??0}')??0; final rating=double.tryParse('${profile['rating']??0}')??0;
    return Scaffold(appBar:AppBar(title:Text(name),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),body:RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(12),children:[
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[CircleAvatar(radius:46,backgroundImage:avatar.isNotEmpty?NetworkImage(avatar):null,child:avatar.isEmpty?const Icon(Icons.person,size:46):null),const SizedBox(height:10),Text(name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),if((profile['city']??'').toString().isNotEmpty)Text('📍 ${profile['city']}',style:const TextStyle(color:Colors.black54)),if((profile['bio']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(profile['bio'].toString(),textAlign:TextAlign.center)),const SizedBox(height:12),Row(mainAxisAlignment:MainAxisAlignment.center,children:[Text('$followers دنبال‌کننده'),const SizedBox(width:20),Text('⭐ ${rating.toStringAsFixed(1)}')]),const SizedBox(height:12),Wrap(spacing:8,children:[FilledButton.icon(onPressed:busy?null:_follow,icon:Icon(following?Icons.notifications_active:Icons.notifications_none),label:Text(following?'دنبال می‌کنم':'دنبال کردن')),OutlinedButton.icon(onPressed:_rate,icon:const Icon(Icons.star_outline),label:const Text('امتیاز')),OutlinedButton.icon(onPressed:_comment,icon:const Icon(Icons.comment_outlined),label:const Text('دیدگاه'))])]))),
      Padding(padding:const EdgeInsets.fromLTRB(4,12,4,8),child:Text('آگهی‌های این فروشنده (${listings.length})',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))),
      if(listings.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Center(child:Text('این فروشنده آگهی فعالی ندارد.'))),
      ...listings.map((x)=>_DivarStyleListing(item:x)),
      const Divider(height:28),
      const Text('دیدگاه‌ها',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),
      if(comments.isEmpty)const Padding(padding:EdgeInsets.all(16),child:Text('هنوز دیدگاهی ثبت نشده است.')),
      ...comments.map((x)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.person,size:18)),title:Text(x['user_name']?.toString()??'کاربر بازارک',style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(x['comment']?.toString()??''),trailing:x['rating']!=null?Text('⭐ ${x['rating']}'):null)),
    ])));
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> conversations = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AuthService.isLoggedIn) {
      if (mounted) setState(() { loading = false; });
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final data = await ApiService.getConversations();
      if (mounted) setState(() { conversations = data; loading = false; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = friendlyNetworkError(context, e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService.authVersion,
      builder: (context, _, __) {
        if (!AuthService.isLoggedIn) {
          return Scaffold(
            appBar: AppBar(title: Text(tr(context, 'chat'))),
            body: Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_outline, size: 64),
                const SizedBox(height: 16),
                Text(psText(context, 'برای ارسال و دریافت پیام، ابتدا حساب خود را بسازید یا وارد حساب شوید.', 'د پیغامونو لېږلو او ترلاسه کولو لپاره لومړی خپل حساب جوړ یا دننه شئ.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
                const SizedBox(height: 20),
                FilledButton.icon(onPressed: () => requireAccount(context), icon: const Icon(Icons.login), label: Text(psText(context, 'ورود / ثبت‌نام', 'ننوتل / نوم لیکنه'))),
              ]),
            )),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(tr(context, 'chat')),
            actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 54),
                      const SizedBox(height: 12),
                      Text(error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(psText(context, 'تلاش دوباره', 'بیا هڅه'))),
                    ])))
                  : conversations.isEmpty
                      ? Center(child: Text(psText(context, 'هنوز گفتگویی ندارید. از داخل یک آگهی روی «چت با فروشنده» بزنید.', 'تر اوسه کومه خبرې اترې نشته. د یوه اعلان له دننه «له پلورونکي سره چټ» ووهئ.')))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: conversations.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final c = conversations[index];
                              final image = c['listing_image_url']?.toString() ?? '';
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 27,
                                  backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                                  child: image.isEmpty ? const Icon(Icons.person) : null,
                                ),
                                title: Text(c['other_user_name']?.toString().trim().isNotEmpty == true ? c['other_user_name'].toString() : 'کاربر بازارک'),
                                subtitle: Text(c['listing_title']?.toString() ?? 'آگهی', maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: const Icon(Icons.chevron_left),
                                onTap: () {
                                  final id = c['id']?.toString();
                                  if (id == null || id.isEmpty) return;
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatDetailScreen(conversationId: id, title: c['other_user_name']?.toString() ?? 'گفتگو'))).then((_) => _load());
                                },
                              );
                            },
                          ),
                        ),
        );
      },
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  const ChatDetailScreen({super.key, required this.conversationId, required this.title});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final data = await ApiService.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() { messages = data; loading = false; error = null; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) scrollController.jumpTo(scrollController.position.maxScrollExtent);
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = friendlyNetworkError(context, e); });
    }
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;
    setState(() { sending = true; });
    try {
      final sent = await ApiService.sendMessage(widget.conversationId, text);
      controller.clear();
      if (mounted) {
        setState(() { messages.add(sent); sending = false; });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { sending = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyNetworkError(context, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = AuthService.userId?.toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [IconButton(onPressed: _loadMessages, icon: const Icon(Icons.refresh))],
      ),
      body: Column(children: [
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 54), const SizedBox(height: 12), Text(error!, textAlign: TextAlign.center), const SizedBox(height: 16),
                      FilledButton.icon(onPressed: _loadMessages, icon: const Icon(Icons.refresh), label: Text(psText(context, 'تلاش دوباره', 'بیا هڅه'))),
                    ])))
                  : messages.isEmpty
                      ? Center(child: Text(psText(context, 'گفتگو را شروع کنید.', 'خبرې اترې پیل کړئ.')))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final m = messages[index];
                            final mine = myId != null && m['sender_id']?.toString() == myId;
                            return Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(m['message']?.toString() ?? ''),
                              ),
                            );
                          },
                        ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: Row(children: [
              Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 4, textInputAction: TextInputAction.newline, decoration: InputDecoration(hintText: psText(context, 'پیام خود را بنویسید...', 'خپل پیغام ولیکئ...'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(22))))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: sending ? null : _send, icon: sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService.authVersion,
      builder: (context, _, __) {
        if (!AuthService.isLoggedIn) {
          return Scaffold(appBar: AppBar(title: Text(tr(context,'add'))), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_outline, size: 64), const SizedBox(height: 16),
            Text(psText(context,'برای ثبت آگهی، ابتدا حساب خود را بسازید یا وارد حساب شوید.','د اعلان ثبتولو لپاره لومړی خپل حساب جوړ یا دننه شئ.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: () => requireAccount(context), icon: const Icon(Icons.login), label: Text(psText(context,'ورود / ثبت‌نام','ننوتل / نوم لیکنه'))),
          ]))));
        }
        return Scaffold(appBar: AppBar(title: Text(tr(context,'add'))), body: const AddProductSheet());
      },
    );
  }
}

class MyProductsScreen extends StatefulWidget {
  final bool activeOnly;
  final bool sortByViews;
  const MyProductsScreen({super.key, this.activeOnly = false, this.sortByViews = false});
  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List<dynamic> ads = [];
  bool loading = true;
  String? error;
  final Map<String, Timer> _pendingDeleteTimers = {};
  final Map<String, dynamic> _pendingDeleteItems = {};

  @override
  void initState() {
    super.initState();
    AuthService.authVersion.addListener(_authChanged);
    _load();
  }

  void _authChanged() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    AuthService.authVersion.removeListener(_authChanged);
    for (final timer in _pendingDeleteTimers.values) {
      timer.cancel();
    }
    _pendingDeleteTimers.clear();
    _pendingDeleteItems.clear();
    super.dispose();
  }

  Future<void> _load() async {
    if (!AuthService.isLoggedIn) {
      if (mounted) setState(() { ads = []; loading = false; error = null; });
      return;
    }
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final data = await ApiService.getMyProducts();
      final filtered = data.where((item) {
        if (!widget.activeOnly) return true;
        final m = item is Map ? item : const <String, dynamic>{};
        final value = m['is_active'];
        return value == true || value.toString().toLowerCase() == 'true' || value.toString() == '1';
      }).toList();
      if (widget.sortByViews) {
        filtered.sort((a, b) {
          final av = int.tryParse('${a is Map ? a['views_count'] ?? 0 : 0}') ?? 0;
          final bv = int.tryParse('${b is Map ? b['views_count'] ?? 0 : 0}') ?? 0;
          return bv.compareTo(av);
        });
      }
      if (mounted) setState(() { ads = filtered; loading = false; error = null; });
    } catch (e) {
      if (mounted) setState(() { ads = []; loading = false; error = friendlyNetworkError(context, e); });
    }
  }

  Future<void> _confirmDelete(dynamic ad) async {
    final id = ad['id']?.toString();
    if (id == null || id.isEmpty) return;
    final title = ad['title']?.toString().trim().isNotEmpty == true ? ad['title'].toString() : psText(context, 'این آگهی', 'دا اعلان');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(psText(context, 'حذف دائمی آگهی', 'د اعلان دایمي حذف')),
        content: Text(psText(context, 'آیا مطمئن هستید «$title» را حذف کنید؟ این آگهی برای همیشه حذف خواهد شد. بعد از تأیید، ۵ ثانیه برای بازگردانی فرصت دارید.', 'ایا ډاډه یاست چې «$title» حذف کړئ؟ دا اعلان به د تل لپاره حذف شي. له تایید وروسته د بېرته راګرځولو لپاره ۵ ثانیې وخت لرئ.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(psText(context, 'انصراف', 'لغوه'))),
          FilledButton.icon(onPressed: () => Navigator.pop(dialogContext, true), icon: const Icon(Icons.delete_forever), label: Text(psText(context, 'حذف', 'حذف'))),
        ],
      ),
    ) ?? false;
    if (!confirmed || !mounted) return;

    _pendingDeleteTimers[id]?.cancel();
    _pendingDeleteItems[id] = ad;
    setState(() => ads.removeWhere((x) => x is Map && x['id']?.toString() == id));

    late Timer timer;
    timer = Timer(const Duration(seconds: 5), () async {
      _pendingDeleteTimers.remove(id);
      final item = _pendingDeleteItems.remove(id);
      try {
        await ApiService.deleteMyProduct(id: id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(psText(context, 'آگهی برای همیشه حذف شد.', 'اعلان د تل لپاره حذف شو.'))));
        }
      } catch (e) {
        if (mounted && item != null) {
          setState(() => ads.insert(0, item));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyNetworkError(context, e))));
        }
      }
    });
    _pendingDeleteTimers[id] = timer;

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(psText(context, 'آگهی حذف می‌شود؛ ۵ ثانیه برای بازگردانی فرصت دارید.', 'اعلان به حذفېدو روان دی؛ د بېرته راګرځولو لپاره ۵ ثانیې وخت لرئ.')),
          action: SnackBarAction(
            label: psText(context, 'بازگردانی', 'بېرته راوستل'),
            onPressed: () {
              final pending = _pendingDeleteTimers.remove(id);
              pending?.cancel();
              final item = _pendingDeleteItems.remove(id);
              if (item != null && mounted) {
                setState(() => ads.insert(0, item));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(psText(context, 'آگهی بازگردانی شد.', 'اعلان بېرته راوګرځول شو.'))));
              }
            },
          ),
        ),
      );
    }
  }

  String _boostText(dynamic ad) {
    if (ad['turbo_active'] == true) return psText(context, '⚡ توربو', '⚡ توربو');
    final level = int.tryParse('${ad['effective_boost_level'] ?? ad['boost_level'] ?? 0}') ?? 0;
    return boostBadgeText(context, level);
  }

  String _turboTimeText(dynamic ad) {
    if (ad['turbo_active'] != true) return '';
    final end = DateTime.tryParse('${ad['turbo_until']}')?.toLocal();
    if (end == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    final endText = '${end.year}/${two(end.month)}/${two(end.day)} ${two(end.hour)}:${two(end.minute)}';
    final start = DateTime.tryParse('${ad['turbo_starts_at']}')?.toLocal();
    final startText = start == null ? '' : '${start.year}/${two(start.month)}/${two(start.day)} ${two(start.hour)}:${two(start.minute)}';
    return startText.isEmpty ? psText(context, 'تر ختم: $endText', 'تر ختم: $endText') : psText(context, 'توربو: $startText تر $endText', 'توربو: $startText تر $endText');
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(context, 'my_ads'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56),
              const SizedBox(height: 12),
              Text(psText(context, 'برای دیدن آگهی‌های خود، ابتدا وارد حساب شوید.', 'د خپلو اعلانونو د لیدلو لپاره لومړی خپل حساب ته ننوځئ.')),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                  if (mounted) _load();
                },
                child: Text(psText(context, 'ورود / ثبت‌نام', 'ننوتل / نوم لیکنه')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'my_ads')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? OfflineErrorView(onRetry: _load, message: error)
              : ads.isEmpty
                  ? Center(child: Text(psText(context, 'شما هنوز هیچ آگهی ثبت نکرده‌اید.', 'تاسو تر اوسه کوم اعلان نه دی ثبت کړی.')))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: ads.length,
                        itemBuilder: (_, i) {
                          final ad = ads[i];
                          final badge = _boostText(ad);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: SizedBox(width: 70, height: 60, child: _imageFor(ad)),
                                  title: Text(ad['title']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(_displayListingPrice(context, ad) + ' • ${ad['province'] ?? ''}'),
                                  trailing: Chip(
                                    avatar: Icon(ad['is_active'] == true ? Icons.check_circle : Icons.pause_circle_outline, size: 18),
                                    label: Text(ad['is_active'] == true ? psText(context, 'فعال', 'فعال') : psText(context, 'غیرفعال', 'غیرفعال')),
                                  ),
                                ),
                                if (ad['moderation_disabled'] == true)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).colorScheme.errorContainer),
                                    child: Text('⚠️ ${psText(context, 'این آگهی توسط مدیریت بازارک به دلیل بررسی قوانین غیرفعال شده است.', 'دا اعلان د بازارک مدیریت له خوا د قوانینو د کتنې له امله غیر فعال شوی دی.')}\n${ad['moderation_reason']?.toString().trim().isNotEmpty == true ? ad['moderation_reason'] : ''}'),
                                  ),
                                SwitchListTile.adaptive(
                                  value: ad['is_active'] == true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  title: Text(ad['is_active'] == true ? psText(context, 'آگهی فعال است', 'اعلان فعال دی') : psText(context, 'آگهی غیرفعال است', 'اعلان غیر فعال دی')),
                                  subtitle: Text(ad['moderation_disabled'] == true
                                      ? psText(context, 'این آگهی توسط مدیریت محدود شده و تا رفع محدودیت قابل فعال‌سازی نیست.', 'دا اعلان د مدیریت له خوا محدود شوی او تر لرې کېدو پورې نه شي فعالېدای.')
                                      : psText(context, 'هر زمان خواستید می‌توانید نمایش آگهی را متوقف یا دوباره فعال کنید.', 'هر وخت کولای شئ اعلان ودروئ یا بېرته فعال یې کړئ.')),
                                  onChanged: ad['moderation_disabled'] == true
                                      ? null
                                      : (value) async {
                                          final previous = ad['is_active'] == true;
                                          setState(() => ad['is_active'] = value);
                                          try {
                                            final updated = await ApiService.setMyProductStatus(id: ad['id'].toString(), isActive: value);
                                            setState(() => ad.addAll(updated));
                                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? psText(context, 'آگهی فعال شد.', 'اعلان فعال شو.') : psText(context, 'آگهی غیرفعال شد.', 'اعلان غیر فعال شو.'))));
                                          } catch (e) {
                                            setState(() => ad['is_active'] = previous);
                                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyNetworkError(context, e))));
                                          }
                                        },
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _confirmDelete(ad),
                                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                                      icon: const Icon(Icons.delete_outline),
                                      label: Text(psText(context, 'حذف دائمی آگهی', 'د اعلان دایمي حذف')),
                                    ),
                                  ),
                                ),
                                if (badge.isNotEmpty)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      child: Chip(label: Text(badge), avatar: const Icon(Icons.auto_awesome, size: 18)),
                                    ),
                                  ),
                                if (_turboTimeText(ad).isNotEmpty)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                      child: Text(_turboTimeText(ad), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        await Navigator.push(context, MaterialPageRoute(builder: (_) => BoostScreen(listing: ad)));
                                        if (mounted) _load();
                                      },
                                      icon: const Icon(Icons.rocket_launch),
                                      label: Text(badge.isEmpty ? psText(context, '🚀 بوست آگهی', '🚀 اعلان Boost کړئ') : psText(context, '🚀 تقویت بوست', '🚀 Boost پیاوړی کړئ')),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _imageFor(dynamic ad) {
    try {
      final raw = ad['image_url'];
      final imgs = raw is String ? jsonDecode(raw) : raw;
      final u = imgs is List && imgs.isNotEmpty ? imgs.first.toString() : '';
      if (u.isNotEmpty) {
        return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_optimizedImageUrl(u), fit: BoxFit.cover, loadingBuilder: _bazarekImageLoading));
      }
    } catch (_) {}
    return const DecoratedBox(decoration: BoxDecoration(color: Colors.black12), child: Icon(Icons.image));
  }
}

class BoostScreen extends StatefulWidget {
  final dynamic listing;
  const BoostScreen({super.key, this.listing});
  @override State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  List<dynamic> packages = [];
  List<dynamic> subscriptions = [];
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final p = await ApiService.getBoostPackages();
      final s = await ApiService.getSubscriptions();
      if (mounted) setState(() { packages = p; subscriptions = s; loading = false; error = null; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = friendlyNetworkError(context, e); });
    }
  }

  Future<String?> _referenceDialog({required String title, required int price}) async {
    final c = TextEditingController();
    Map<String, dynamic> payment = {};
    try { payment = await ApiService.getPaymentInfo(); } catch (_) {}
    final bank = payment['bank'] is Map ? Map<String, dynamic>.from(payment['bank']) : <String, dynamic>{};
    final card = (payment['card_number'] ?? bank['card_number'] ?? payment['account_number'] ?? bank['account_number'] ?? '').toString();
    // شماره کارت را از هر فاصله/کاراکتر قالب‌بندی جدا می‌کنیم تا ترتیب منطقی اعداد
    // هنگام کپی در محیط‌های RTL تغییر نکند. مقدار Clipboard فقط رقم‌های واقعی است.
    final cardDigits = card
        .replaceAll('۰', '0').replaceAll('۱', '1').replaceAll('۲', '2').replaceAll('۳', '3').replaceAll('۴', '4')
        .replaceAll('۵', '5').replaceAll('۶', '6').replaceAll('۷', '7').replaceAll('۸', '8').replaceAll('۹', '9')
        .replaceAll('٠', '0').replaceAll('١', '1').replaceAll('٢', '2').replaceAll('٣', '3').replaceAll('٤', '4')
        .replaceAll('٥', '5').replaceAll('٦', '6').replaceAll('٧', '7').replaceAll('٨', '8').replaceAll('٩', '9')
        .replaceAll(RegExp(r'[^0-9]'), '');
    final bankName = (payment['bank_name'] ?? bank['name'] ?? '').toString();
    final accountName = (payment['account_name'] ?? bank['account_name'] ?? '').toString();
    final instructions = (payment['instructions'] ?? '').toString();
    final ps = Localizations.localeOf(context).languageCode == 'ps';
    return showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${tr(context, 'price')}: $price ${tr(context, 'afghani')}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).colorScheme.primaryContainer), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ps ? '💳 د پیسو لېږلو معلومات' : '💳 اطلاعات پرداخت', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              if (bankName.isNotEmpty) Text('${ps ? 'بانک' : 'بانک'}: $bankName'),
              if (accountName.isNotEmpty) Text('${ps ? 'د حساب نوم' : 'نام حساب'}: $accountName'),
              if (card.isNotEmpty) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Row(children: [
                  Expanded(child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: SelectableText(
                      card,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.6),
                    ),
                  )),
                  IconButton(
                    tooltip: ps ? 'کاپي' : 'کپی',
                    onPressed: cardDigits.isEmpty ? null : () async {
                      // عمداً فقط رقم‌ها کپی می‌شوند؛ هیچ فاصله یا کاراکتر RTL داخل Clipboard نمی‌رود.
                      await Clipboard.setData(ClipboardData(text: cardDigits));
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ps ? 'د کارت شمېره په سمه بڼه کاپي شوه.' : 'شماره کارت بدون فاصله و با ترتیب درست کپی شد.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 20),
                  ),
                ]),
              ),
              if (card.isEmpty) Text(ps ? 'د تادیې معلومات لا نه دي تنظیم شوي.' : 'اطلاعات کارت/حساب هنوز تنظیم نشده است.'),
              if (instructions.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(instructions)),
            ])),
            const SizedBox(height: 10),
            Text(ps ? '۱) پورته حساب/کارت ته دقیق مبلغ ولېږئ.\n۲) د انتقال رسید یا تعقیبي شمېره واخلئ.\n۳) هماغه شمېره لاندې ولیکئ.\n۴) مدیریت د پیسو له تایید وروسته Boost فعالوي.' : '۱) مبلغ دقیقاً به حساب/کارت بالا انتقال کنید.\n۲) رسید یا شماره پیگیری انتقال را بگیرید.\n۳) همان شماره را در کادر زیر وارد کنید.\n۴) بعد از تأیید پرداخت توسط مدیریت، Boost فعال می‌شود.'),
            const SizedBox(height: 12),
            TextField(controller: c, onChanged: (_) => setDialogState(() {}), decoration: InputDecoration(labelText: ps ? 'د رسید / تعقیب شمېره' : 'شماره پیگیری / رسید', border: const OutlineInputBorder())),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(ps ? 'لغوه' : 'لغو')),
            FilledButton(onPressed: c.text.trim().isEmpty ? null : () => Navigator.pop(dialogContext, c.text.trim()), child: Text(ps ? 'ثبت غوښتنه' : 'ثبت درخواست')),
          ],
        ),
      ),
    );
  }

  Future<void> _buyOne(dynamic pkg) async {
    final id = widget.listing?['id']?.toString();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'ps' ? 'لومړی له «زما اعلانونه» څخه یو اعلان وټاکئ.' : 'برای بوست کوتاه‌مدت ابتدا یک آگهی را از «آگهی‌های من» انتخاب کنید.')));
      return;
    }
    final ref = await _referenceDialog(title: pkg['title']?.toString() ?? 'بوست آگهی', price: int.tryParse('${pkg['price_afn']}') ?? 0);
    if (ref == null) return;
    try {
      await ApiService.createBoostOrder(id, pkg['id'].toString(), ref);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'ps' ? 'د Boost غوښتنه ثبت شوه؛ د تادیې له تایید وروسته فعاله کېږي.' : 'درخواست بوست ثبت شد؛ پس از تأیید پرداخت فعال می‌شود.'))); Navigator.pop(context, true); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyNetworkError(context, e)))); }
  }

  Future<void> _buyGlobal(String plan, int price, String title) async {
    final ref = await _referenceDialog(title: title, price: price);
    if (ref == null) return;
    try {
      await ApiService.createGlobalBoost(plan, ref);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'ps' ? 'ستاسو غوښتنه ثبت شوه؛ د تایید وروسته ستاسو ټول فعال اعلانونه Boost کېږي.' : 'درخواست ثبت شد؛ پس از تأیید پرداخت، روی همه آگهی‌های فعال شما اعمال می‌شود.'))); _load(); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyNetworkError(context, e)))); }
  }

  String _dateTimeForUser(dynamic value) {
    final dt = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}/${two(dt.month)}/${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _boostPlanTitle(BuildContext context, String plan) {
    final ps = Localizations.localeOf(context).languageCode == 'ps';
    switch (plan) {
      case 'boost_weekly': return ps ? '⚡ توربو اوونیز' : '⚡ توربو هفتگی';
      case 'boost_monthly': return ps ? '👑 توربو میاشتنی' : '👑 توربو ماهانه';
      case 'boost_yearly': return ps ? '🏆 توربو کلنی' : '🏆 توربو سالانه';
      default: return ps ? '⚡ توربو' : '⚡ توربو';
    }
  }

  Widget _globalBoostPlanCard(BuildContext context, bool ps, String plan, String title, String desc, int price) {
    final active = subscriptions.any((s) => s['plan'] == plan && s['status'] == 'active' && DateTime.tryParse('${s['ends_at']}')?.isAfter(DateTime.now()) == true);
    final pending = subscriptions.any((s) => s['plan'] == plan && s['status'] == 'pending');
    return Card(child: ListTile(
      leading: Text(plan == 'boost_weekly' ? '⚡' : plan == 'boost_monthly' ? '👑' : '🏆', style: const TextStyle(fontSize: 30)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(desc),
      trailing: active ? Chip(label: Text(ps ? 'فعال' : 'فعال')) : pending ? Chip(label: Text(ps ? 'د تایید په تمه' : 'در انتظار تأیید')) : FilledButton(onPressed: () => _buyGlobal(plan, price, title), child: Text('$price ${tr(context,'afghani')}')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ps = Localizations.localeOf(context).languageCode == 'ps';
    final globalActive = subscriptions.any((s) => ['boost_weekly','boost_monthly','boost_yearly'].contains(s['plan']) && s['status'] == 'active' && DateTime.tryParse('${s['ends_at']}')?.isAfter(DateTime.now()) == true);

    return Scaffold(
      appBar: AppBar(title: Text(ps ? '🚀 د بازارک Boost' : '🚀 Boost بازارک')),
      body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? OfflineErrorView(onRetry: _load, message: error) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ps ? '🚀 خپل اعلان له نورو مخکې کړئ!' : '🚀 آگهی‌ات را از بقیه جلو بزن!', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(ps ? 'هر څومره Boost لوړ وي، اعلان مو په لوړه درجه کې ښکاري او ځانګړی نښان اخلي.' : 'هرچه سطح Boost بالاتر باشد، آگهی در جایگاه بالاتری نمایش داده می‌شود و برچسپ مخصوص خودش را می‌گیرد.'),
          ])),
          const SizedBox(height: 22),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)), child: Text(ps ? '💳 د تادیې طریقه: د Boost د انتخاب پر مهال به د بازارک د کارت/حساب معلومات درښکاره شي. مبلغ ولېږئ، د رسید شمېره ولیکئ، او د مدیریت تایید ته انتظار وباسئ.' : '💳 روش پرداخت: هنگام انتخاب Boost، شماره کارت/حساب بازارک نمایش داده می‌شود. مبلغ را انتقال دهید، شماره رسید را وارد کنید و منتظر تأیید مدیریت بمانید.')),
          const SizedBox(height: 18),
          Text(ps ? '⚡ د بازارک توربو پلانونه' : '⚡ پلان‌های توربو بازارک', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(ps ? 'یو پلان واخلئ؛ ستاسو ټول فعال اعلانونه د تایید وروسته سمدستي توربو کېږي او د پلان تر ختمېدو پورې نښان لري.' : 'یک پلان بخرید؛ بعد از تأیید مدیریت، تمام آگهی‌های فعال شما توربو می‌شوند و تا پایان مدت نشان توربو را دارند.', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          if (globalActive)
            Builder(builder: (context) {
              final active = subscriptions.where((s) => ['boost_weekly','boost_monthly','boost_yearly'].contains(s['plan']) && s['status'] == 'active' && DateTime.tryParse('${s['ends_at']}')?.isAfter(DateTime.now()) == true).toList()..sort((a,b) => DateTime.tryParse('${b['ends_at']}')!.compareTo(DateTime.tryParse('${a['ends_at']}')!));
              final s = active.isEmpty ? null : active.first;
              final start = s == null ? '' : _dateTimeForUser(s['starts_at']);
              final end = s == null ? '' : _dateTimeForUser(s['ends_at']);
              final planTitle = s == null ? '' : _boostPlanTitle(context, s['plan']?.toString() ?? '');
              return Card(color: Theme.of(context).colorScheme.primaryContainer, child: ListTile(leading: const Text('⚡', style: TextStyle(fontSize: 28)), title: Text(planTitle.isEmpty ? (ps ? 'توربو فعال' : 'توربو فعال') : planTitle, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(start.isEmpty ? end : '$start\n$end'), trailing: Chip(label: Text(ps ? 'فعال' : 'فعال'))));
            }),
          _globalBoostPlanCard(context, ps, 'boost_weekly', ps ? '⚡ اوونیز — ټول اعلانونه' : '⚡ هفتگی — همه آگهی‌ها', tr(context,'boost_week_desc'), 150),
          _globalBoostPlanCard(context, ps, 'boost_monthly', ps ? '👑 میاشتنی — ټول اعلانونه' : '👑 ماهانه — همه آگهی‌ها', tr(context,'boost_month_desc'), 500),
          _globalBoostPlanCard(context, ps, 'boost_yearly', ps ? '🏆 کلنی — ټول اعلانونه' : '🏆 سالانه — همه آگهی‌ها', tr(context,'boost_year_desc'), 4500),
          const SizedBox(height: 8),
          Text(ps ? '💡 هر درې پلانونه د تایید وروسته ستاسو پر ټولو فعالو اعلانونو اغېز کوي. د تایید وخت د توربو د پیل وخت دی؛ له ختمېدو وروسته په اوتومات ډول غیر فعال کېږي.' : '💡 هر سه پلان بعد از تأیید روی تمام آگهی‌های فعال شما اثر می‌گذارد. زمان تأیید مدیریت همان زمان شروع توربو است؛ پس از پایان، توربو خودکار غیرفعال می‌شود.', style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1000 ? 5 : width >= 700 ? 4 : 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(psText(context, 'همه دسته‌بندی‌ها', 'ټولې کټګورۍ')),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final id = category['id']?.toString() ?? '';
          final title = localizedCategoryTitle(
            context,
            id,
            category['title']?.toString() ?? 'دسته‌بندی',
          );
          final icon = category['icon'] is IconData
              ? category['icon'] as IconData
              : Icons.category;

          return Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubcategoryScreen(category: category),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Icon(
                        icon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SubcategoryScreen extends StatelessWidget {
  final Map<String, dynamic> category;
  const SubcategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final categoryId = category['id']?.toString() ?? '';
    final categoryTitle = localizedCategoryTitle(context, categoryId, category['title']?.toString() ?? 'دسته‌بندی');
    final categoryIcon = category['icon'] is IconData ? category['icon'] as IconData : Icons.category;
    final list = subcategories[categoryId] ?? [];

    if (list.isEmpty) {
      return CategoryListingsScreen(categoryId: categoryId, categoryTitle: categoryTitle);
    }

    return Scaffold(
      appBar: AppBar(title: Text(categoryTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = list[i];
          final subcategoryId = c['id']?.toString() ?? '';
          final subcategoryTitle = localizedSubcategoryTitle(context, categoryId, c['id']?.toString() ?? '', c['title']?.toString() ?? '');
          return ListTile(
            leading: CircleAvatar(child: Icon(categoryIcon)),
            title: Text(subcategoryTitle),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryListingsScreen(categoryId: categoryId, subcategoryId: subcategoryId, categoryTitle: subcategoryTitle))),
          );
        },
      ),
    );
  }
}

class CategoryListingsScreen extends StatefulWidget {
  final String categoryId;
  final String? subcategoryId;
  final String categoryTitle;
  const CategoryListingsScreen({super.key, required this.categoryId, this.subcategoryId, required this.categoryTitle});
  @override
  State<CategoryListingsScreen> createState() => _CategoryListingsScreenState();
}

class _CategoryListingsScreenState extends State<CategoryListingsScreen> {
  List<dynamic> ads = [];
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await ApiService.getProducts(category: widget.categoryId, subcategory: widget.subcategoryId);
      if (mounted) setState(() { ads = d; loading = false; error = null; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = friendlyNetworkError(context, e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryTitle), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? OfflineErrorView(onRetry: _load, message: error)
              : ads.isEmpty
                  ? Center(child: Text(Localizations.localeOf(context).languageCode == 'ps' ? 'په «${widget.categoryTitle}» کې تر اوسه فعال اعلان نشته.' : 'در «${widget.categoryTitle}» هنوز آگهی فعالی پیدا نشد.'))
                  : RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: ads.length, itemBuilder: (_, i) => _ProductCard(item: ads[i]))),
    );
  }
}

class PickedProfileImage {
  final Uint8List bytes;
  final String name;
  final String? mimeType;
  const PickedProfileImage({required this.bytes, required this.name, this.mimeType});
}

Future<PickedProfileImage?> pickProfileImage() async {
  // Web: use file_picker so we receive the real bytes directly instead of
  // image_picker's temporary browser Blob URL. This fixes the Web-only
  // "Could not load Blob from its URL" error.
  if (kIsWeb) {
    final file = await FilePicker.pickFile(
      type: FileType.image,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('خواندن تصویر انتخاب‌شده در مرورگر ممکن نشد. لطفاً دوباره انتخاب کنید.');
    }
    return PickedProfileImage(bytes: bytes, name: file.name);
  }

  // Android/iOS: keep the existing image_picker flow unchanged.
  final picker = ImagePicker();
  final image = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 1000,
  );
  if (image == null) return null;
  return PickedProfileImage(
    bytes: await image.readAsBytes(),
    name: image.name.isNotEmpty ? image.name : 'avatar.jpg',
    mimeType: image.mimeType,
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;
  bool saving = false;
  String? error;
  Map<String, dynamic> profile = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!AuthService.isLoggedIn) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final data = await ApiService.getMyProfile();
      // Calculate statistics from the same authenticated /products endpoint
      // used by «آگهی‌های من». This keeps the counters correct even when the
      // deployed backend's /api/me response does not yet include statistics.
      try {
        final myProducts = await ApiService.getMyProducts();
        final activeCount = myProducts.where((item) {
          final m = item is Map ? item : const <String, dynamic>{};
          final value = m['is_active'];
          return value == true || value.toString().toLowerCase() == 'true' || value.toString() == '1';
        }).length;
        final totalViews = myProducts.fold<int>(0, (sum, item) {
          final m = item is Map ? item : const <String, dynamic>{};
          return sum + (int.tryParse('${m['views_count'] ?? 0}') ?? 0);
        });
        data['total_ads'] = myProducts.length;
        data['active_ads'] = activeCount;
        data['total_views'] = totalViews;
      } catch (_) {
        // Keep server-provided counters as a fallback.
      }
      final avatar = data['avatar_url']?.toString() ?? '';
      if (avatar.isNotEmpty) {
        AuthService.avatarUrl = avatar;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('avatar_url', avatar);
      }
      final name = data['full_name']?.toString().trim() ?? '';
      final phone = data['phone']?.toString().trim() ?? '';
      if (name.isNotEmpty) AuthService.userName = name;
      if (phone.isNotEmpty) AuthService.userContact = phone;
      if (mounted) setState(() { profile = data; loading = false; error = null; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = friendlyNetworkError(context, e); });
    }
  }

  Future<void> _changeAvatar() async {
    final image = await pickProfileImage();
    if (image == null) return;
    setState(() => saving = true);
    try {
      await ApiService.uploadAvatar(image);
      await _loadProfile();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عکس پروفایل با موفقیت تغییر کرد.')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyNetworkError(context, e))),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _editProfile() async {
    final name = TextEditingController(text: profile['full_name']?.toString() ?? AuthService.userName ?? '');
    final phone = TextEditingController(text: profile['phone']?.toString() ?? '');
    final city = TextEditingController(text: profile['city']?.toString() ?? '');
    final shop = TextEditingController(text: profile['shop_name']?.toString() ?? '');
    final bio = TextEditingController(text: profile['bio']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ویرایش پروفایل'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: name, decoration: const InputDecoration(labelText: 'نام کامل'), validator: (v) => v == null || v.trim().isEmpty ? 'نام کامل را وارد کنید.' : null),
                  const SizedBox(height: 10),
                  TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'شماره تلفن'), keyboardType: TextInputType.phone),
                  const SizedBox(height: 10),
                  TextFormField(controller: city, decoration: const InputDecoration(labelText: 'شهر / ولایت')),
                  const SizedBox(height: 10),
                  TextFormField(controller: shop, decoration: const InputDecoration(labelText: 'نام فروشگاه')),
                  const SizedBox(height: 10),
                  TextFormField(controller: bio, maxLines: 3, maxLength: 500, decoration: const InputDecoration(labelText: 'درباره من', alignLabelWithHint: true)),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('انصراف')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('ذخیره')),
        ],
      ),
    );
    if (result == true) {
      setState(() => saving = true);
      try {
        profile = await ApiService.updateMyProfile(fullName: name.text, phone: phone.text, city: city.text, shopName: shop.text, bio: bio.text);
        if (mounted) setState(() {});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پروفایل با موفقیت ذخیره شد.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyNetworkError(context, e))));
      } finally {
        if (mounted) setState(() => saving = false);
      }
    }
    name.dispose(); phone.dispose(); city.dispose(); shop.dispose(); bio.dispose();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف همیشگی حساب'),
        content: const Text(
          'با حذف حساب، پروفایل، آگهی‌ها و اطلاعات مرتبط با حساب شما برای همیشه حذف می‌شود و این کار قابل بازگردانی نیست.\n\nآیا مطمئن هستید که می‌خواهید حساب خود را برای همیشه حذف کنید؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('انصراف')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('بله، حسابم را برای همیشه حذف کن'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => saving = true);
    try {
      await ApiService.deleteMyAccount();
      await AuthService.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حساب شما برای همیشه حذف شد.')));
        setState(() { profile = {}; error = null; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyNetworkError(context, e))));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _infoTile(IconData icon, String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(context, 'profile'))),
        body: Center(child: FilledButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())); if (mounted) setState(() {}); }, icon: const Icon(Icons.login), label: Text(tr(context, 'login')))),
      );
    }

    final name = profile['full_name']?.toString().trim().isNotEmpty == true ? profile['full_name'].toString() : (AuthService.userName ?? 'کاربر بازارک');
    final city = profile['city']?.toString() ?? '';
    final bio = profile['bio']?.toString() ?? '';
    final shop = profile['shop_name']?.toString() ?? '';
    final phone = profile['phone']?.toString() ?? '';
    final avatar = AuthService.avatarUrl ?? profile['avatar_url']?.toString() ?? '';
    final activeAds = int.tryParse('${profile['active_ads'] ?? 0}') ?? 0;
    final totalAds = int.tryParse('${profile['total_ads'] ?? 0}') ?? 0;
    final views = int.tryParse('${profile['total_views'] ?? 0}') ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حساب من'),
        actions: [IconButton(onPressed: loading || saving ? null : _editProfile, icon: const Icon(Icons.edit_outlined), tooltip: 'ویرایش پروفایل')],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 54,
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                              child: avatar.isEmpty ? Icon(Icons.person, size: 54, color: Theme.of(context).colorScheme.primary) : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Material(
                                color: Theme.of(context).colorScheme.primary,
                                shape: const CircleBorder(),
                                child: IconButton(onPressed: saving ? null : _changeAvatar, icon: const Icon(Icons.camera_alt_outlined, color: Colors.white), tooltip: 'تغییر عکس'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        if (city.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('📍 $city', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(bio, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 14),
                        FilledButton.icon(onPressed: saving ? null : _editProfile, icon: const Icon(Icons.edit_outlined), label: const Text('ویرایش پروفایل')),
                      ],
                    ),
                  ),
                  if (error != null) Padding(padding: const EdgeInsets.all(12), child: Text(error!, style: const TextStyle(color: Colors.red))),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(child: _statCard('آگهی‌ها', '$totalAds', Icons.inventory_2_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProductsScreen())))),
                        const SizedBox(width: 8),
                        Expanded(child: _statCard('فعال', '$activeAds', Icons.check_circle_outline, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProductsScreen(activeOnly: true))))),
                        const SizedBox(width: 8),
                        Expanded(child: _statCard('بازدید', '$views', Icons.visibility_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProductsScreen(sortByViews: true))))),
                      ],
                    ),
                  ),
                  if (shop.isNotEmpty || phone.isNotEmpty || city.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Column(children: [
                        const ListTile(title: Text('اطلاعات پروفایل', style: TextStyle(fontWeight: FontWeight.bold)), leading: Icon(Icons.person_outline)),
                        _infoTile(Icons.store_outlined, 'فروشگاه', shop),
                        _infoTile(Icons.phone_outlined, 'شماره تلفن', phone),
                        _infoTile(Icons.location_on_outlined, 'شهر / ولایت', city),
                      ]),
                    ),
                  ListTile(leading: const Icon(Icons.notifications_outlined), title: const Text('اعلان‌ها'), subtitle: const Text('پیام‌های سیستم و نتیجه رسیدگی به گزارش‌ها'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                  ListTile(leading: const Icon(Icons.support_agent_outlined), title: const Text('پشتیبانی و ارتباط با ما'), subtitle: const Text('گزارش اشکال، پیشنهاد و پیام به تیم بازارک'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
                  ListTile(leading: const Icon(Icons.admin_panel_settings_outlined), title: const Text('ورود مدیریت بازارک'), subtitle: const Text('پنل مدیریت، بررسی آگهی‌ها و گزارش‌ها'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()))),
                  ListTile(leading: const Icon(Icons.rocket_launch), title: Text('🚀 ${tr(context, 'boost')}'), subtitle: const Text('افزایش نمایش آگهی و اشتراک ویژه'), onTap: () async { if (!await requireAccount(context)) return; if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const BoostScreen())); }),
                  ListTile(leading: const Icon(Icons.download_for_offline_outlined), title: Text(tr(context, 'download_app')), subtitle: Text(tr(context, 'download_app_desc')), onTap: () async { const apkUrl = 'https://bazarek-web.onrender.com/download/bazarek.apk'; try { final opened = await launchUrl(Uri.parse(apkUrl), mode: LaunchMode.externalApplication); if (!opened && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('باز کردن لینک دانلود ممکن نشد.'))); } catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('باز کردن لینک دانلود ممکن نشد.'))); } }),
                  const Divider(),
                  SwitchListTile(value: Theme.of(context).brightness == Brightness.dark, onChanged: (_) => BazarBuzurgApp.toggleTheme(context), title: Text(tr(context, 'dark_mode')), secondary: const Icon(Icons.dark_mode)),
                  ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('خروج از حساب', style: TextStyle(color: Colors.red)), onTap: saving ? null : () async { await AuthService.logout(); if (mounted) setState(() {}); }),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                    title: const Text('حذف همیشگی حساب', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    subtitle: const Text('پروفایل و اطلاعات حساب برای همیشه حذف می‌شود'),
                    onTap: saving ? null : _deleteAccount,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Icon(icon, size: 24),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 3),
            const Icon(Icons.touch_app_outlined, size: 14),
          ]),
        ),
      ),
    );
  }
}


class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool loading = true;
  bool sending = false;
  String? error;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ApiService.getSupportRequests();
      if (!mounted) return;
      setState(() {
        items = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = friendlyNetworkError(context, e); });
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'bug': return psText(context, '🐞 گزارش اشکال', '🐞 د ستونزې راپور');
      case 'suggestion': return psText(context, '💡 پیشنهاد', '💡 وړاندیز');
      case 'report': return psText(context, '📢 گزارش آگهی یا کاربر', '📢 د اعلان یا کارونکي راپور');
      default: return psText(context, '💬 پیام به پشتیبانی', '💬 ملاتړ ته پیغام');
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress': return psText(context, 'در حال بررسی', 'د کتنې په حال کې');
      case 'answered': return psText(context, 'پاسخ داده شد', 'ځواب ورکړل شو');
      case 'resolved': return psText(context, 'حل شد', 'حل شو');
      default: return psText(context, 'جدید', 'نوی');
    }
  }

  Future<void> _newRequest() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    String type = 'support';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(psText(context, 'ارتباط با تیم بازارک', 'له د بازارک ټیم سره اړیکه')),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: type,
              decoration: InputDecoration(
                labelText: psText(context, 'موضوع', 'موضوع'),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'support', child: Text(psText(context, '💬 پیام به پشتیبانی', '💬 ملاتړ ته پیغام'))),
                DropdownMenuItem(value: 'bug', child: Text(psText(context, '🐞 گزارش اشکال', '🐞 د ستونزې راپور'))),
                DropdownMenuItem(value: 'suggestion', child: Text(psText(context, '💡 پیشنهاد برای بهتر شدن بازارک', '💡 د بازارک د ښه کېدو وړاندیز'))),
                DropdownMenuItem(value: 'report', child: Text(psText(context, '📢 گزارش آگهی یا کاربر', '📢 د اعلان یا کارونکي راپور'))),
              ],
              onChanged: (v) => setDialogState(() => type = v ?? 'support'),
            ),
            const SizedBox(height: 12),
            TextField(controller: subject, maxLength: 120, decoration: InputDecoration(labelText: psText(context, 'عنوان', 'سرلیک'), border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: message, minLines: 4, maxLines: 8, maxLength: 3000, decoration: InputDecoration(labelText: psText(context, 'توضیح', 'تشریح'), hintText: psText(context, 'مشکل یا پیشنهاد خود را بنویسید...', 'خپله ستونزه یا وړاندیز ولیکئ...'), border: const OutlineInputBorder())),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(psText(context, 'انصراف', 'لغوه'))),
            FilledButton(
              onPressed: sending ? null : () async {
                if (subject.text.trim().isEmpty || message.text.trim().isEmpty) return;
                setDialogState(() {});
                setState(() => sending = true);
                try {
                  await ApiService.createSupportRequest(type: type, subject: subject.text.trim(), message: message.text.trim());
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (e) {
                  if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(friendlyNetworkError(dialogContext, e))));
                } finally {
                  if (mounted) setState(() => sending = false);
                }
              },
              child: Text(sending ? psText(context, 'در حال ارسال...', 'د لېږلو په حال کې...') : psText(context, 'ارسال', 'لېږل')),
            ),
          ],
        ),
      ),
    );
    subject.dispose();
    message.dispose();
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(psText(context, 'درخواست شما ثبت شد.', 'ستاسو غوښتنه ثبت شوه.'))));
      _load();
    }
  }

  void _showRequest(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text((item['title'] ?? item['subject'])?.toString() ?? '-'),
        content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_typeLabel(item['type']?.toString() ?? 'support'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${psText(context, 'وضعیت', 'حالت')}: ${_statusLabel(item['status']?.toString() ?? 'new')}'),
          const Divider(height: 24),
          Text(item['message']?.toString() ?? '-'),
          if ((item['admin_reply']?.toString() ?? '').trim().isNotEmpty) ...[
            const Divider(height: 24),
            Text(psText(context, 'پاسخ پشتیبانی', 'د ملاتړ ځواب'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(item['admin_reply'].toString()),
          ],
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(psText(context, 'بستن', 'تړل')))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(psText(context, 'پشتیبانی و ارتباط با ما', 'ملاتړ او له موږ سره اړیکه')),
      actions: [IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _newRequest,
      icon: const Icon(Icons.add_comment_outlined),
      label: Text(psText(context, 'درخواست جدید', 'نوې غوښتنه')),
    ),
    body: loading
      ? const Center(child: CircularProgressIndicator())
      : error != null
        ? OfflineErrorView(onRetry: _load, message: error)
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              children: [
                Card(child: ListTile(
                  leading: const Icon(Icons.support_agent, size: 38),
                  title: Text(psText(context, 'پشتیبانی بازارک', 'د بازارک ملاتړ'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(psText(context, 'اگر مشکل یا پیشنهادی دارید، از همین‌جا برای تیم بازارک بفرستید.', 'که ستونزه یا وړاندیز لرئ، له همدې ځایه یې د بازارک ټیم ته ولېږئ.')),
                )),
                if (items.isEmpty)
                  Card(child: ListTile(leading: const Icon(Icons.inbox_outlined), title: Text(psText(context, 'هنوز درخواستی ندارید.', 'تر اوسه کومه غوښتنه نه لرئ.'))))
                else
                  ...items.map((item) => Card(child: ListTile(
                    onTap: () => _showRequest(item),
                    leading: const Icon(Icons.forum_outlined),
                    title: Text((item['title'] ?? item['subject'])?.toString() ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${_typeLabel(item['type']?.toString() ?? 'support')}\n${_statusLabel(item['status']?.toString() ?? 'new')}${(item['admin_reply']?.toString() ?? '').trim().isNotEmpty ? ' • ${psText(context, 'پاسخ دارد', 'ځواب لري')}' : ''}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_left),
                  ))),
              ],
            ),
          ),
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool loading = true; String? error; List<Map<String,dynamic>> items = [];
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    try {
      final data = await ApiService.getNotifications();
      if(!mounted)return; setState((){items=data.map((e)=>Map<String,dynamic>.from(e as Map)).toList();loading=false;});
    }catch(e){if(!mounted)return;setState((){loading=false;error=friendlyNetworkError(context, e);});}
  }
  Future<void> _read(Map<String,dynamic> n) async {
    if(n['is_read']==true)return;
    try{await ApiService.markNotificationRead(n['id'].toString());if(mounted)setState(()=>n['is_read']=true);}catch(_){}
  }
  Future<void> _delete(Map<String,dynamic> n) async {
    try{await ApiService.deleteNotification(n['id'].toString());if(mounted)setState(()=>items.remove(n));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyNetworkError(context, e))));}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(psText(context,'اعلان‌ها','خبرتیاوې')),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator()):error!=null?OfflineErrorView(onRetry:_load,message:error):RefreshIndicator(onRefresh:_load,child:items.isEmpty?ListView(children:[const SizedBox(height:160),Center(child:Text('اعلانی وجود ندارد.'))]):ListView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(context,i){final n=items[i];final unread=n['is_read']!=true;return Card(child:ListTile(onTap:()=>_read(n), leading:Icon(unread?Icons.notifications_active:Icons.notifications_none), title:Text(n['title']?.toString()??'اعلان بازارک',style:TextStyle(fontWeight:unread?FontWeight.bold:FontWeight.normal)), subtitle:Text('${n['message']??''}\n${n['created_at']??''}'),isThreeLine:true,trailing:IconButton(onPressed:()=>_delete(n),icon:const Icon(Icons.delete_outline))));})));
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isSignUp = false;
  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  bool _isValidEmailOrPhone(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegex = RegExp(r'^\+?[0-9]{9,13}$');
    return emailRegex.hasMatch(value) || phoneRegex.hasMatch(value);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final contact = contactController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    setState(() => isLoading = true);

    Map<String, dynamic> response;
    if (isSignUp) {
      response = await ApiService.register(name, contact, password);
    } else {
      response = await ApiService.login(contact, password);
    }

    setState(() => isLoading = false);

    if (response['token'] != null) {
      final user = response['user'] ?? {};
      await AuthService.saveUser(
        response['token'],
        user['name'] ?? name,
        user['email'] ?? user['user_metadata']?['phone'] ?? contact,
        refreshTokenVal: response['refresh_token'],
        userIdVal: user['id']?.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSignUp ? 'ثبت‌نام با موفقیت انجام شد' : 'با موفقیت وارد شدید'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'خطا در ثبت یا ورود'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSignUp ? tr(context, 'signup') : tr(context, 'login')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                if (isSignUp) ...[
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: tr(context, 'full_name'),
                      prefixIcon: const Icon(Icons.person),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 2) {
                        return 'لطفاً نام کامل خود را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: contactController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: tr(context, 'phone_or_email'),
                    prefixIcon: const Icon(Icons.phone_android),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'لطفاً ایمیل یا شماره تلفن خود را وارد کنید';
                    }
                    if (!_isValidEmailOrPhone(val.trim())) {
                      return 'فرمت ایمیل (مثل name@gmail.com) یا شماره تلفن معتبر نیست';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr(context, 'password'),
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 6) {
                      return 'رمز عبور باید حداقل ۶ کاراکتر باشد';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isSignUp ? tr(context, 'signup') : tr(context, 'login'),
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() => isSignUp = !isSignUp);
                  },
                  child: Text(
                    isSignUp ? tr(context, 'have_account') : tr(context, 'no_account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddProductSheet extends StatefulWidget {
  const AddProductSheet({super.key});

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final title = TextEditingController();
  final price = TextEditingController();
  final stock = TextEditingController(text: '1');
  final desc = TextEditingController();
  final contactPhone = TextEditingController();
  final locationText = TextEditingController();
  final socialLink = TextEditingController();

  String category = '';
  String subcategory = '';
  String province = '';
  bool allowChat = true;
  bool showPhone = true;
  bool isNegotiable = false;
  String currency = 'AFN';
  bool uploading = false;

  List<Uint8List> imageBytes = [];
  List<String> imageNames = [];
  List<String> imageUrls = [];
  bool publishing = false;

  final ImagePicker _picker = ImagePicker();

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _pickImage() async {
    if (imageBytes.length >= 20) { _msg('حداکثر ۲۰ عکس مجاز است.'); return; }

    // Web: use file_picker so the browser gives us the actual bytes.
    // This avoids image_picker Blob URLs, which can fail after selection.
    if (kIsWeb) {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (result.isEmpty) return;
      final remaining = 20 - imageBytes.length;
      for (final file in result.take(remaining)) {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) continue;
        imageBytes.add(bytes);
        imageNames.add(file.name.isNotEmpty ? file.name : 'image.jpg');
      }
      if (mounted) setState(() {});
      return;
    }

    // Android/iOS: keep the existing image_picker flow unchanged.
    final picked = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (picked.isEmpty) return;
    final remaining = 20 - imageBytes.length;
    for (final image in picked.take(remaining)) {
      imageBytes.add(await image.readAsBytes());
      imageNames.add(image.name);
    }
    if (mounted) setState(() {});
  }
  Future<void> _uploadImages() async {
    if (imageBytes.isEmpty) throw Exception('حداقل یک عکس انتخاب کنید.');
    imageUrls.clear();
    for (var start = 0; start < imageBytes.length; start += 3) {
      final end = (start + 3 > imageBytes.length) ? imageBytes.length : start + 3;
      var success = false;
      Object? lastError;
      for (var attempt = 1; attempt <= 3 && !success; attempt++) {
        try {
          final req = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/upload-images'));
          req.headers['Accept'] = 'application/json';
          if (AuthService.token != null) req.headers['Authorization'] = 'Bearer ${AuthService.token}';
          for (var i = start; i < end; i++) {
            req.files.add(http.MultipartFile.fromBytes('images', imageBytes[i], filename: imageNames[i]));
          }
          var response = await req.send().timeout(const Duration(seconds: 90));
          var body = await response.stream.bytesToString();
          if (response.statusCode == 401 && await ApiService.refreshSession()) {
            final retry = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/upload-images'));
            retry.headers['Accept'] = 'application/json';
            retry.headers['Authorization'] = 'Bearer ${AuthService.token}';
            for (var i = start; i < end; i++) {
              retry.files.add(http.MultipartFile.fromBytes('images', imageBytes[i], filename: imageNames[i]));
            }
            response = await retry.send().timeout(const Duration(seconds: 90));
            body = await response.stream.bytesToString();
          }
          final data = jsonDecode(body);
          if (response.statusCode == 401) {
            throw Exception('نشست شما معتبر نیست. لطفاً دوباره وارد حساب شوید.');
          }
          if (response.statusCode != 201) throw Exception(data['error'] ?? 'خطا در آپلود عکس‌ها.');
          imageUrls.addAll(List<String>.from(data['urls'] ?? []));
          success = true;
        } catch (e) {
          lastError = e;
          if (attempt < 3) await Future.delayed(Duration(seconds: attempt));
        }
      }
      if (!success) throw Exception(lastError?.toString() ?? 'آپلود عکس‌ها ناموفق بود.');
    }
  }

  Future<bool> _ensureAuthenticated() async {
    if (AuthService.isLoggedIn) {
      // اگر access token فعلی معتبر نیست، refresh token را امتحان می‌کنیم.
      // در صورت نبود refresh token، ورود مجدد لازم است.
      return true;
    }

    if (!mounted) return false;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (AuthService.isLoggedIn) {
      return true;
    }
    return false;
  }

  Future<bool> _refreshIfPossible() async {
    if (!AuthService.isLoggedIn) return false;
    // فقط زمانی که refresh token داریم می‌توانیم نشست را تمدید کنیم.
    if (AuthService.refreshToken == null || AuthService.refreshToken!.isEmpty) {
      return true;
    }
    return true;
  }

  Future<void> _publish() async {
    if (publishing) return;
    if (title.text.trim().isEmpty) { _msg('عنوان آگهی را وارد کنید.'); return; }
    if (category.isEmpty) { _msg('دسته‌بندی را انتخاب کنید.'); return; }
    if (subcategory.isEmpty && (subcategories[category]?.isNotEmpty ?? false)) { _msg('زیر‌دسته را انتخاب کنید.'); return; }
    if (province.isEmpty) { _msg('ولایت آگهی را انتخاب کنید.'); return; }
    if (imageBytes.isEmpty) { _msg('حداقل یک عکس برای آگهی انتخاب کنید.'); return; }

    // انتشار و آپلود عکس‌ها نیاز به حساب کاربری دارد. اگر وارد نشده،
    // ابتدا صفحه ورود را باز می‌کنیم و پس از ورود ادامه می‌دهیم.
    if (!await _ensureAuthenticated()) {
      if (mounted) _msg('برای انتشار آگهی ابتدا وارد حساب خود شوید.');
      return;
    }

    setState(() => publishing = true);
    try {
      await _uploadImages();
      if (imageUrls.isEmpty) throw Exception('عکس‌ها آپلود نشدند.');
      final payload = jsonEncode({
        'title': title.text.trim(), 'category': category, 'subcategory': subcategory,
        'price': double.tryParse(price.text.replaceAll(',', '')) ?? 0,
        'cost_price': 0, 'stock': int.tryParse(stock.text) ?? 1,
        'description': desc.text.trim(), 'image_url': jsonEncode(imageUrls),
        'allow_chat': allowChat, 'show_phone': showPhone, 'contact_phone': contactPhone.text.trim(),
        'location_text': locationText.text.trim(), 'province': province, 'is_negotiable': isNegotiable, 'currency': currency, 'external_link': socialLink.text.trim(),
      });
      var response = await http.post(Uri.parse('${ApiConfig.baseUrl}/products'), headers: {
        'Content-Type':'application/json',
        if (AuthService.token != null) 'Authorization':'Bearer ${AuthService.token}',
      }, body: payload).timeout(const Duration(seconds: 30));
      if (response.statusCode == 401 && await ApiService.refreshSession()) {
        response = await http.post(Uri.parse('${ApiConfig.baseUrl}/products'), headers: {
          'Content-Type':'application/json', 'Authorization':'Bearer ${AuthService.token}',
        }, body: payload).timeout(const Duration(seconds: 30));
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 401) {
        throw Exception('نشست شما معتبر نیست. لطفاً دوباره وارد حساب شوید و دوباره انتشار را بزنید.');
      }
      if (response.statusCode != 201) throw Exception(data['error'] ?? tr(context, 'publish_error'));
      if (!mounted) return;
      _msg(tr(context, 'publish_success'));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _msg(friendlyNetworkError(context, e));
    } finally { if (mounted) setState(() => publishing = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: title,
            decoration: InputDecoration(labelText: psText(context, 'عنوان آگهی', 'د اعلان سرلیک')),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: category.isEmpty ? null : category,
            hint: Text(psText(context, 'انتخاب دسته‌بندی', 'کټګوري وټاکئ')),
            items: categories.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(localizedCategoryTitle(context, c['id'] as String, c['title'] as String)))).toList(),
            onChanged: (val) => setState(() { category = val ?? ''; subcategory = ''; }),
          ),
          if ((subcategories[category] ?? []).isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: subcategory.isEmpty ? null : subcategory,
              hint: Text(psText(context, 'انتخاب زیر‌دسته', 'فرعي کټګوري وټاکئ')),
              items: (subcategories[category] ?? []).map((c) => DropdownMenuItem(value: c['id'], child: Text(localizedSubcategoryTitle(context, category, c['id']!, c['title']!)))).toList(),
              onChanged: (val) => setState(() => subcategory = val ?? ''),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: province.isEmpty ? null : province,
            hint: Text(psText(context, 'انتخاب ولایت', 'ولایت وټاکئ')),
            items: provinces
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(localizedProvince(context, p)),
                    ))
                .toList(),
            onChanged: (val) => setState(() => province = val ?? ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: psText(context, 'قیمت', 'بیه'),
              hintText: psText(context, 'مثلاً 10000', 'لکه 10000'),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD7E2FF)),
            ),
            child: Row(children: [
              Expanded(child: ChoiceChip(
                label: Text(psText(context, 'افغانی (AFN)', 'افغانۍ (AFN)')),
                selected: currency == 'AFN',
                onSelected: (_) => setState(() => currency = 'AFN'),
                selectedColor: const Color(0xFF1565C0),
                labelStyle: TextStyle(color: currency == 'AFN' ? Colors.white : const Color(0xFF12345B), fontWeight: FontWeight.w800),
              )),
              Expanded(child: ChoiceChip(
                label: const Text('دلار (USD)'),
                selected: currency == 'USD',
                onSelected: (_) => setState(() => currency = 'USD'),
                selectedColor: const Color(0xFF1565C0),
                labelStyle: TextStyle(color: currency == 'USD' ? Colors.white : const Color(0xFF12345B), fontWeight: FontWeight.w800),
              )),
            ]),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: desc,
            maxLines: 3,
            decoration: InputDecoration(labelText: psText(context, 'توضیحات', 'تشریحات')),
          ),
          if (category == 'social_pages') ...[
            const SizedBox(height: 12),
            TextField(
              controller: socialLink,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: tr(context, 'social_link'), hintText: tr(context, 'social_link_hint'), prefixIcon: const Icon(Icons.link)),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: contactPhone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: psText(context, 'شماره تماس', 'د اړیکې شمېره')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: locationText,
            decoration: InputDecoration(labelText: psText(context, 'آدرس / آدرس دقیق', 'پته / دقیقه پته')),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(psText(context, 'امکان چت مستقیم', 'مستقیمې خبرې اترې')),
            value: allowChat,
            onChanged: (val) => setState(() => allowChat = val),
          ),
          SwitchListTile(
            title: Text(psText(context, 'نمایش شماره تماس', 'د اړیکې شمېره ښکاره کول')),
            value: showPhone,
            onChanged: (val) => setState(() => showPhone = val),
          ),
          SwitchListTile(
            title: Text(psText(context, 'قیمت توافقی', 'توافقي بیه')),
            value: isNegotiable,
            onChanged: (val) => setState(() => isNegotiable = val),
          ),
          const SizedBox(height: 12),
          Text('${psText(context, 'عکس‌ها', 'انځورونه')}: ${imageBytes.length}/20', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < imageBytes.length; i++)
              Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(imageBytes[i], width: 86, height: 86, fit: BoxFit.cover)),
                Positioned(top: 2, right: 2, child: InkWell(onTap: () => setState(() { imageBytes.removeAt(i); imageNames.removeAt(i); imageUrls.clear(); }), child: const CircleAvatar(radius: 12, child: Icon(Icons.close, size: 16)))),
              ]),
            if (imageBytes.length < 20) InkWell(onTap: _pickImage, child: Container(width: 86, height: 86, decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_a_photo))),
          ]),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: publishing ? null : _publish, icon: publishing ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.publish), label: Text(publishing ? 'در حال انتشار...' : 'ثبت و انتشار آگهی')),
        ],
      ),
    );
  }
}
