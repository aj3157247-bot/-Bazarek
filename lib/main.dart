import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_panel_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BazarBuzurgApp());
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
};

class ApiConfig {
  static const String baseUrl = 'https://bazarek.onrender.com/api';
}

class AuthService {
  static final ValueNotifier<int> authVersion = ValueNotifier<int>(0);
  static String? token;
  static String? userName;
  static String? userContact;
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
    if (refreshTokenVal != null && refreshTokenVal.isNotEmpty) {
      await prefs.setString('refresh_token', refreshTokenVal);
    }
    authVersion.value++;
  }

  static Future<void> logout() async {
    token = null;
    userName = null;
    userContact = null;
    refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_contact');
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
    ChatListScreen(),
    AddProductScreen(),
    MyProductsScreen(),
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
          if ((idx == 1 || idx == 2) && !AuthService.isLoggedIn) {
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
            icon: const Icon(Icons.chat_outlined),
            selectedIcon: const Icon(Icons.chat),
            label: tr(context, 'chat'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: tr(context, 'add'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt),
            selectedIcon: const Icon(Icons.list),
            label: tr(context, 'my_ads'),
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
  List<dynamic> products = [];
  bool isLoading = true;
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
      if (mounted) {
        setState(() {
          products = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          products = [];
          loadError = e.toString().replaceFirst('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'app_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              final current = Localizations.localeOf(context).languageCode;
              BazarBuzurgApp.setLocale(
                context,
                Locale(current == 'fa' ? 'ps' : 'fa'),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                onChanged: (val) {
                  searchQuery = val;
                  Future.delayed(const Duration(milliseconds: 450), () {
                    if (!mounted || searchQuery != val) return;
                    _loadProducts();
                  });
                },
                decoration: InputDecoration(
                  hintText: tr(context, 'search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Text('دسته‌بندی‌ها', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(
              height: 92,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = categories[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubcategoryScreen(category: c))),
                    child: Container(
                      width: 105, padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Theme.of(context).colorScheme.primaryContainer),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(c['icon'] as IconData, size: 30),
                        const SizedBox(height: 5),
                        Text(c['title'] as String, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: selectedProvince.isEmpty ? null : selectedProvince,
                    hint: Text(tr(context, 'all_provinces')),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(tr(context, 'all_provinces')),
                      ),
                      ...provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                    ],
                    onChanged: (val) {
                      setState(() => selectedProvince = val ?? '');
                      _loadProducts();
                    },
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: selectedCategory.isEmpty ? null : selectedCategory,
                    hint: Text(tr(context, 'all_categories')),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(tr(context, 'all_categories')),
                      ),
                      ...categories.map((c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text(c['title'] as String),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => selectedCategory = val ?? '');
                      _loadProducts();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : loadError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off, size: 48),
                                const SizedBox(height: 12),
                                Text(loadError!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                FilledButton.icon(onPressed: _loadProducts, icon: const Icon(Icons.refresh), label: const Text('تلاش دوباره')),
                              ],
                            ),
                          ),
                        )
                      : products.isEmpty
                          ? const Center(child: Text('هنوز هیچ آگهی فعالی ثبت نشده است.'))
                          : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: products.length,
                          itemBuilder: (context, idx) => _ProductCard(item: products[idx]),
                        ),
            ),
          ],
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
    final boostLabel = item['boost_label']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      elevation: boostLabel.isNotEmpty ? 3 : 1,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: item))),
        child: SizedBox(
          height: 126,
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (boostLabel.isNotEmpty) Chip(label: Text(boostLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), avatar: const Icon(Icons.auto_awesome, size: 15), visualDensity: VisualDensity.compact),
                    Text(item['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    Text(price == '0' ? tr(context,'free') : '$price ${tr(context,'afghani')}', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text('${item['province'] ?? ''}${(item['location_text'] ?? '').toString().isNotEmpty ? ' • ${item['location_text']}' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              ),
              SizedBox(width: 128, height: 126, child: Stack(fit: StackFit.expand, children: [
                imageUrl.isNotEmpty ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)) : Container(color: Colors.grey.shade300, child: const Icon(Icons.image, size: 42)),
                if (boostLabel.isNotEmpty) Positioned(top: 7, right: 7, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), child: Text(boostLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))),
              ])),
            ],
          ),
        ),
      ),
    );
  }
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
                  Text(
                    product['title'] ?? '',
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
                  Text(product['description'] ?? 'بدون توضیحات'),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(product['province'] ?? ''),
                    subtitle: Text(product['location_text'] ?? ''),
                  ),
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
                        const SnackBar(content: Text('شماره تماس ثبت نشده است.')),
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
                          SnackBar(content: Text('امکان تماس با $phone وجود ندارد.')),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('باز کردن تماس تلفنی ناموفق بود.')),
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
    if (!AuthService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(context, 'chat'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'برای ارسال و دریافت پیام، ابتدا حساب خود را بسازید یا وارد حساب شوید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => requireAccount(context),
                  icon: const Icon(Icons.login),
                  label: const Text('ورود / ثبت‌نام'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'chat'))),
      body: const Center(child: Text('لیست پیام‌ها خالی است')),
    );
  }
}

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(tr(context, 'add'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'برای ثبت آگهی، ابتدا حساب خود را بسازید یا وارد حساب شوید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => requireAccount(context),
                  icon: const Icon(Icons.login),
                  label: const Text('ورود / ثبت‌نام'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'add'))),
      body: const AddProductSheet(),
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
    if (level >= 5) return '🏆 فروشنده طلایی';
    if (level == 4) return '👑 فروشنده ویژه';
    if (level == 3) return '💥 قدرتی';
    if (level == 2) return '🔥 انفجاری';
    if (level == 1) return '⚡ توربو';
    return '';
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
              const Text('برای دیدن آگهی‌های خود، ابتدا وارد حساب شوید.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                  if (mounted) _load();
                },
                child: const Text('ورود / ثبت‌نام'),
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
                  ? const Center(child: Text('شما هنوز هیچ آگهی ثبت نکرده‌اید.'))
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
                                      label: Text(badge.isEmpty ? '🚀 بوست آگهی' : '🚀 تقویت بوست'),
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
  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  List<dynamic> packages = [];
  List<dynamic> subscriptions = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

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
    return showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مبلغ: $price افغانی'),
              const SizedBox(height: 8),
              const Text('مبلغ را انتقال دهید و شماره پیگیری/رسید را وارد کنید.'),
              const SizedBox(height: 12),
              TextField(
                controller: c,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(
                  labelText: 'شماره پیگیری / رسید',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('لغو'),
            ),
            FilledButton(
              onPressed: c.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, c.text.trim()),
              child: const Text('ثبت درخواست'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyOne(dynamic pkg) async {
    final id = widget.listing?['id']?.toString();
    if (id == null || id.isEmpty) return;
    final ref = await _referenceDialog(title: pkg['title']?.toString() ?? 'بوست آگهی', price: int.tryParse('${pkg['price_afn']}') ?? 0);
    if (ref == null) return;
    try {
      await ApiService.createBoostOrder(id, pkg['id'].toString(), ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('درخواست بوست ثبت شد؛ پس از تأیید پرداخت فعال می‌شود.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _buyGlobal(String plan, int price, String title) async {
    final ref = await _referenceDialog(title: title, price: price);
    if (ref == null) return;
    try {
      await ApiService.createGlobalBoost(plan, ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('درخواست اشتراک ثبت شد؛ پس از تأیید پرداخت برای همه آگهی‌های شما فعال می‌شود.')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalActive = subscriptions.any((s) => ['boost_monthly', 'boost_yearly'].contains(s['plan']) && s['status'] == 'active' && DateTime.tryParse('${s['ends_at']}')?.isAfter(DateTime.now()) == true);
    return Scaffold(
      appBar: AppBar(title: const Text('🚀 Boost بازارک')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(error!, textAlign: TextAlign.center)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer]),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🚀 آگهی‌ات را از بقیه جلو بزن!', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                          SizedBox(height: 6),
                          Text('هرچه سطح بوست بالاتر باشد، آگهی در جایگاه بالاتری نمایش داده می‌شود و برچسپ مخصوص خودش را می‌گیرد.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (widget.listing != null) ...[
                      Text('⚡ فقط همین آگهی', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      for (final pkg in packages)
                        Card(
                          child: ListTile(
                            leading: Text(pkg['id'] == 'boost24' ? '⚡' : pkg['id'] == 'boost3' ? '🔥' : '💥', style: const TextStyle(fontSize: 30)),
                            title: Text(pkg['title']?.toString() ?? ''),
                            subtitle: Text(pkg['description']?.toString() ?? ''),
                            trailing: FilledButton(onPressed: () => _buyOne(pkg), child: Text('${pkg['price_afn']} افغانی')),
                          ),
                        ),
                      const SizedBox(height: 18),
                    ],
                    Text('👑 برای تمام آگهی‌های شما', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Text('👑', style: TextStyle(fontSize: 30)),
                        title: const Text('ماهانه — همه آگهی‌ها'),
                        subtitle: const Text('۳۰ روز؛ تمام آگهی‌های فعال شما با اولویت ویژه نمایش داده می‌شوند.'),
                        trailing: globalActive ? const Chip(label: Text('فعال')) : FilledButton(onPressed: () => _buyGlobal('boost_monthly', 400, '👑 بوست ماهانه'), child: const Text('۴۰۰ افغانی')),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Text('🏆', style: TextStyle(fontSize: 30)),
                        title: const Text('سالانه — همه آگهی‌ها'),
                        subtitle: const Text('۳۶۵ روز؛ بالاترین سطح اولویت برای تمام آگهی‌های شما.'),
                        trailing: globalActive ? const Chip(label: Text('فعال')) : FilledButton(onPressed: () => _buyGlobal('boost_yearly', 3500, '🏆 بوست سالانه'), child: const Text('۳۵۰۰ افغانی')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('💡 بوست‌های کوتاه‌مدت فقط روی همان آگهی اعمال می‌شوند؛ اشتراک ماهانه و سالانه روی همه آگهی‌های شما اثر می‌گذارد.', style: TextStyle(color: Colors.black54)),
                  ],
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
    final categoryTitle = category['title']?.toString() ?? 'دسته‌بندی';
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
          final subcategoryTitle = c['title']?.toString() ?? '';
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
                  ? Center(child: Text('در «${widget.categoryTitle}» هنوز آگهی فعالی پیدا نشد.'))
                  : RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: ads.length, itemBuilder: (_, i) => _ProductCard(item: ads[i]))),
    );
  }
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
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person, size: 40),
              ),
              accountName: Text(AuthService.userName ?? 'کاربر بازارک'),
              accountEmail: Text(AuthService.userContact ?? ''),
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
            title: const Text('🚀 Boost آگهی‌ها'),
            subtitle: const Text('افزایش نمایش آگهی و اشتراک ویژه'),
            onTap: () async {
              if (!await requireAccount(context)) return;
              if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const BoostScreen()));
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
    final picked = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 2000, maxHeight: 2000);
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
        'location_text': locationText.text.trim(), 'province': province, 'is_negotiable': isNegotiable,
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
      if (response.statusCode != 201) throw Exception(data['error'] ?? 'خطا در انتشار آگهی.');
      if (!mounted) return;
      _msg('آگهی با موفقیت منتشر شد.');
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
            decoration: const InputDecoration(labelText: 'عنوان آگهی'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: category.isEmpty ? null : category,
            hint: const Text('انتخاب دسته‌بندی'),
            items: categories.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['title'] as String))).toList(),
            onChanged: (val) => setState(() { category = val ?? ''; subcategory = ''; }),
          ),
          if ((subcategories[category] ?? []).isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: subcategory.isEmpty ? null : subcategory,
              hint: const Text('انتخاب زیر‌دسته'),
              items: (subcategories[category] ?? []).map((c) => DropdownMenuItem(value: c['id'], child: Text(c['title']!))).toList(),
              onChanged: (val) => setState(() => subcategory = val ?? ''),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: province.isEmpty ? null : province,
            hint: const Text('انتخاب ولایت'),
            items: provinces
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p),
                    ))
                .toList(),
            onChanged: (val) => setState(() => province = val ?? ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'قیمت (افغانی)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: desc,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'توضیحات'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contactPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'شماره تماس'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: locationText,
            decoration: const InputDecoration(labelText: 'آدرس / آدرس دقیق'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('امکان چت مستقیم'),
            value: allowChat,
            onChanged: (val) => setState(() => allowChat = val),
          ),
          SwitchListTile(
            title: const Text('نمایش شماره تماس'),
            value: showPhone,
            onChanged: (val) => setState(() => showPhone = val),
          ),
          SwitchListTile(
            title: const Text('قیمت توافقی'),
            value: isNegotiable,
            onChanged: (val) => setState(() => isNegotiable = val),
          ),
          const SizedBox(height: 12),
          Text('عکس‌ها: ${imageBytes.length}/10', style: const TextStyle(fontWeight: FontWeight.bold)),
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
