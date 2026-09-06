import 'dart:convert';
import 'package:http/http.dart' as http;
import 'product_model.dart';

class ApiService {
  // آدرس سرور بک‌اند (برای تست محلی یا آدرس سرور ابری)
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // دریافت لیست محصولات
  static Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Product.fromJson(data)).toList();
    } else {
      throw Exception('خطا در دریافت لیست محصولات');
    }
  }

  // تولید متن آگهی هوشمند با Gemini
  static Future<String> generateAd(String name, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate-ad'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'productName': name,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['adText'] ?? '';
    } else {
      throw Exception('خطا در ساخت آگهی');
    }
  }
}
