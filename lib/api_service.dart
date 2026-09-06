import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://bazarek.onrender.com/api';
  static String? _token;
  static Map<String, String> _headers({bool auth = false}) => {
    'Content-Type': 'application/json',
    if (auth && _token != null) 'Authorization': 'Bearer $_token',
  };
  static void setToken(String? token) => _token = token;
  static String? get currentUserId { try { if (_token == null) return null; final parts=_token!.split('.'); if(parts.length<2)return null; final payload=utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))); final d=jsonDecode(payload); return d['sub']?.toString(); } catch (_) { return null; } }

  static Future<String> adminLogin(String email, String password) async {
    final r = await http.post(Uri.parse('$baseUrl/admin/login'), headers: _headers(), body: jsonEncode({'email': email, 'password': password}));
    final data = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(data['error'] ?? 'ورود مدیریت ناموفق بود.');
    return data['token'].toString();
  }

  static Map<String,String> _adminHeaders(String token) => {'Content-Type':'application/json','Authorization':'Bearer $token'};
  static Future<Map<String,dynamic>> adminStats(String token) async { final r=await http.get(Uri.parse('$baseUrl/admin/stats'),headers:_adminHeaders(token)); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت آمار مدیریت.'); return Map<String,dynamic>.from(d); }
  static Future<List<Map<String,dynamic>>> adminProducts(String token) async { final r=await http.get(Uri.parse('$baseUrl/admin/products'),headers:_adminHeaders(token)); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت آگهی‌ها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e))); }
  static Future<List<Map<String,dynamic>>> adminUsers(String token) async { final r=await http.get(Uri.parse('$baseUrl/admin/users'),headers:_adminHeaders(token)); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت کاربران.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e))); }
  static Future<void> adminSetProductStatus(String token,String id,bool active) async { final r=await http.patch(Uri.parse('$baseUrl/admin/products/$id/status'),headers:_adminHeaders(token),body:jsonEncode({'is_active':active})); if(r.statusCode!=200)throw Exception(jsonDecode(r.body)['error']??'خطا در تغییر وضعیت آگهی.'); }
  static Future<void> adminDeleteProduct(String token,String id) async { final r=await http.delete(Uri.parse('$baseUrl/admin/products/$id'),headers:_adminHeaders(token)); if(r.statusCode!=200)throw Exception(jsonDecode(r.body)['error']??'خطا در حذف آگهی.'); }
  static Future<void> adminPromoteProduct(String token,String id,{int featureDays=0,int pinDays=0}) async { final r=await http.patch(Uri.parse('$baseUrl/admin/products/$id/promotion'),headers:_adminHeaders(token),body:jsonEncode({'feature_days':featureDays,'pin_days':pinDays})); if(r.statusCode!=200)throw Exception(jsonDecode(r.body)['error']??'خطا در ویژه/پین کردن آگهی.'); }
  static Future<void> adminBlockUser(String token,String id,{required bool blocked,int durationDays=0,String reason=''}) async { final r=await http.patch(Uri.parse('$baseUrl/admin/users/$id/block'),headers:_adminHeaders(token),body:jsonEncode({'blocked':blocked,'duration_days':durationDays,'reason':reason})); if(r.statusCode!=200)throw Exception(jsonDecode(r.body)['error']??'خطا در تغییر وضعیت کاربر.'); }

  static Future<List<Map<String,dynamic>>> getListings({String q='',String category=''}) async { final uri=Uri.parse('$baseUrl/listings').replace(queryParameters:{if(q.trim().isNotEmpty)'q':q.trim(),if(category.trim().isNotEmpty)'category':category.trim()}); final r=await http.get(uri,headers:_headers()); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت آگهی‌ها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e))); }
  static Future<String> login(String email,String password) async { final r=await http.post(Uri.parse('$baseUrl/auth/login'),headers:_headers(),body:jsonEncode({'email':email,'password':password})); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'ورود ناموفق بود.'); _token=d['token']; return _token!; }
  static Future<Map<String,dynamic>> register({required String email,required String password,String fullName='',String shopName='',String phone=''}) async { final r=await http.post(Uri.parse('$baseUrl/auth/register'),headers:_headers(),body:jsonEncode({'email':email,'password':password,'full_name':fullName,'shop_name':shopName,'phone':phone})); final d=jsonDecode(r.body); if(r.statusCode!=201&&r.statusCode!=200)throw Exception(d['error']??'ثبت‌نام ناموفق بود.'); if(d['token']!=null)_token=d['token']; return Map<String,dynamic>.from(d); }
  static Future<Map<String,dynamic>> getProfile() async { final r=await http.get(Uri.parse('$baseUrl/me'),headers:_headers(auth:true)); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت پروفایل.'); return Map<String,dynamic>.from(d); }
  static Future<List<Map<String,dynamic>>> getProducts() async { final r=await http.get(Uri.parse('$baseUrl/products'),headers:_headers(auth:true)); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت محصولات.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e))); }
  static Future<Map<String,dynamic>> addProduct(Map<String,dynamic> product) async { final r=await http.post(Uri.parse('$baseUrl/products'),headers:_headers(auth:true),body:jsonEncode(product)); final d=jsonDecode(r.body); if(r.statusCode!=201)throw Exception(d['error']??'خطا در ثبت آگهی.'); return Map<String,dynamic>.from(d); }
  static Future<List<String>> uploadImages(List<Uint8List> images,List<String> names) async { if(images.length!=names.length)throw Exception('اطلاعات عکس کامل نیست.'); final req=http.MultipartRequest('POST',Uri.parse('$baseUrl/upload-images')); if(_token!=null)req.headers['Authorization']='Bearer $_token'; for(var i=0;i<images.length;i++){req.files.add(http.MultipartFile.fromBytes('images',images[i],filename:names[i]));} final response=await req.send(); final body=await response.stream.bytesToString(); final d=jsonDecode(body); if(response.statusCode!=201)throw Exception(d['error']??'خطا در آپلود عکس‌ها.'); return List<String>.from(d['urls']??[]); }
  static Future<void> deleteProduct(String id) async { final r=await http.delete(Uri.parse('$baseUrl/products/$id'),headers:_headers(auth:true)); if(r.statusCode!=200)throw Exception(jsonDecode(r.body)['error']??'خطا در حذف آگهی.'); }

  static Future<Map<String,dynamic>> startConversation(String listingId) async {
    final r=await http.post(Uri.parse('$baseUrl/conversations'),headers:_headers(auth:true),body:jsonEncode({'listing_id':listingId}));
    final d=jsonDecode(r.body); if(r.statusCode!=200&&r.statusCode!=201)throw Exception(d['error']??'خطا در شروع گفتگو.'); return Map<String,dynamic>.from(d);
  }
  static Future<List<Map<String,dynamic>>> getConversations() async {
    final r=await http.get(Uri.parse('$baseUrl/conversations'),headers:_headers(auth:true)); final d=jsonDecode(r.body);
    if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت گفتگوها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e)));
  }
  static Future<List<Map<String,dynamic>>> getMessages(String conversationId) async {
    final r=await http.get(Uri.parse('$baseUrl/conversations/$conversationId/messages'),headers:_headers(auth:true)); final d=jsonDecode(r.body);
    if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت پیام‌ها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e)));
  }
  static Future<Map<String,dynamic>> sendMessage(String conversationId,String message) async {
    final r=await http.post(Uri.parse('$baseUrl/conversations/$conversationId/messages'),headers:_headers(auth:true),body:jsonEncode({'message':message})); final d=jsonDecode(r.body);
    if(r.statusCode!=201)throw Exception(d['error']??'خطا در ارسال پیام.'); return Map<String,dynamic>.from(d);
  }

  static Future<String> generateAd(String productName,String description,{String language='fa'}) async { final r=await http.post(Uri.parse('$baseUrl/generate-ad'),headers:_headers(auth:true),body:jsonEncode({'productName':productName,'description':description,'language':language})); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در تولید آگهی.'); return d['adText']; }
}
