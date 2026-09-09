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
    String? province,
    String? query,
    int page = 1,
  }) async {
    final queryParams = {
      if (category != null && category.isNotEmpty) 'category': category,
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
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/products'), headers: headers).timeout(const Duration(seconds: 20));
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data is List) return data;
    if (res.statusCode == 401 && await refreshSession()) return getMyProducts();
    throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت آگهی‌های شما.') : 'خطا در دریافت آگهی‌های شما.');
  }

  static Future<List<dynamic>> getBoostPackages() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/monetization/packages'), headers: headers).timeout(const Duration(seconds: 20));
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data is List) return data;
    if (res.statusCode == 401 && await refreshSession()) return getBoostPackages();
    throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت بسته‌های بوست.') : 'خطا در دریافت بسته‌های بوست.');
  }

  static Future<Map<String, dynamic>> createBoostOrder(String listingId, String packageId, String reference) async {
    final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/promotions/orders'), headers: headers, body: jsonEncode({
      'listing_id': listingId,
      'package_id': packageId,
      'payment_method': 'manual',
      'payment_reference': reference.trim(),
    })).timeout(const Duration(seconds: 20));
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) return data is Map<String,dynamic> ? data : <String,dynamic>{};
    if (res.statusCode == 401 && await refreshSession()) return createBoostOrder(listingId, packageId, reference);
    throw Exception(data is Map ? (data['error'] ?? 'ثبت سفارش بوست ناموفق بود.') : 'ثبت سفارش بوست ناموفق بود.');
  }

  static Future<Map<String, dynamic>> createGlobalBoost(String plan, String reference) async {
    final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/subscriptions'), headers: headers, body: jsonEncode({
      'plan': plan,
      'payment_reference': reference.trim(),
    })).timeout(const Duration(seconds: 20));
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) return data is Map<String,dynamic> ? data : <String,dynamic>{};
    if (res.statusCode == 401 && await refreshSession()) return createGlobalBoost(plan, reference);
    throw Exception(data is Map ? (data['error'] ?? 'ثبت درخواست بوست سراسری ناموفق بود.') : 'ثبت درخواست بوست سراسری ناموفق بود.');
  }

  static Future<List<dynamic>> getSubscriptions() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/subscriptions'), headers: headers).timeout(const Duration(seconds: 20));
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data is List) return data;
    if (res.statusCode == 401 && await refreshSession()) return getSubscriptions();
    throw Exception(data is Map ? (data['error'] ?? 'خطا در دریافت اشتراک‌ها.') : 'خطا در دریافت اشتراک‌ها.');
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
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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
    final boostBadge = item['boost_badge']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: item))),
        child: SizedBox(
          height: 132,
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (boostBadge.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFF6D00)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(boostBadge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    Text(item['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    Text(price == '0' ? tr(context,'free') : '$price ${tr(context,'afghani')}', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text('${item['province'] ?? ''}${(item['location_text'] ?? '').toString().isNotEmpty ? ' • ${item['location_text']}' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              ),
              SizedBox(width: 120, height: 132, child: imageUrl.isNotEmpty ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)) : Container(color: Colors.grey.shade300, child: const Icon(Icons.image, size: 42))),
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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!AuthService.isLoggedIn) { if (mounted) setState(() { loading = false; }); return; }
    setState(() { loading = true; error = null; });
    try {
      final data = await ApiService.getMyProducts();
      if (mounted) setState(() { ads = data; loading = false; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _openBoost(dynamic ad) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => BoostScreen(listing: ad)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Scaffold(appBar: AppBar(title: Text(tr(context, 'my_ads'))), body: const Center(child: Text('برای مدیریت و بوست آگهی‌ها ابتدا وارد حساب شوید.')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'my_ads')),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('تلاش دوباره'))])))
              : ads.isEmpty
                  ? const Center(child: Text('شما هنوز هیچ آگهی ثبت نکرده‌اید.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: ads.length,
                      itemBuilder: (_, i) {
                        final ad = ads[i];
                        final title = ad['title']?.toString() ?? 'آگهی بدون عنوان';
                        final active = ad['is_active'] == true || ad['is_active'] == 1;
                        final image = ad['image_url']?.toString() ?? '';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(8),
                            leading: SizedBox(width: 72, height: 72, child: image.isNotEmpty ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.image)) : const Icon(Icons.image, size: 40)),
                            title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(active ? 'فعال • آماده برای بوست' : 'غیرفعال'),
                            trailing: active ? FilledButton.icon(onPressed: () => _openBoost(ad), icon: const Icon(Icons.rocket_launch, size: 18), label: const Text('بوست')) : null,
                          ),
                        );
                      },
                    ),
    );
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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final results = await Future.wait([ApiService.getBoostPackages(), ApiService.getSubscriptions()]);
      if (mounted) setState(() { packages = results[0]; subscriptions = results[1]; loading = false; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<String?> _referenceDialog(String title, String price) async {
    final c = TextEditingController();
    return showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('مبلغ $price افغانی را طبق روش پرداخت بازارک انتقال دهید، سپس شماره پیگیری یا رسید را وارد کنید.'),
        const SizedBox(height: 12),
        TextField(controller: c, decoration: const InputDecoration(labelText: 'شماره پیگیری / رسید', border: OutlineInputBorder())),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')), FilledButton(onPressed: () { if (c.text.trim().isNotEmpty) Navigator.pop(ctx, c.text.trim()); }, child: const Text('ثبت درخواست'))],
    ));
  }

  Future<void> _buyPackage(dynamic pkg) async {
    if (widget.listing == null) return;
    final ref = await _referenceDialog(pkg['title']?.toString() ?? 'بوست آگهی', NumberFormatHelper.format(pkg['price_afn']));
    if (ref == null) return;
    try {
      await ApiService.createBoostOrder(widget.listing['id'].toString(), pkg['id'].toString(), ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('درخواست بوست ثبت شد و پس از تأیید مدیریت فعال می‌شود.')));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _buyGlobal(String plan, String title, int price) async {
    final ref = await _referenceDialog(title, NumberFormatHelper.format(price));
    if (ref == null) return;
    try {
      await ApiService.createGlobalBoost(plan, ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('درخواست بوست سراسری ثبت شد و پس از تأیید مدیریت فعال می‌شود.')));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🚀 بوست بازارک')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, textAlign: TextAlign.center))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  const Text('🚀 آگهی‌ات را از بقیه جلو بزن!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('پول بیشتر یعنی اولویت بیشتر در نمایش آگهی‌ها. بوست‌ها خودکار روی جایگاه آگهی اثر می‌گذارند.'),
                  if (widget.listing != null) ...[
                    const SizedBox(height: 18),
                    Text('برای: ${widget.listing['title'] ?? 'آگهی'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...packages.map((p) => _BoostTile(title: p['title']?.toString() ?? '', description: p['description']?.toString() ?? '', price: NumberFormatHelper.format(p['price_afn']), icon: Icons.rocket_launch, onTap: () => _buyPackage(p))),
                  ],
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('👑 بوست برای تمام آگهی‌های شما', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('با این گزینه همه آگهی‌های فعال شما به‌صورت خودکار اولویت بالاتری می‌گیرند.'),
                  const SizedBox(height: 10),
                  _BoostTile(title: '👑 ماهانه — همه آگهی‌ها', description: '۳۰ روز برای تمام آگهی‌های فعال شما.', price: '۴۰۰', icon: Icons.workspace_premium, onTap: () => _buyGlobal('monthly_boost','👑 بوست ماهانه',400)),
                  _BoostTile(title: '🏆 سالانه — همه آگهی‌ها', description: '۳۶۵ روز برای تمام آگهی‌های فعال شما؛ مناسب فروشندگان حرفه‌ای.', price: '۳٬۵۰۰', icon: Icons.emoji_events, onTap: () => _buyGlobal('yearly_boost','🏆 بوست سالانه',3500)),
                  if (subscriptions.any((s) => s['status'] == 'pending'))
                    const Padding(padding: EdgeInsets.only(top: 12), child: Text('⏳ یک درخواست بوست سراسری شما در انتظار تأیید مدیریت است.')),
                ],),
    );
  }
}

class _BoostTile extends StatelessWidget {
  final String title, description, price;
  final IconData icon;
  final VoidCallback onTap;
  const _BoostTile({required this.title, required this.description, required this.price, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(description),
      isThreeLine: true,
      trailing: FilledButton(onPressed: onTap, child: Text('$price افغانی')),
    ),
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
