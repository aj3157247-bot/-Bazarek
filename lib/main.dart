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
    // توکن‌های ساختگی نسخه‌های قدیمی معتبر نیستند؛ آنها را پاک می‌کنیم.
    if (AuthService.token != null && AuthService.token!.startsWith('local_')) {
      await AuthService.logout();
    }

    setState(() {
      _locale = Locale(lang);
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
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
      home: const MainLayout(),
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
  'boost_24_desc': '۲۴ ساعت؛ ارزان‌ترین راه برای بیشتر دیده‌شدن همین آگهی.',
  'boost_3_desc': '۳ روز؛ آگهی شما با اولویت بیشتر نمایش داده می‌شود.',
  'boost_7_desc': '۷ روز؛ بالاترین قدرت بوست کوتاه‌مدت برای همین آگهی.',
  'boost_month_desc': '۳۰ روز؛ تمام آگهی‌های فعال شما اولویت ویژه می‌گیرند.',
  'boost_year_desc': '۳۶۵ روز؛ بالاترین اولویت برای تمام آگهی‌های فعال شما.',
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
  'boost_24_desc': '۲۴ ساعته؛ د همدې اعلان د ډېر لیدل کېدو ارزانه لاره.',
  'boost_3_desc': '۳ ورځې؛ ستاسو اعلان په لوړه لومړیتوب ښکاره کېږي.',
  'boost_7_desc': '۷ ورځې؛ د همدې اعلان لپاره تر ټولو پیاوړی لنډمهاله Boost.',
  'boost_month_desc': '۳۰ ورځې؛ ستاسو ټول فعال اعلانونه ځانګړی لومړیتوب اخلي.',
  'boost_year_desc': '۳۶۵ ورځې؛ ستاسو ټولو فعالو اعلانونو ته تر ټولو لوړ لومړیتوب.',
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

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  static Future<void> saveUser(String tokenVal, String nameVal, String contactVal, {String? refreshTokenVal}) async {
    token = tokenVal;
    userName = nameVal;
    userContact = contactVal;
    refreshToken = refreshTokenVal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', tokenVal);
    await prefs.setString('user_name', nameVal);
    await prefs.setString('user_contact', contactVal);
    if (avatarUrl != null && avatarUrl!.isNotEmpty) await prefs.setString('avatar_url', avatarUrl!);
    if (refreshTokenVal != null && refreshTokenVal.isNotEmpty) {
      await prefs.setString('refresh_token', refreshTokenVal);
    }
    authVersion.value++;
  }

  static Future<void> logout() async {
    token = null;
    userName = null;
    userContact = null;
    avatarUrl = null;
    refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_contact');
    await prefs.remove('avatar_url');
    await prefs.remove('refresh_token');
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

  static Future<List<dynamic>> getMyProducts() async {
    var res = await http.get(Uri.parse('${ApiConfig.baseUrl}/products'), headers: headers).timeout(const Duration(seconds: 15));
    if (res.statusCode == 401 && await refreshSession()) {
      res = await http.get(Uri.parse('${ApiConfig.baseUrl}/products'), headers: headers).timeout(const Duration(seconds: 15));
    }
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت آگهی‌های شما.') : 'خطا در دریافت آگهی‌های شما.');
    return data is List ? data : List<dynamic>.from(data['data'] ?? const []);
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
    return list.where((x) => ['boost24','boost3','boost7'].contains(x['id'])).toList();
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

  String _friendlyNetworkError(Object error) {
    final raw = error.toString().toLowerCase();
    final networkFailure = raw.contains('failed to fetch') ||
        raw.contains('clientexception') ||
        raw.contains('socketexception') ||
        raw.contains('connection refused') ||
        raw.contains('connection reset') ||
        raw.contains('network is unreachable') ||
        raw.contains('no internet') ||
        raw.contains('network error') ||
        raw.contains('timed out');
    if (networkFailure) {
      return Localizations.localeOf(context).languageCode == 'ps'
          ? 'مهرباني وکړئ خپل انټرنېټي اتصال وګورئ او بیا هڅه وکړئ.'
          : 'لطفاً از وصل بودن اینترنت خود مطمئن شوید و دوباره تلاش کنید.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

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
                child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_rounded, size: 48), const SizedBox(height: 12),
                  Text(loadError!, textAlign: TextAlign.center), const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _loadProducts, icon: const Icon(Icons.refresh_rounded), label: Text(tr(context, 'retry'))),
                ]))),
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
    final priceText = (priceRaw == null || priceRaw.toString().trim().isEmpty || priceRaw.toString() == '0') ? tr(context, 'free') : '${NumberFormatHelper.format(priceRaw)} ${tr(context, 'afghani')}';
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
            imageUrl.isNotEmpty ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE9EDF3), child: Icon(Icons.image_not_supported_outlined, size: 34))) : const ColoredBox(color: Color(0xFFE9EDF3), child: Icon(Icons.image_outlined, size: 34)),
            if (count > 1) Positioned(left: 7, top: 7, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(.62), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.photo_library_outlined, color: Colors.white, size: 13), const SizedBox(width: 3), Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))]))),
            if (boost.isNotEmpty) Positioned(right: 7, top: 7, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFF8A00), borderRadius: BorderRadius.circular(8)), child: Text(boost, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))))
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
            SizedBox(width: 86, height: 188, child: imageUrl.isNotEmpty ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12, child: Icon(Icons.image_not_supported))) : const ColoredBox(color: Colors.black12, child: Icon(Icons.image, size: 30))),
            Expanded(child: Padding(padding: const EdgeInsets.all(9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(8)), child: Text(label.isEmpty ? '✨ ویژه' : label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
              const SizedBox(height: 8),
              LocalizedText(item['title']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 8),
              Text('${NumberFormatHelper.format(item['price'])} ${tr(context, 'afghani')}', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, fontSize: 12)),
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
    final price = NumberFormatHelper.format(item['price']);
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
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE9EDF4), child: Icon(Icons.image_not_supported_outlined, size: 36)))
                  : const ColoredBox(color: Color(0xFFE9EDF4), child: Icon(Icons.image_outlined, size: 36)),
              if (boostLabel.isNotEmpty)
                Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(9)), child: Text(boostLabel, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
              Positioned(top: 8, left: 8, child: _SaveAdButton(item: item)),
            ]),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LocalizedText(item['title']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const Spacer(),
                Text(price == '0' ? tr(context, 'free') : '$price ${tr(context, 'afghani')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
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
    return raw.replaceAllMapped(RegExp(r'(?<=\d)(?=(\d{3})+$)'), (_) => ',');
  }
}

