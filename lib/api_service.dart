import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://bazarek.onrender.com/api';

  // دریافت لیست محصولات
  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('خطا در دریافت لیست محصولات');
    }
  }

  // ثبت محصول جدید
  static Future<bool> addProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(productData),
    );
    return response.statusCode == 201;
  }

  // تولید متن آگهی با جمینای
  static Future<String> generateAd(String productName, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate-ad'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'productName': productName,
        'description': description,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['adText'];
    } else {
      throw Exception('خطا در تولید متن آگهی');
    }
  }
}
