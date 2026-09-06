import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://bazarek.onrender.com/api';
  static String? _token;

  static Map<String, String> _headers({bool auth = false}) => {
    'Content-Type': 'application/json',
    if (auth && _token != null) 'Authorization': 'Bearer $_token',
  };

  static void setToken(String? token) => _token = token;

  static Future<String> login(String email, String password) async {
    final r = await http.post(Uri.parse('$baseUrl/auth/login'), headers: _headers(), body: jsonEncode({'email': email, 'password': password}));
    final data = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(data['error'] ?? 'ورود ناموفق بود.');
    _token = data['token'];
    return _token!;
  }

  static Future<Map<String, dynamic>> register({required String email, required String password, String fullName = '', String shopName = '', String phone = ''}) async {
    final r = await http.post(Uri.parse('$baseUrl/auth/register'), headers: _headers(), body: jsonEncode({'email': email, 'password': password, 'full_name': fullName, 'shop_name': shopName, 'phone': phone}));
    final data = jsonDecode(r.body);
    if (r.statusCode != 201 && r.statusCode != 200) throw Exception(data['error'] ?? 'ثبت‌نام ناموفق بود.');
    if (data['token'] != null) _token = data['token'];
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final r = await http.get(Uri.parse('$baseUrl/me'), headers: _headers(auth: true));
    final data = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(data['error'] ?? 'خطا در دریافت پروفایل.');
    return Map<String, dynamic>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    final r = await http.get(Uri.parse('$baseUrl/products'), headers: _headers(auth: true));
    final data = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(data['error'] ?? 'خطا در دریافت محصولات.');
    return List<Map<String, dynamic>>.from(data.map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<Map<String, dynamic>> addProduct(Map<String, dynamic> product) async {
    final r = await http.post(Uri.parse('$baseUrl/products'), headers: _headers(auth: true), body: jsonEncode(product));
    final data = jsonDecode(r.body);
    if (r.statusCode != 201) throw Exception(data['error'] ?? 'خطا در ثبت محصول.');
    return Map<String, dynamic>.from(data);
  }

  static Future<void> deleteProduct(String id) async {
    final r = await http.delete(Uri.parse('$baseUrl/products/$id'), headers: _headers(auth: true));
    if (r.statusCode != 200) throw Exception(jsonDecode(r.body)['error'] ?? 'خطا در حذف محصول.');
  }

  static Future<String> generateAd(String productName, String description, {String language = 'fa'}) async {
    final r = await http.post(Uri.parse('$baseUrl/generate-ad'), headers: _headers(auth: true), body: jsonEncode({'productName': productName, 'description': description, 'language': language}));
    final data = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(data['error'] ?? 'خطا در تولید آگهی.');
    return data['adText'];
  }
}
