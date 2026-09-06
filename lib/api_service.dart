import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bazarek.onrender.com/api',
  );
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'bazarek_access_token';
  static const _refreshKey = 'bazarek_refresh_token';

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    if (method == 'GET') {
      response = await http.get(uri, headers: headers);
    } else if (method == 'POST') {
      response = await http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
    } else {
      throw Exception('Unsupported HTTP method');
    }

    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error']?.toString() ?? 'خطا در ارتباط با سرور');
    }
    return data;
  }

  static Future<void> _saveSession(Map<String, dynamic>? session) async {
    if (session == null) return;
    final access = session['access_token']?.toString();
    final refresh = session['refresh_token']?.toString();
    if (access != null && access.isNotEmpty) await _storage.write(key: _tokenKey, value: access);
    if (refresh != null && refresh.isNotEmpty) await _storage.write(key: _refreshKey, value: refresh);
  }

  static Future<bool> hasSession() async => (await _storage.read(key: _tokenKey))?.isNotEmpty ?? false;

  static Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String shopName,
    required String email,
    required String password,
  }) async {
    final data = await _request('POST', '/auth/signup', auth: false, body: {
      'fullName': fullName,
      'shopName': shopName,
      'email': email,
      'password': password,
    });
    await _saveSession(data['session']);
    return data;
  }

  static Future<void> login(String email, String password) async {
    final data = await _request('POST', '/auth/login', auth: false, body: {
      'email': email,
      'password': password,
    });
    await _saveSession(data['session']);
  }

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
  }

  static Future<Map<String, dynamic>> me() => _request('GET', '/auth/me');

  static Future<Map<String, dynamic>> getDashboard() => _request('GET', '/dashboard');

  static Future<List<dynamic>> getProducts() async {
    final token = await _storage.read(key: _tokenKey);
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    final response = await http.get(Uri.parse('$baseUrl/products'), headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw Exception(decoded is Map ? (decoded['error'] ?? 'خطا در دریافت محصولات') : 'خطا در دریافت محصولات');
    }
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  static Future<bool> addProduct(Map<String, dynamic> productData) async {
    await _request('POST', '/products', body: productData);
    return true;
  }

  static Future<String> generateAd(String productName, String description) async {
    final data = await _request('POST', '/generate-ad', body: {
      'productName': productName,
      'description': description,
    });
    return data['adText']?.toString() ?? '';
  }
}
