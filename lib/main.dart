import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class ApiConfig {
  static const String baseUrl = 'https://afgbazar.com/api/v1';
}

class AuthService {
  static String? token;
  static String? userName;
  static String? userContact;

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  static Future<void> saveUser(String tokenVal, String nameVal, String contactVal) async {
    token = tokenVal;
    userName = nameVal;
    userContact = contactVal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', tokenVal);
    await prefs.setString('user_name', nameVal);
    await prefs.setString('user_contact', contactVal);
  }

  static Future<void> logout() async {
    token = null;
    userName = null;
    userContact = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_contact');
  }
}

class ApiService {
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (AuthService.token != null) 'Authorization': 'Bearer ${AuthService.token}',
      };

  static Future<Map<String, dynamic>> login(String phoneOrEmail, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    // ۱. بررسی ثبت نام قبلی در حافظه دستگاه
    final savedPassword = prefs.getString('user_pwd_$phoneOrEmail');
    final savedName = prefs.getString('registered_name_$phoneOrEmail');

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: headers,
        body: jsonEncode({'login': phoneOrEmail, 'password': password}),
      ).timeout(const Duration(seconds: 4));
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}

    // ۲. عدم اجازه ورود در صورت عدم وجود حساب ثبت شده
    if (savedPassword == null) {
      return {'error': 'این حساب کاربری وجود ندارد. لطفاً ابتدا ثبت‌نام (Sign Up) کنید.'};
    }

    if (savedPassword != password) {
      return {'error': 'رمز عبور وارد شده اشتباه است.'};
    }

    return {
      'token': 'local_sec_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'name': savedName ?? 'کاربر بازارک',
        'contact': phoneOrEmail,
      }
    };
  }

  static Future<Map<String, dynamic>> register(String name, String phoneOrEmail, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    // ذخیره اطلاعات ثبت‌نام جهت اعتبارسنجی ورود بعدی
    await prefs.setString('registered_name_$phoneOrEmail', name);
    await prefs.setString('user_pwd_$phoneOrEmail', password);

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/register'),
        headers: headers,
        body: jsonEncode({'name': name, 'login': phoneOrEmail, 'password': password}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (_) {}

    return {
      'token': 'local_reg_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'name': name,
        'contact': phoneOrEmail,
      }
    };
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
      'page': page.toString(),
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/products').replace(queryParameters: queryParams);
    try {
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['data'] ?? [];
      }
    } catch (_) {}
    return [];
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
        onDestinationSelected: (idx) {
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

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
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
                  _loadProducts();
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
                  : products.isEmpty
                      ? const Center(child: Text('هیچ آگهی یافت نشد'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, idx) {
                            return _ProductCard(item: products[idx]);
                          },
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
      if (item['image_url'] != null) {
        images = jsonDecode(item['image_url']);
      }
    } catch (_) {}

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: images.isNotEmpty
                  ? Image.network(
                      images.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.image, size: 50)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item['price'] ?? 0} ${tr(context, 'afghani')}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14),
                      Text(
                        item['province'] ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                  onPressed: () {
                    final phone = product['contact_phone'] ?? '';
                    if (phone.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('شماره تماس: $phone')),
                      );
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
                  onPressed: () {},
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
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'add'))),
      body: const AddProductSheet(),
    );
  }
}

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'my_ads'))),
      body: const Center(child: Text('شما هنوز هیچ آگهی ثبت نکرده‌اید')),
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
        user['contact'] ?? contact,
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
  String province = '';
  bool allowChat = true;
  bool showPhone = true;
  bool isNegotiable = false;
  bool uploading = false;

  List<Uint8List> imageBytes = [];
  List<String> imageNames = [];
  List<String> imageUrls = [];

  final ImagePicker _picker = ImagePicker();

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        imageBytes.add(bytes);
        imageNames.add(image.name);
      });
    }
  }

  Future<void> _uploadImages() async {
    setState(() => uploading = true);
    setState(() => uploading = false);
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
            items: categories
                .map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['title'] as String),
                    ))
                .toList(),
            onChanged: (val) => setState(() => category = val ?? ''),
          ),
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
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('افزودن تصویر'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: uploading
                ? null
                : () async {
                    if (title.text.trim().isEmpty) {
                      _msg('عنوان آگهی را وارد کنید.');
                      return;
                    }
                    if (category.isEmpty) {
                      _msg('دسته‌بندی را انتخاب کنید.');
                      return;
                    }
                    if (province.isEmpty) {
                      _msg('ولایت آگهی را انتخاب کنید.');
                      return;
                    }
                    if (imageBytes.isNotEmpty && imageUrls.isEmpty) {
                      await _uploadImages();
                    }
                    if (!mounted) return;
                    Navigator.pop(context, {
                      'title': title.text.trim(),
                      'category': category,
                      'price': double.tryParse(price.text.replaceAll(',', '')) ?? 0,
                      'cost_price': 0,
                      'stock': int.tryParse(stock.text) ?? 1,
                      'description': desc.text.trim(),
                      'image_url': jsonEncode(imageUrls),
                      'allow_chat': allowChat,
                      'show_phone': showPhone,
                      'contact_phone': contactPhone.text.trim(),
                      'location_text': locationText.text.trim(),
                      'province': province,
                      'is_negotiable': isNegotiable,
                    });
                  },
            icon: const Icon(Icons.check),
            label: const Text('ثبت و انتشار آگهی'),
          ),
        ],
      ),
    );
  }
}
