import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static dynamic _json(http.Response r) {
    try { return jsonDecode(r.body); }
    catch (_) {
      final preview = r.body.length > 180 ? r.body.substring(0, 180) : r.body;
      throw Exception('پاسخ نامعتبر از سرور (${r.statusCode}): $preview');
    }
  }
  static Future<http.Response> _send(http.Response r) async => r;
  static const String baseUrl = 'https://bazarek.onrender.com/api';
  static String? _token;
  static String? _refreshToken;
  static Map<String, String> _headers({bool auth = false}) => {
    'Content-Type': 'application/json',
    if (auth && _token != null) 'Authorization': 'Bearer $_token',
  };
  static void setToken(String? token) => _token = token;
  static void setRefreshToken(String? token) => _refreshToken = token;
  static String? get currentToken => _token;
  static String? get refreshToken => _refreshToken;
  static String? get currentUserId { try { if (_token == null) return null; final parts=_token!.split('.'); if(parts.length<2)return null; final payload=utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))); final d=jsonDecode(payload); return d['sub']?.toString(); } catch (_) { return null; } }

  static Future<String> adminLogin(String email, String password) async {
    final r = await http.post(Uri.parse('$baseUrl/admin/login'), headers: _headers(), body: jsonEncode({'email': email, 'password': password}));
    final data = _json(r);
    if (r.statusCode != 200) throw Exception(data['error'] ?? 'ورود مدیریت ناموفق بود.');
    return data['token'].toString();
  }

  static Map<String,String> _adminHeaders(String token) => {'Content-Type':'application/json','Authorization':'Bearer $token'};
  static Future<Map<String,dynamic>> adminStats(String token) async { final r=await http.get(Uri.parse('$baseUrl/admin/stats'),headers:_adminHeaders(token)); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت آمار مدیریت.'); return Map<String,dynamic>.from(d); }
  static Future<List<Map<String,dynamic>>> adminProducts(String token) async { final r=await http.get(Uri.parse('$baseUrl/admin/products'),headers:_adminHeaders(token)); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت آگهی‌ها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e))); }
  static Future<List<Map<String,dynamic>>> adminUsers(String token) async { final r=await http.get(Uri.parse('$baseUrl/admin/users'),headers:_adminHeaders(token)); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت کاربران.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e))); }
  static Future<void> adminSetProductStatus(String token,String id,bool active) async { final r=await http.patch(Uri.parse('$baseUrl/admin/products/$id/status'),headers:_adminHeaders(token),body:jsonEncode({'is_active':active})); if(r.statusCode!=200)throw Exception(_json(r)['error']??'خطا در تغییر وضعیت آگهی.'); }
  static Future<void> adminDeleteProduct(String token,String id) async { final r=await http.delete(Uri.parse('$baseUrl/admin/products/$id'),headers:_adminHeaders(token)); if(r.statusCode!=200)throw Exception(_json(r)['error']??'خطا در حذف آگهی.'); }
  static Future<void> adminPromoteProduct(String token,String id,{int featureDays=0,int pinDays=0}) async { final r=await http.patch(Uri.parse('$baseUrl/admin/products/$id/promotion'),headers:_adminHeaders(token),body:jsonEncode({'feature_days':featureDays,'pin_days':pinDays})); if(r.statusCode!=200)throw Exception(_json(r)['error']??'خطا در ویژه/پین کردن آگهی.'); }
  static Future<void> adminBlockUser(String token,String id,{required bool blocked,int durationDays=0,String reason=''}) async { final r=await http.patch(Uri.parse('$baseUrl/admin/users/$id/block'),headers:_adminHeaders(token),body:jsonEncode({'blocked':blocked,'duration_days':durationDays,'reason':reason})); if(r.statusCode!=200)throw Exception(_json(r)['error']??'خطا در تغییر وضعیت کاربر.'); }

  static Future<List<Map<String,dynamic>>> getListings({String q='',String category='',String province=''}) async { final uri=Uri.parse('$baseUrl/listings').replace(queryParameters:{if(q.trim().isNotEmpty)'q':q.trim(),if(category.trim().isNotEmpty)'category':category.trim(),if(province.trim().isNotEmpty&&province!='__all__')'province':province.trim()}); final r=await http.get(uri,headers:_headers()); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت آگهی‌ها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e))); }
  static Future<String> login(String identifier,String password) async { final r=await http.post(Uri.parse('$baseUrl/auth/login'),headers:_headers(),body:jsonEncode({'identifier':identifier,'password':password})); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'ورود ناموفق بود.'); _token=d['token']?.toString(); _refreshToken=d['refresh_token']?.toString(); if(_token==null||_token!.isEmpty)throw Exception('ورود ناموفق بود.'); return _token!; }
  static Future<Map<String,dynamic>> register({String phone='',String email='',required String password,String fullName='',String shopName=''}) async { final r=await http.post(Uri.parse('$baseUrl/auth/register'),headers:_headers(),body:jsonEncode({'phone':phone,'email':email,'password':password,'full_name':fullName,'shop_name':shopName})); final d=_json(r); if(r.statusCode!=201&&r.statusCode!=200)throw Exception(d['error']??'ثبت‌نام ناموفق بود.'); if(d['token']!=null)_token=d['token'].toString(); if(d['refresh_token']!=null)_refreshToken=d['refresh_token'].toString(); return Map<String,dynamic>.from(d); }
  static Future<bool> refreshSession(String refreshToken) async { try { final r=await http.post(Uri.parse('$baseUrl/auth/refresh'),headers:_headers(),body:jsonEncode({'refresh_token':refreshToken})); final d=_json(r); if(r.statusCode!=200||d is! Map||d['token']==null)return false; _token=d['token'].toString(); _refreshToken=(d['refresh_token']??refreshToken).toString(); return true; } catch (_) { return false; } }
  static void clearSession(){_token=null;_refreshToken=null;}
  static Future<Map<String,dynamic>> getProfile() async { final r=await http.get(Uri.parse('$baseUrl/me'),headers:_headers(auth:true)); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت پروفایل.'); return Map<String,dynamic>.from(d); }
  static Future<List<Map<String,dynamic>>> getProducts() async { final r=await http.get(Uri.parse('$baseUrl/products'),headers:_headers(auth:true)); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت محصولات.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e))); }
  static Future<Map<String,dynamic>> addProduct(Map<String,dynamic> product) async { final r=await http.post(Uri.parse('$baseUrl/products'),headers:_headers(auth:true),body:jsonEncode(product)); final d=jsonDecode(r.body); if(r.statusCode!=201)throw Exception(d['error']??'خطا در ثبت آگهی.'); return Map<String,dynamic>.from(d); }
  static Future<List<String>> uploadImages(List<Uint8List> images,List<String> names) async {
    if(images.length!=names.length)throw Exception('اطلاعات عکس کامل نیست.');
    if(images.isEmpty)throw Exception('حداقل یک عکس انتخاب کنید.');

    Future<http.StreamedResponse> send() async {
      final req=http.MultipartRequest('POST',Uri.parse('$baseUrl/upload-images'));
      req.headers['Accept']='application/json';
      if(_token!=null&&_token!.isNotEmpty)req.headers['Authorization']='Bearer $_token';
      String mimeFor(String name) {
        final ext = name.toLowerCase().split('.').last;
        switch (ext) {
          case 'png': return 'image/png';
          case 'webp': return 'image/webp';
          case 'gif': return 'image/gif';
          case 'heic': return 'image/heic';
          case 'heif': return 'image/heif';
          case 'jpg':
          case 'jpeg':
          default: return 'image/jpeg';
        }
      }
      for(var i=0;i<images.length;i++){
        final mime = mimeFor(names[i]);
        final parts = mime.split('/');
        req.files.add(http.MultipartFile.fromBytes(
          'images',
          images[i],
          filename: names[i],
          contentType: MediaType(parts[0], parts[1]),
        ));
      }
      return req.send().timeout(const Duration(seconds:90));
    }

    var response=await send();
    var body=await response.stream.bytesToString();

    // If the access token expired, refresh it once and retry the multipart upload.
    if(response.statusCode==401 && _refreshToken!=null && _refreshToken!.isNotEmpty){
      final refreshed=await refreshSession(_refreshToken!);
      if(refreshed){
        response=await send();
        body=await response.stream.bytesToString();
      }
    }

    dynamic d;
    try { d=jsonDecode(body); } catch (_) {
      final preview=body.length>220?body.substring(0,220):body;
      throw Exception('پاسخ نامعتبر از سرور (${response.statusCode}): $preview');
    }
    if(response.statusCode!=201){
      throw Exception(d is Map ? (d['error']??'خطا در آپلود عکس‌ها.') : 'خطا در آپلود عکس‌ها.');
    }
    final urls=d is Map ? d['urls'] : null;
    if(urls is! List || urls.isEmpty)throw Exception('سرور عکس‌ها را آپلود نکرد.');
    return List<String>.from(urls.map((x)=>x.toString()));
  }
  static Future<void> incrementListingView(String id) async { try { await http.post(Uri.parse('$baseUrl/listings/$id/view')); } catch (_) {} }
  static Future<bool> toggleFavorite(String id) async { final r=await http.post(Uri.parse('$baseUrl/favorites/$id'),headers:_headers(auth:true)); final d=_json(r); if(r.statusCode!=200&&r.statusCode!=201)throw Exception(d['error']??'خطا در علاقه‌مندی.'); return d['favorite']==true; }
  static Future<List<Map<String,dynamic>>> getFavorites() async { final r=await http.get(Uri.parse('$baseUrl/favorites'),headers:_headers(auth:true)); final d=_json(r); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت علاقه‌مندی‌ها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e))); }
  static Future<String> getServerVersion() async { final r=await http.get(Uri.parse('$baseUrl/version')); final d=_json(r); if(r.statusCode!=200)throw Exception('سرور بازارک به‌روز نیست.'); return (d['version']??'').toString(); }

  static Future<void> deleteProduct(String id) async { final r=await http.delete(Uri.parse('$baseUrl/products/$id'),headers:_headers(auth:true)); if(r.statusCode!=200)throw Exception(_json(r)['error']??'خطا در حذف آگهی.'); }

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

  static Future<Map<String,dynamic>> updateProfile({String fullName='',String shopName='',String phone='',String city=''}) async {
    final r=await http.patch(Uri.parse('$baseUrl/me'),headers:_headers(auth:true),body:jsonEncode({'full_name':fullName,'shop_name':shopName,'phone':phone,'city':city}));
    final d=_json(r); if(r.statusCode!=200)throw Exception(d['error']??'خطا در ذخیره پروفایل.'); return Map<String,dynamic>.from(d);
  }
  static Future<String> uploadAvatar(Uint8List bytes,String name) async {
    final req=http.MultipartRequest('POST',Uri.parse('$baseUrl/profile/avatar'));
    if(_token!=null)req.headers['Authorization']='Bearer $_token';
    req.files.add(http.MultipartFile.fromBytes('avatar',bytes,filename:name));
    final response=await req.send(); final body=await response.stream.bytesToString(); dynamic d;
    try{d=jsonDecode(body);}catch(_){throw Exception('پاسخ نامعتبر از سرور (${response.statusCode}).');}
    if(response.statusCode!=201)throw Exception(d is Map?(d['error']??'خطا در آپلود تصویر پروفایل.'):'خطا در آپلود تصویر پروفایل.');
    return (d['url']??'').toString();
  }
  static Future<List<Map<String,dynamic>>> getMyWarnings() async {
    final r=await http.get(Uri.parse('$baseUrl/me/warnings'),headers:_headers(auth:true)); final d=_json(r);
    if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت هشدارها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e)));
  }
  static Future<void> adminWarnUser(String token,String id,String message) async {
    final r=await http.post(Uri.parse('$baseUrl/admin/users/$id/warnings'),headers:_adminHeaders(token),body:jsonEncode({'message':message})); final d=_json(r);
    if(r.statusCode!=201)throw Exception(d['error']??'خطا در ثبت هشدار.');
  }
  static Future<List<Map<String,dynamic>>> adminWarnings(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/admin/warnings'),headers:_adminHeaders(token)); final d=_json(r);
    if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت هشدارها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e)));
  }
  static Future<void> reportListing(String listingId,String reason) async {
    final r=await http.post(Uri.parse('$baseUrl/reports'),headers:_headers(auth:true),body:jsonEncode({'listing_id':listingId,'reason':reason})); final d=_json(r);
    if(r.statusCode!=201)throw Exception(d['error']??'خطا در ثبت گزارش.');
  }
  static Future<List<Map<String,dynamic>>> adminReports(String token) async {
    final r=await http.get(Uri.parse('$baseUrl/admin/reports'),headers:_adminHeaders(token)); final d=_json(r);
    if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت گزارش‌ها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e)));
  }
  static Future<void> adminSetReportStatus(String token,String id,String status) async {
    final r=await http.patch(Uri.parse('$baseUrl/admin/reports/$id'),headers:_adminHeaders(token),body:jsonEncode({'status':status})); final d=_json(r);
    if(r.statusCode!=200)throw Exception(d['error']??'خطا در تغییر گزارش.');
  }

  static Future<Map<String,dynamic>> paymentInfo() async { final r=await http.get(Uri.parse('$baseUrl/payment-info'),headers:_headers(auth:true)); final d=_json(r); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت اطلاعات پرداخت.'); return Map<String,dynamic>.from(d); }
  static Future<Map<String,dynamic>> getWallet() async { final r=await http.get(Uri.parse('$baseUrl/wallet'),headers:_headers(auth:true)); final d=_json(r); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت کیف پول.'); return Map<String,dynamic>.from(d); }
  static Future<List<Map<String,dynamic>>> monetizationPackages() async { final r=await http.get(Uri.parse('$baseUrl/monetization/packages'),headers:_headers(auth:true)); final d=_json(r); if(r.statusCode!=200)throw Exception(d['error']??'خطا در دریافت بسته‌ها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e))); }
  static Future<Map<String,dynamic>> buyPromotion({required String listingId,required String packageId,String paymentMethod='wallet',String paymentReference=''}) async { final r=await http.post(Uri.parse('$baseUrl/promotions/orders'),headers:_headers(auth:true),body:jsonEncode({'listing_id':listingId,'package_id':packageId,'payment_method':paymentMethod,'payment_reference':paymentReference})); final d=_json(r); if(r.statusCode!=201)throw Exception(d['error']??'خطا در خرید ارتقا.'); return Map<String,dynamic>.from(d); }
  static Future<List<Map<String,dynamic>>> promotionOrders() async { final r=await http.get(Uri.parse('$baseUrl/promotions/orders'),headers:_headers(auth:true)); final d=_json(r); if(r.statusCode!=200)throw Exception(d['error']??'خطا در سفارش‌ها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e))); }
  static Future<List<Map<String,dynamic>>> subscriptions() async { final r=await http.get(Uri.parse('$baseUrl/subscriptions'),headers:_headers(auth:true)); final d=_json(r); if(r.statusCode!=200)throw Exception(d['error']??'خطا در اشتراک‌ها.'); return List<Map<String,dynamic>>.from(d.map((e)=>Map<String,dynamic>.from(e))); }
  static Future<Map<String,dynamic>> buySubscription(String plan,{String paymentReference=''}) async { final r=await http.post(Uri.parse('$baseUrl/subscriptions'),headers:_headers(auth:true),body:jsonEncode({'plan':plan,'payment_reference':paymentReference})); final d=_json(r); if(r.statusCode!=201)throw Exception(d['error']??'خطا در فعال‌سازی اشتراک.'); return Map<String,dynamic>.from(d); }
  static Future<void> adminSetSubscription(String token,String id,String status) async { final r=await http.patch(Uri.parse('$baseUrl/admin/subscriptions/$id'),headers:_adminHeaders(token),body:jsonEncode({'status':status})); final d=_json(r); if(r.statusCode!=200)throw Exception(d['error']??'خطا در تغییر وضعیت اشتراک.'); }
  static Future<Map<String,dynamic>> adminMonetization(String token) async { final r=await http.get(Uri.parse('$baseUrl/admin/monetization'),headers:_adminHeaders(token)); final d=_json(r); if(r.statusCode!=200)throw Exception(d['error']??'خطا در آمار درآمد.'); return Map<String,dynamic>.from(d); }
  static Future<void> adminCreditWallet(String token,String userId,int amount,{String description=''}) async { final r=await http.post(Uri.parse('$baseUrl/admin/wallets/$userId/credit'),headers:_adminHeaders(token),body:jsonEncode({'amount_afn':amount,'description':description})); if(r.statusCode!=201)throw Exception(_json(r)['error']??'خطا در شارژ کیف پول.'); }
  static Future<void> adminSetPromotionOrder(String token,String id,String status) async { final r=await http.patch(Uri.parse('$baseUrl/admin/promotions/orders/$id'),headers:_adminHeaders(token),body:jsonEncode({'status':status})); if(r.statusCode!=200)throw Exception(_json(r)['error']??'خطا در تغییر سفارش.'); }
  static Future<String> generateAd(String productName,String description,{String language='fa'}) async { final r=await http.post(Uri.parse('$baseUrl/generate-ad'),headers:_headers(auth:true),body:jsonEncode({'productName':productName,'description':description,'language':language})); final d=jsonDecode(r.body); if(r.statusCode!=200)throw Exception(d['error']??'خطا در تولید آگهی.'); return d['adText']; }
}