class ProductDetailScreen extends StatelessWidget {
  final dynamic product;
  const ProductDetailScreen({super.key, required this.product});

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
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (_, i) => Image.network(images[i], fit: BoxFit.cover),
                ),
              )
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
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product['price'] ?? 0} ${tr(context, 'afghani')}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('بخش گفت‌وگو پس از اتصال به سیستم پیام‌رسانی آماده است.')),
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

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService.authVersion,
      builder: (context, _, __) {
        if (!AuthService.isLoggedIn) {
          return Scaffold(appBar: AppBar(title: Text(tr(context,'chat'))), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_outline, size: 64), const SizedBox(height: 16),
            Text(psText(context,'برای ارسال و دریافت پیام، ابتدا حساب خود را بسازید یا وارد حساب شوید.','د پیغامونو لېږلو او ترلاسه کولو لپاره لومړی خپل حساب جوړ یا دننه شئ.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: () => requireAccount(context), icon: const Icon(Icons.login), label: Text(psText(context,'ورود / ثبت‌نام','ننوتل / نوم لیکنه'))),
          ]))));
        }
        return Scaffold(appBar: AppBar(title: Text(tr(context,'chat'))), body: Center(child: Text(psText(context,'لیست پیام‌ها خالی است','د پیغامونو لېست تش دی.'))));
      },
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
  const MyProductsScreen({super.key});
  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List<dynamic> ads = [];
  bool loading = true;
  String? error;

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
      if (mounted) setState(() { ads = data; loading = false; error = null; });
    } catch (e) {
      if (mounted) setState(() { ads = []; loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  String _boostText(dynamic ad) {
    final level = int.tryParse('${ad['boost_level'] ?? 0}') ?? 0;
    return boostBadgeText(context, level);
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
              ? Center(child: Text(error!, textAlign: TextAlign.center))
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
                                  subtitle: Text('${NumberFormatHelper.format(ad['price'])} افغانی • ${ad['province'] ?? ''}'),
                                ),
                                if (badge.isNotEmpty)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      child: Chip(label: Text(badge), avatar: const Icon(Icons.auto_awesome, size: 18)),
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
        return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(u, fit: BoxFit.cover));
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
      if (mounted) setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
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
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
  }

  Future<void> _buyGlobal(String plan, int price, String title) async {
    final ref = await _referenceDialog(title: title, price: price);
    if (ref == null) return;
    try {
      await ApiService.createGlobalBoost(plan, ref);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'ps' ? 'ستاسو غوښتنه ثبت شوه؛ د تایید وروسته ستاسو ټول فعال اعلانونه Boost کېږي.' : 'درخواست ثبت شد؛ پس از تأیید پرداخت، روی همه آگهی‌های فعال شما اعمال می‌شود.'))); _load(); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
  }

  @override
  Widget build(BuildContext context) {
    final ps = Localizations.localeOf(context).languageCode == 'ps';
    final globalActive = subscriptions.any((s) => ['boost_monthly','boost_yearly'].contains(s['plan']) && s['status'] == 'active' && DateTime.tryParse('${s['ends_at']}')?.isAfter(DateTime.now()) == true);
    final shortPackages = packages.where((x) => ['boost24','boost3','boost7'].contains(x['id'])).toList();
    return Scaffold(
      appBar: AppBar(title: Text(ps ? '🚀 د بازارک Boost' : '🚀 Boost بازارک')),
      body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(error!, textAlign: TextAlign.center))) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ps ? '🚀 خپل اعلان له نورو مخکې کړئ!' : '🚀 آگهی‌ات را از بقیه جلو بزن!', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(ps ? 'هر څومره Boost لوړ وي، اعلان مو په لوړه درجه کې ښکاري او ځانګړی نښان اخلي.' : 'هرچه سطح Boost بالاتر باشد، آگهی در جایگاه بالاتری نمایش داده می‌شود و برچسپ مخصوص خودش را می‌گیرد.'),
          ])),
          const SizedBox(height: 22),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)), child: Text(ps ? '💳 د تادیې طریقه: د Boost د انتخاب پر مهال به د بازارک د کارت/حساب معلومات درښکاره شي. مبلغ ولېږئ، د رسید شمېره ولیکئ، او د مدیریت تایید ته انتظار وباسئ.' : '💳 روش پرداخت: هنگام انتخاب Boost، شماره کارت/حساب بازارک نمایش داده می‌شود. مبلغ را انتقال دهید، شماره رسید را وارد کنید و منتظر تأیید مدیریت بمانید.')),
          const SizedBox(height: 14),
          Text(ps ? '⚡ لنډمهاله Boost' : '⚡ بوست کوتاه‌مدت', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(ps ? 'یوازې د یوه ټاکلي اعلان لپاره؛ ارزانه او مناسب د چټک پلور لپاره.' : 'فقط برای یک آگهی؛ ارزان و مناسب برای فروش سریع.', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          if (shortPackages.isEmpty) Card(child: ListTile(leading: const Icon(Icons.info_outline), title: Text(ps ? 'لنډمهاله Boostونه موجود نه دي.' : 'بوست‌های کوتاه‌مدت موجود نیستند.')))
          else ...shortPackages.map((pkg) {
            final id = pkg['id'];
            final title = ps ? (id == 'boost24' ? '⚡ توربو — ۲۴ ساعته' : id == 'boost3' ? '🔥 انفجاري — ۳ ورځې' : '💥 پیاوړی — ۷ ورځې') : (id == 'boost24' ? '⚡ توربو — ۲۴ ساعت' : id == 'boost3' ? '🔥 انفجاری — ۳ روز' : '💥 قدرتی — ۷ روز');
            final desc = id == 'boost24' ? tr(context,'boost_24_desc') : id == 'boost3' ? tr(context,'boost_3_desc') : tr(context,'boost_7_desc');
            return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: Text(id == 'boost24' ? '⚡' : id == 'boost3' ? '🔥' : '💥', style: const TextStyle(fontSize: 30)), title: Text(title), subtitle: Text(desc), trailing: FilledButton(onPressed: () => _buyOne(pkg), child: Text('${pkg['price_afn']} ${tr(context,'afghani')}'))));
          }),
          const SizedBox(height: 20),
          Text(ps ? '👑 میاشتنی او کلنی Boost' : '👑 بوست ماهانه و سالانه', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(ps ? 'د پیسو په بدل کې ستاسو ټول فعال اعلانونه Boost کېږي.' : 'یک اشتراک بخرید تا تمام آگهی‌های فعال شما Boost شوند.', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Card(child: ListTile(leading: const Text('👑', style: TextStyle(fontSize: 30)), title: Text(ps ? 'میاشتنی — ټول اعلانونه' : 'ماهانه — همه آگهی‌ها'), subtitle: Text(tr(context,'boost_month_desc')), trailing: globalActive ? Chip(label: Text(ps ? 'فعال' : 'فعال')) : FilledButton(onPressed: () => _buyGlobal('boost_monthly', 300, ps ? '👑 میاشتنی Boost' : '👑 بوست ماهانه'), child: Text('۳۰۰ ${tr(context,'afghani')}')))),
          Card(child: ListTile(leading: const Text('🏆', style: TextStyle(fontSize: 30)), title: Text(ps ? 'کلنی — ټول اعلانونه' : 'سالانه — همه آگهی‌ها'), subtitle: Text(tr(context,'boost_year_desc')), trailing: globalActive ? Chip(label: Text(ps ? 'فعال' : 'فعال')) : FilledButton(onPressed: () => _buyGlobal('boost_yearly', 2500, ps ? '🏆 کلنی Boost' : '🏆 بوست سالانه'), child: Text('۲۵۰۰ ${tr(context,'afghani')}')))),
          const SizedBox(height: 8),
          Text(ps ? '💡 لنډمهاله Boost یوازې پر ټاکلي اعلان لګېږي. میاشتنی او کلنی پلان ستاسو پر ټولو فعالو اعلانونو اغېز کوي.' : '💡 بوست کوتاه‌مدت فقط روی همان آگهی اعمال می‌شود؛ اشتراک ماهانه و سالانه روی تمام آگهی‌های فعال شما اثر می‌گذارد.', style: const TextStyle(color: Colors.black54)),
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
      if (mounted) setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryTitle), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, textAlign: TextAlign.center))
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'profile'))),
      body: ListView(
        children: [
          if (AuthService.isLoggedIn) ...[
            UserAccountsDrawerHeader(
              currentAccountPicture: GestureDetector(
                onTap: () async {
                  final image = await pickProfileImage();
                  if (image == null) return;
                  try {
                    await ApiService.uploadAvatar(image);
                    if (mounted) setState(() {});
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(psText(context, 'عکس پروفایل با موفقیت تغییر کرد.', 'ستاسو د پروفایل انځور بدل شو.'))));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                  }
                },
                child: CircleAvatar(
                  backgroundImage: (AuthService.avatarUrl != null && AuthService.avatarUrl!.isNotEmpty) ? NetworkImage(AuthService.avatarUrl!) : null,
                  child: (AuthService.avatarUrl == null || AuthService.avatarUrl!.isEmpty) ? const Icon(Icons.person, size: 40) : null,
                ),
              ),
              accountName: Text(AuthService.userName ?? 'کاربر بازارک'),
              accountEmail: Text(AuthService.userContact ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.add_a_photo_outlined),
              title: Text(psText(context, 'تغییر عکس پروفایل', 'د پروفایل انځور بدلول')),
              subtitle: Text(psText(context, 'یک عکس از گالری انتخاب کنید.', 'له ګالري څخه یو انځور وټاکئ.')),
              onTap: () async {
                final image = await pickProfileImage();
                if (image == null) return;
                try { await ApiService.uploadAvatar(image); if (mounted) setState(() {}); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(psText(context, 'اعلان‌ها', 'خبرتیاوې')),
              subtitle: Text(psText(context, 'پیام‌های سیستم و نتیجه رسیدگی به گزارش‌ها', 'د سیسټم او راپورونو خبرتیاوې')),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(tr(context, 'logout'), style: const TextStyle(color: Colors.red)),
              onTap: () async {
                await AuthService.logout();
                setState(() {});
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: Text(tr(context, 'login')),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
                setState(() {});
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('ورود مدیریت'),
            subtitle: const Text('پنل مدیریت، کاربران، آگهی‌ها و شکایات'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.rocket_launch),
            title: Text('🚀 ${tr(context, 'boost')}'),
            subtitle: Text(psText(context, 'افزایش نمایش آگهی و اشتراک ویژه', 'د اعلانونو لیدل ډېر کړئ او ځانګړی ګډون واخلئ.')),
            onTap: () async {
              if (!await requireAccount(context)) return;
              if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const BoostScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: Text(tr(context, 'download_app')),
            subtitle: Text(tr(context, 'download_app_desc')),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(psText(context, 'لینک دانلود اپلیکیشن به‌زودی فعال می‌شود.', 'د اپلېکېشن د ډاونلوډ لینک به ژر فعال شي.'))));
            },
          ),
          const Divider(),
          SwitchListTile(
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (_) => BazarBuzurgApp.toggleTheme(context),
            title: Text(tr(context, 'dark_mode')),
            secondary: const Icon(Icons.dark_mode),
          ),
        ],
      ),
    );
  }
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
    }catch(e){if(!mounted)return;setState((){loading=false;error=e.toString().replaceFirst('Exception: ','');});}
  }
  Future<void> _read(Map<String,dynamic> n) async {
    if(n['is_read']==true)return;
    try{await ApiService.markNotificationRead(n['id'].toString());if(mounted)setState(()=>n['is_read']=true);}catch(_){}
  }
  Future<void> _delete(Map<String,dynamic> n) async {
    try{await ApiService.deleteNotification(n['id'].toString());if(mounted)setState(()=>items.remove(n));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(psText(context,'اعلان‌ها','خبرتیاوې')),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Text(error!)):RefreshIndicator(onRefresh:_load,child:items.isEmpty?ListView(children:[const SizedBox(height:160),Center(child:Text('اعلانی وجود ندارد.'))]):ListView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(context,i){final n=items[i];final unread=n['is_read']!=true;return Card(child:ListTile(onTap:()=>_read(n), leading:Icon(unread?Icons.notifications_active:Icons.notifications_none), title:Text(n['title']?.toString()??'اعلان بازارک',style:TextStyle(fontWeight:unread?FontWeight.bold:FontWeight.normal)), subtitle:Text('${n['message']??''}\n${n['created_at']??''}'),isThreeLine:true,trailing:IconButton(onPressed:()=>_delete(n),icon:const Icon(Icons.delete_outline))));})));
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
    if (imageBytes.length >= 10) { _msg('حداکثر ۱۰ عکس مجاز است.'); return; }

    // Web: use file_picker so the browser gives us the actual bytes.
    // This avoids image_picker Blob URLs, which can fail after selection.
    if (kIsWeb) {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (files.isEmpty) return;
      final remaining = 10 - imageBytes.length;
      for (final file in files.take(remaining)) {
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
    final remaining = 10 - imageBytes.length;
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
        'location_text': locationText.text.trim(), 'province': province, 'is_negotiable': isNegotiable, 'external_link': socialLink.text.trim(),
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
      if (mounted) _msg(e.toString().replaceFirst('Exception: ', ''));
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
            decoration: InputDecoration(labelText: psText(context, 'قیمت (افغانی)', 'بیه (افغانۍ)')),
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
          Text('${psText(context, 'عکس‌ها', 'انځورونه')}: ${imageBytes.length}/10', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < imageBytes.length; i++)
              Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(imageBytes[i], width: 86, height: 86, fit: BoxFit.cover)),
                Positioned(top: 2, right: 2, child: InkWell(onTap: () => setState(() { imageBytes.removeAt(i); imageNames.removeAt(i); imageUrls.clear(); }), child: const CircleAvatar(radius: 12, child: Icon(Icons.close, size: 16)))),
              ]),
            if (imageBytes.length < 10) InkWell(onTap: _pickImage, child: Container(width: 86, height: 86, decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_a_photo))),
          ]),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: publishing ? null : _publish, icon: publishing ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.publish), label: Text(publishing ? 'در حال انتشار...' : 'ثبت و انتشار آگهی')),
        ],
      ),
    );
  }
}
