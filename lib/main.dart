import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('fa'));

String tr(String dari) {
  if (appLocale.value.languageCode != 'ps') return dari;
  const ps = <String,String>{
    'همه':'ټول','موبایل':'موبایل','موتر':'موټر','املاک':'املاک','لوازم برقی':'برقي وسایل','خانه':'کور','لباس':'کالي','خدمات':'خدمتونه','کار':'کار','حیوانات':'څاروي',
    'پیام‌ها':'پیغامونه','حساب من':'زما حساب','ثبت آگهی':'اعلان ثبتول','بازار افغانستان، ساده و حرفه‌ای':'د افغانستان بازار، ساده او مسلکي','چه چیزی می‌خواهید پیدا کنید؟':'څه شی لټوئ؟',
    'آگهی‌ای پیدا نشد.':'هیڅ اعلان پیدا نه شو.','جستجو یا دسته‌بندی را تغییر دهید.':'لټون یا کټګوري بدله کړئ.','گزارش آگهی':'اعلان راپور کړئ','قیمت':'بیه','دسته‌بندی':'کټګوري','توضیحات':'توضیحات','چت با فروشنده':'له پلورونکي سره خبرې','افزودن به علاقه‌مندی‌ها':'خوښو ته اضافه کول','گزارش این آگهی':'دا اعلان راپور کړئ',
    'ورود به بازارک':'بازارک ته ننوتل','رمز عبور':'پټ نوم','ورود':'ننوتل','حساب ندارید؟ ثبت‌نام کنید':'حساب نه لرئ؟ نوم‌لیکنه وکړئ','ورود مدیریت':'مدیریت ته ننوتل','ساخت حساب':'حساب جوړول','نام شما':'ستاسو نوم','نام دکان / کسب‌وکار':'د دوکان / کاروبار نوم','شماره تماس':'د اړیکې شمېره','ساخت حساب و ورود':'حساب جوړول او ننوتل',
    'پروفایل من':'زما پروفایل','نام و نام خانوادگی':'نوم او تخلص','شماره تلفن':'د تلیفون شمېره','شهر / ولایت':'ښار / ولایت','ذخیره پروفایل':'پروفایل خوندي کول','خروج از حساب':'له حسابه وتل','آگهی‌های من':'زما اعلانونه','موجودی':'موجودي','کاربران':'کاروونکي','آگهی‌ها':'اعلانونه',
    'زبان برنامه':'د پروګرام ژبه','انتخاب زبان':'ژبه وټاکئ','زبان با موفقیت تغییر کرد.':'ژبه په بریالیتوب بدله شوه.'
  };
  return ps[dari] ?? dari;
}

Future<void> chooseLanguage(BuildContext context) async {
  final code = await showDialog<String>(context: context, builder: (dialogContext) => SimpleDialog(
    title: Text(tr('انتخاب زبان')),
    children: [
      SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, 'fa'), child: const Text('دری')),
      SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, 'ps'), child: const Text('پښتو')),
    ],
  ));
  if (code == null) return;
  appLocale.value = Locale(code);
  final p = await SharedPreferences.getInstance();
  await p.setString('bazarek_language', code);
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('زبان با موفقیت تغییر کرد.'))));
}

void main() => runApp(const BazarekApp());

class BazarekApp extends StatelessWidget {
  const BazarekApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale>(
    valueListenable: appLocale,
    builder: (_, locale, __) => MaterialApp(
      title: 'بازارک', debugShowCheckedModeBanner: false, locale: locale,
      supportedLocales: const [Locale('fa'), Locale('ps')],
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal, fontFamily: 'Roboto'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox()),
      home: const StartupScreen(),
    ),
  );
}

class StartupScreen extends StatefulWidget { const StartupScreen({super.key}); @override State<StartupScreen> createState()=>_StartupScreenState(); }
class _StartupScreenState extends State<StartupScreen> {
  @override void initState(){super.initState();_start();}
  Future<void> _start() async {
    final p = await SharedPreferences.getInstance();
    final savedLanguage = p.getString('bazarek_language');
    if (savedLanguage == 'fa' || savedLanguage == 'ps') appLocale.value = Locale(savedLanguage!);
    final token = p.getString('bazarek_token');
    final refresh = p.getString('bazarek_refresh_token');
    if (token != null && token.isNotEmpty) {
      ApiService.setToken(token);
      ApiService.setRefreshToken(refresh);
      try {
        await ApiService.getProfile();
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        return;
      } catch (_) {
        // Access tokens expire. Try the saved refresh token before asking the user to log in again.
        if (refresh != null && refresh.isNotEmpty && await ApiService.refreshSession(refresh)) {
          await p.setString('bazarek_token', ApiService.currentToken!);
          final newRefresh = ApiService.refreshToken;
          if (newRefresh != null && newRefresh.isNotEmpty) await p.setString('bazarek_refresh_token', newRefresh);
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          return;
        }
        await p.remove('bazarek_token');
        await p.remove('bazarek_refresh_token');
        ApiService.clearSession();
      }
    }
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }
  @override Widget build(BuildContext context)=>const Scaffold(body:Center(child:CircularProgressIndicator()));
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen>{
  final search=TextEditingController(); List<Map<String,dynamic>> listings=[]; bool loading=true; String category='';
  final cats=['همه','موبایل','موتر','املاک','لوازم برقی','خانه','لباس','خدمات','کار','حیوانات'];
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{if(mounted)setState(()=>loading=true);try{final x=await ApiService.getListings(q:search.text,category:category=='همه'?'':category);if(mounted)setState(()=>listings=x);}catch(e){if(mounted)_msg(e);}finally{if(mounted)setState(()=>loading=false);}}
  void _msg(Object e)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));
  Future<void> _openLogin()async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>const LoginScreen()));if(mounted)_load();}
  Future<void> _openBoost()async{final p=await SharedPreferences.getInstance();if(p.getString('bazarek_token')==null){await _openLogin();return;}if(!mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>const MonetizationScreen()));}
  Future<void> _openAccount()async{final p=await SharedPreferences.getInstance();if(p.getString('bazarek_token')==null){await _openLogin();return;}if(!mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>const DashboardScreen()));}
  Future<void> _openMessages()async{final p=await SharedPreferences.getInstance();if(p.getString('bazarek_token')==null){await _openLogin();return;}if(!mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>const ConversationsScreen()));}
  Future<void> _openChat(Map<String,dynamic> listing)async{final p=await SharedPreferences.getInstance();if(p.getString('bazarek_token')==null){await _openLogin();return;}try{final conv=await ApiService.startConversation(listing['id'].toString());if(!mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>ChatScreen(conversation:conv,listingTitle:(listing['title']??'آگهی').toString())));}catch(e){if(mounted)_msg(e);}}
  Future<void> _post()async{final p=await SharedPreferences.getInstance();if(p.getString('bazarek_token')==null){await _openLogin();return;}if(!mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>const DashboardScreen()));}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('بازارک',style:TextStyle(fontWeight:FontWeight.bold)),actions:[IconButton(onPressed:()=>chooseLanguage(context),tooltip:tr('زبان برنامه'),icon:const Icon(Icons.language)),IconButton(onPressed:_openMessages,tooltip:tr('پیام‌ها'),icon:const Icon(Icons.chat_outlined)),IconButton(onPressed:_openAccount,tooltip:tr('حساب من'),icon:const Icon(Icons.person_outline))]),
    floatingActionButton:FloatingActionButton.extended(onPressed:_post,icon:const Icon(Icons.add),label:const Text('ثبت آگهی')),
    body:RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
      Text(tr('بازار افغانستان، ساده و حرفه‌ای'),style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)),
      const SizedBox(height:12),TextField(controller:search,onSubmitted:(_)=>_load(),textInputAction:TextInputAction.search,decoration:InputDecoration(hintText:tr('چه چیزی می‌خواهید پیدا کنید؟'),prefixIcon:const Icon(Icons.search),suffixIcon:IconButton(onPressed:_load,icon:const Icon(Icons.tune)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(18)))),
      const SizedBox(height:12),SizedBox(height:44,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:cats.length,itemBuilder:(_,i)=>ChoiceChip(label:Text(tr(cats[i])),selected:(category.isEmpty&&i==0)||category==cats[i],onSelected:(_){setState(()=>category=cats[i]);_load();}),separatorBuilder:(_,__)=>const SizedBox(width:8))),
      const SizedBox(height:12),Card(child:InkWell(onTap:_openBoost,child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[CircleAvatar(child:const Icon(Icons.rocket_launch)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('🚀 بازارک BOOST',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)),SizedBox(height:3),Text('ویژه و پین آگهی برای دیده‌شدن بیشتر',style:TextStyle(fontSize:13))])),const Icon(Icons.chevron_left)])))),const SizedBox(height:18),if(loading)const Center(child:Padding(padding:EdgeInsets.all(30),child:CircularProgressIndicator())) else if(listings.isEmpty)Card(child:Padding(padding:const EdgeInsets.all(28),child:Column(children:[const Icon(Icons.search_off,size:46),const SizedBox(height:8),Text(tr('آگهی‌ای پیدا نشد.')),Text(tr('جستجو یا دسته‌بندی را تغییر دهید.'))]))) else ...listings.map((p)=>ListingCard(product:p,onTap:()=>_details(p)))
    ])));
  Future<void> _report(Map<String,dynamic> p) async {
    final reason=await showDialog<String>(context:context,builder:(_)=>SimpleDialog(title:const Text('گزارش آگهی'),children:[
      for(final x in ['کلاهبرداری یا تقلب','کالای ممنوع یا غیرقانونی','محتوای توهین‌آمیز','آگهی تکراری یا جعلی','اطلاعات نادرست']) SimpleDialogOption(onPressed:()=>Navigator.pop(context,x),child:Text(x)),
    ]));
    if(reason==null)return;
    final prefs=await SharedPreferences.getInstance();
    if(prefs.getString('bazarek_token')==null){await _openLogin();return;}
    try{await ApiService.reportListing(p['id'].toString(),reason);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('گزارش شما ثبت شد و توسط مدیریت بررسی می‌شود.')));}catch(e){if(mounted)_msg(e);}
  }

  void _details(Map<String,dynamic> p){ ApiService.incrementListingView(p['id'].toString()); showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>Directionality(textDirection:TextDirection.rtl,child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(20,20,20,32),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Stack(children:[ImageGallery(images:_imageUrls(p['image_url']),height:230),if(p['is_pinned']==true||p['is_featured']==true)Positioned(top:12,left:12,child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),decoration:BoxDecoration(color:Theme.of(context).colorScheme.primary.withOpacity(.92),borderRadius:BorderRadius.circular(12)),child:Text(p['is_featured']==true&&p['is_pinned']==true?'🚀 BOOST بازارک':p['is_featured']==true?'⭐ بازارک ویژه':'📌 بازارک پین',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold))))]),const SizedBox(height:14),Text(p['title']??'',style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:12),
    Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(14)),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('قیمت',style:TextStyle(fontSize:16)),Text(_money(p['price']),style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold))])),
    if((p['category']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:Text('دسته‌بندی: ${p['category']}')),
    if((p['location_text']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text('📍 محل: ${p['location_text']}')),
    if(p['is_negotiable']==true)const Padding(padding:EdgeInsets.only(top:8),child:Text('🤝 قیمت قابل مذاکره است.')),
    Padding(padding:const EdgeInsets.only(top:8),child:Text('👁 ${p['views_count']??0} بازدید')),
    const SizedBox(height:12),
    Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.store_outlined)),title:Text((p['seller_name']??'فروشنده بازارک').toString()),subtitle:(p['seller_phone']??'').toString().isNotEmpty?Text('شماره تماس: ${p['seller_phone']}'):const Text('فروشنده در بازارک'))),
    const SizedBox(height:12),const Text('توضیحات',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text((p['description']??'توضیحی ثبت نشده است.').toString(),style:const TextStyle(height:1.6)),
    if(p['allow_chat']!=false) const SizedBox(height:18),
    if(p['allow_chat']!=false) SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>_openChat(p),icon:const Icon(Icons.chat_bubble_outline),label:const Text('چت با فروشنده'))),
    const SizedBox(height:8),
    OutlinedButton.icon(onPressed:() async { final prefs=await SharedPreferences.getInstance(); if(prefs.getString('bazarek_token')==null){await _openLogin();return;} try{final fav=await ApiService.toggleFavorite(p['id'].toString()); if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(fav?'به علاقه‌مندی‌ها اضافه شد ❤️':'از علاقه‌مندی‌ها حذف شد.')));}catch(e){if(mounted)_msg(e);} },icon:const Icon(Icons.favorite_border),label:const Text('افزودن به علاقه‌مندی‌ها')),
    const SizedBox(height:8),
    OutlinedButton.icon(onPressed:()=>_report(p),icon:const Icon(Icons.flag_outlined),label:const Text('گزارش این آگهی')),
  ])))); }
}

List<String> _imageUrls(dynamic raw){
  final s=(raw??'').toString().trim(); if(s.isEmpty)return [];
  try{final d=jsonDecode(s);if(d is List)return d.map((e)=>e.toString()).where((e)=>e.isNotEmpty).toList();}catch(_){ }
  return [s];
}
String _money(dynamic value){final n=(value is num)?value:double.tryParse('$value')??0;return '${n.toStringAsFixed(n%1==0?0:2)} افغانی';}

class ImageGallery extends StatelessWidget {
  final List<String> images;
  final double height;
  const ImageGallery({super.key, required this.images, this.height = 180});
  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.image_outlined, size: 48),
      );
    }
    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (_, i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                images[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 42),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
class ListingCard extends StatelessWidget{final Map<String,dynamic> product;final VoidCallback onTap;const ListingCard({super.key,required this.product,required this.onTap});@override Widget build(BuildContext context){final images=_imageUrls(product['image_url']);final pinned=product['is_pinned']==true;final featured=product['is_featured']==true;return Card(clipBehavior:Clip.antiAlias,margin:const EdgeInsets.only(bottom:10),child:InkWell(onTap:onTap,child:Padding(padding:const EdgeInsets.all(10),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Stack(children:[ClipRRect(borderRadius:BorderRadius.circular(12),child:images.isNotEmpty?Image.network(images.first,width:86,height:86,fit:BoxFit.cover,errorBuilder:(_,__,___)=>_placeholder(context)):_placeholder(context)),if(pinned||featured)Positioned(top:5,left:5,child:_promoWatermark(context,pinned,featured))]),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[if(pinned)const Icon(Icons.push_pin,size:17),if(featured)const Icon(Icons.star,size:17),const SizedBox(width:3),Expanded(child:Text((product['title']??'').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700)))]),const SizedBox(height:8),Text((product['category']??'عمومی').toString()),const SizedBox(height:8),Text(_money(product['price']),style:TextStyle(fontSize:17,fontWeight:FontWeight.bold,color:Theme.of(context).colorScheme.primary))])),const Icon(Icons.chevron_left)]))));}Widget _promoWatermark(BuildContext context,bool pinned,bool featured){final text=featured&&pinned?'BOOST بازارک':featured?'بازارک ویژه':'بازارک پین';return Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),decoration:BoxDecoration(color:Theme.of(context).colorScheme.primary.withOpacity(.9),borderRadius:BorderRadius.circular(8)),child:Text(text,style:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w800)));}Widget _placeholder(BuildContext context)=>Container(width:86,height:86,decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.image_outlined,size:34));}

class AuthScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const AuthScaffold({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState()=>_LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen>{final phone=TextEditingController(),password=TextEditingController();bool loading=false;Future<void> _login()async{if(!RegExp(r'^(?:07|\+937|00937)\d{8}$').hasMatch(phone.text.trim())){_msg(Exception('شماره تلفن افغانستان را به شکل 07XXXXXXXX وارد کنید.'));return;}setState(()=>loading=true);try{final t=await ApiService.login(phone.text.trim(),password.text);final p=await SharedPreferences.getInstance();await p.setString('bazarek_token',t);final rt=ApiService.refreshToken;if(rt!=null&&rt.isNotEmpty)await p.setString('bazarek_refresh_token',rt);if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const HomeScreen()),(_)=>false);}catch(e){_msg(e);}finally{if(mounted)setState(()=>loading=false);}}void _msg(Object e)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));@override Widget build(BuildContext context)=>AuthScaffold(title:tr('ورود به بازارک'),children:[TextField(controller:phone,keyboardType:TextInputType.phone,decoration:InputDecoration(labelText:tr('شماره تلفن'),hintText:'07XXXXXXXX',prefixIcon:const Icon(Icons.phone_outlined),border:const OutlineInputBorder())),const SizedBox(height:14),TextField(controller:password,obscureText:true,decoration:InputDecoration(labelText:tr('رمز عبور'),prefixIcon:const Icon(Icons.lock_outline),border:const OutlineInputBorder())),const SizedBox(height:20),SizedBox(width:double.infinity,height:52,child:FilledButton(onPressed:loading?null:_login,child:loading?const CircularProgressIndicator():Text(tr('ورود')))),TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RegisterScreen())),child:Text(tr('حساب ندارید؟ ثبت‌نام کنید'))),const Divider(height:28),TextButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminLoginScreen())),icon:const Icon(Icons.admin_panel_settings_outlined),label:Text(tr('ورود مدیریت')))]);}

class AdminLoginScreen extends StatefulWidget{const AdminLoginScreen({super.key});@override State<AdminLoginScreen> createState()=>_AdminLoginScreenState();}
class _AdminLoginScreenState extends State<AdminLoginScreen>{final email=TextEditingController(),password=TextEditingController();bool loading=false;Future<void> _login()async{setState(()=>loading=true);try{final t=await ApiService.adminLogin(email.text.trim(),password.text);final p=await SharedPreferences.getInstance();await p.setString('bazarek_admin_token',t);if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>AdminDashboardScreen(token:t)));}catch(e){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>loading=false);}}@override Widget build(BuildContext context)=>AuthScaffold(title:'پنل مدیریت بازارک',children:[const Text('این بخش فقط برای مدیر سیستم است.',textAlign:TextAlign.center),const SizedBox(height:20),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ایمیل مدیر',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'رمز عبور مدیر',border:OutlineInputBorder())),const SizedBox(height:18),SizedBox(height:52,child:FilledButton(onPressed:loading?null:_login,child:loading?const CircularProgressIndicator():const Text('ورود امن به مدیریت')))]);}

class AdminDashboardScreen extends StatefulWidget{final String token;const AdminDashboardScreen({super.key,required this.token});@override State<AdminDashboardScreen> createState()=>_AdminDashboardScreenState();}
class _AdminDashboardScreenState extends State<AdminDashboardScreen>{Map<String,dynamic> stats={};List<Map<String,dynamic>> products=[];List<Map<String,dynamic>> users=[];bool loading=true;int tab=0;
 Future<void> _load()async{setState(()=>loading=true);try{final r=await Future.wait([ApiService.adminStats(widget.token),ApiService.adminProducts(widget.token),ApiService.adminUsers(widget.token)]);if(mounted)setState((){stats=r[0] as Map<String,dynamic>;products=r[1] as List<Map<String,dynamic>>;users=r[2] as List<Map<String,dynamic>>;});}catch(e){_err(e);}finally{if(mounted)setState(()=>loading=false);}}
 Future<void> _status(Map<String,dynamic> p,bool active)async{try{await ApiService.adminSetProductStatus(widget.token,p['id'].toString(),active);await _load();}catch(e){_err(e);}}
 Future<void> _delete(String id)async{try{await ApiService.adminDeleteProduct(widget.token,id);await _load();}catch(e){_err(e);}}
 Future<void> _promote(Map<String,dynamic> p)async{final choice=await showDialog<String>(context:context,builder:(_)=>SimpleDialog(title:const Text('ارتقای آگهی'),children:[SimpleDialogOption(onPressed:()=>Navigator.pop(context,'featured7'),child:const Text('⭐ ویژه ۷ روزه')),SimpleDialogOption(onPressed:()=>Navigator.pop(context,'featured30'),child:const Text('⭐ ویژه ۳۰ روزه')),SimpleDialogOption(onPressed:()=>Navigator.pop(context,'pin7'),child:const Text('📌 پین ۷ روزه')),SimpleDialogOption(onPressed:()=>Navigator.pop(context,'pin30'),child:const Text('📌 پین ۳۰ روزه')),SimpleDialogOption(onPressed:()=>Navigator.pop(context,'both7'),child:const Text('⭐📌 ویژه + پین ۷ روزه')),SimpleDialogOption(onPressed:()=>Navigator.pop(context,'clear'),child:const Text('حذف ارتقا'))]));if(choice==null)return;int f=0,pi=0;if(choice=='featured7')f=7;if(choice=='featured30')f=30;if(choice=='pin7')pi=7;if(choice=='pin30')pi=30;if(choice=='both7'){f=7;pi=7;}try{await ApiService.adminPromoteProduct(widget.token,p['id'].toString(),featureDays:f,pinDays:pi);await _load();}catch(e){_err(e);}}
 Future<void> _warn(Map<String,dynamic> u) async {
   final c=TextEditingController();
   final message=await showDialog<String>(context:context,builder:(_)=>AlertDialog(title:const Text('هشدار به کاربر'),content:TextField(controller:c,maxLines:4,decoration:const InputDecoration(hintText:'متن هشدار و قانون نقض‌شده را بنویسید.')),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('لغو')),FilledButton(onPressed:()=>Navigator.pop(context,c.text.trim()),child:const Text('ارسال هشدار'))]));
   if(message==null||message.trim().isEmpty)return;
   try{await ApiService.adminWarnUser(widget.token,u['id'].toString(),message);_err(Exception('هشدار برای کاربر ثبت شد.'));}catch(e){_err(e);}
 }
 Future<void> _block(Map<String,dynamic> u)async{final blocked=u['is_blocked']==true;if(blocked){try{await ApiService.adminBlockUser(widget.token,u['id'].toString(),blocked:false);await _load();}catch(e){_err(e);}return;}final days=await showDialog<int>(context:context,builder:(_)=>SimpleDialog(title:const Text('مسدود کردن کاربر'),children:[SimpleDialogOption(onPressed:()=>Navigator.pop(context,1),child:const Text('۱ روز')),SimpleDialogOption(onPressed:()=>Navigator.pop(context,7),child:const Text('۷ روز')),SimpleDialogOption(onPressed:()=>Navigator.pop(context,30),child:const Text('۳۰ روز')),SimpleDialogOption(onPressed:()=>Navigator.pop(context,0),child:const Text('دائمی'))]));if(days==null)return;final reason=await _reasonDialog();try{await ApiService.adminBlockUser(widget.token,u['id'].toString(),blocked:true,durationDays:days,reason:reason);await _load();}catch(e){_err(e);}}
 Future<String> _reasonDialog()async{final c=TextEditingController();final r=await showDialog<String>(context:context,builder:(_)=>AlertDialog(title:const Text('دلیل مسدودی'),content:TextField(controller:c,maxLines:3,decoration:const InputDecoration(hintText:'مثلاً توهین، کلاهبرداری یا محتوای خلاف قوانین')),actions:[TextButton(onPressed:()=>Navigator.pop(context,''),child:const Text('بدون دلیل')),FilledButton(onPressed:()=>Navigator.pop(context,c.text.trim()),child:const Text('ثبت'))]));return r??'';}
 void _err(Object e)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));
 Future<void> _logout()async{final p=await SharedPreferences.getInstance();await p.remove('bazarek_admin_token');if(mounted)Navigator.pop(context);}
 @override void initState(){super.initState();_load();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('مدیریت بازارک'),actions:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AdminMonetizationScreen(token:widget.token))),icon:const Icon(Icons.payments_outlined)),IconButton(onPressed:_load,icon:const Icon(Icons.refresh)),IconButton(onPressed:_logout,icon:const Icon(Icons.logout))]),body:RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(16),children:[if(loading)const LinearProgressIndicator(),const SizedBox(height:8),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.7,children:[_stat('کاربران',stats['users']??0,Icons.people_outline),_stat('آگهی‌ها',stats['products']??0,Icons.campaign_outlined)]),const SizedBox(height:14),SegmentedButton<int>(segments:const[ButtonSegment(value:0,label:Text('آگهی‌ها'),icon:Icon(Icons.campaign_outlined)),ButtonSegment(value:1,label:Text('کاربران'),icon:Icon(Icons.people_outline))],selected:{tab},onSelectionChanged:(v)=>setState(()=>tab=v.first)),const SizedBox(height:16),if(tab==0)...products.map((p)=>Card(child:ListTile(leading:Icon(p['is_pinned']==true?Icons.push_pin:p['is_featured']==true?Icons.star:p['is_active']==true?Icons.visibility:Icons.visibility_off),title:Text(p['title']??''),subtitle:Text('${_money(p['price'])} • ${p['category']??'بدون دسته'}'),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='active')_status(p,true);if(v=='off')_status(p,false);if(v=='promote')_promote(p);if(v=='delete')_delete(p['id'].toString());},itemBuilder:(_)=>const[PopupMenuItem(value:'active',child:Text('فعال کردن')),PopupMenuItem(value:'off',child:Text('غیرفعال کردن')),PopupMenuItem(value:'promote',child:Text('⭐ ویژه / 📌 پین')),PopupMenuItem(value:'delete',child:Text('حذف آگهی'))])))) else ...users.map((u)=>Card(child:ListTile(leading:Icon(u['is_blocked']==true?Icons.block:Icons.person_outline),title:Text((u['shop_name']??u['full_name']??'کاربر بدون نام').toString()),subtitle:Text('${u['phone']??''}${u['block_reason']!=null?' • ${u['block_reason']}':''}'),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='warn')_warn(u);if(v=='block')_block(u);},itemBuilder:(_)=>[PopupMenuItem(value:'warn',child:Text('⚠️ ارسال هشدار')),PopupMenuItem(value:'block',child:Text(u['is_blocked']==true?'رفع مسدودی':'🚫 مسدود کردن'))]))))])));
 Widget _stat(String t,dynamic v,IconData i)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Icon(i),const SizedBox(width:8),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t),Text('$v',style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold))])])));
}


class AdminMonetizationScreen extends StatefulWidget { final String token; const AdminMonetizationScreen({super.key,required this.token}); @override State<AdminMonetizationScreen> createState()=>_AdminMonetizationScreenState(); }
class _AdminMonetizationScreenState extends State<AdminMonetizationScreen>{Map<String,dynamic> data={};bool loading=true;@override void initState(){super.initState();_load();}Future<void> _load()async{try{final d=await ApiService.adminMonetization(widget.token);if(mounted)setState(()=>data=d);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>loading=false);}}Future<void> _status(String id,String status)async{try{await ApiService.adminSetPromotionOrder(widget.token,id,status);await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}}Future<void> _subStatus(String id,String status)async{try{await ApiService.adminSetSubscription(widget.token,id,status);await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}}@override Widget build(BuildContext context){final orders=List<Map<String,dynamic>>.from((data['orders']??[]).map((e)=>Map<String,dynamic>.from(e)));return Scaffold(appBar:AppBar(title:const Text('💰 درآمد و BOOST بازارک'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[Card(child:ListTile(leading:const Icon(Icons.payments),title:const Text('درآمد ثبت‌شده'),trailing:Text('${data['revenue_afn']??0} AFN',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)))),const SizedBox(height:16),const Text('سفارش‌های تبلیغاتی',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),...orders.map((o)=>Card(child:ListTile(title:Text('${o['amount_afn']} AFN • ${o['package_id']}'),subtitle:Text('${o['payment_method']} • ${o['status']}${(o['payment_reference']??'').toString().isNotEmpty?' • رسید: ${o['payment_reference']}':''}'),trailing:o['status']=='pending'?PopupMenuButton<String>(onSelected:(v)=>_status(o['id'].toString(),v),itemBuilder:(_)=>const[PopupMenuItem(value:'paid',child:Text('تأیید پرداخت')),PopupMenuItem(value:'rejected',child:Text('رد پرداخت'))]):const Icon(Icons.check_circle_outline)))),
...List<Map<String,dynamic>>.from((data['subscriptions']??[]).map((e)=>Map<String,dynamic>.from(e))).map((s)=>Card(child:ListTile(title:Text('اشتراک ${(s['plan']??'').toString()} • ${(s['price_afn']??0)} AFN'),subtitle:Text('${s['status']}${(s['payment_reference']??'').toString().isNotEmpty?' • رسید: ${s['payment_reference']}':''}'),trailing:s['status']=='pending'?PopupMenuButton<String>(onSelected:(v)=>_subStatus(s['id'].toString(),v),itemBuilder:(_)=>const[PopupMenuItem(value:'active',child:Text('تأیید پرداخت و فعال‌سازی')),PopupMenuItem(value:'rejected',child:Text('رد پرداخت'))]):const Icon(Icons.storefront))))]));}}

class RegisterScreen extends StatefulWidget { const RegisterScreen({super.key}); @override State<RegisterScreen> createState()=>_RegisterScreenState(); }
class _RegisterScreenState extends State<RegisterScreen>{final name=TextEditingController(),shop=TextEditingController(),phone=TextEditingController(),password=TextEditingController();bool loading=false;Future<void> _register()async{if(!RegExp(r'^(?:07|\+937|00937)\d{8}$').hasMatch(phone.text.trim())){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('شماره تلفن افغانستان را به شکل 07XXXXXXXX وارد کنید.')));return;}if(password.text.length<8){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('رمز عبور باید حداقل ۸ کاراکتر باشد.')));return;}setState(()=>loading=true);try{final d=await ApiService.register(phone:phone.text.trim(),password:password.text,fullName:name.text,shopName:shop.text);final token=d['token'];if(token!=null){final p=await SharedPreferences.getInstance();await p.setString('bazarek_token',token.toString());final rt=ApiService.refreshToken;if(rt!=null&&rt.isNotEmpty)await p.setString('bazarek_refresh_token',rt);if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const HomeScreen()),(_)=>false);}else{throw Exception('حساب ساخته نشد. لطفاً دوباره تلاش کنید.');}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>loading=false);}}@override Widget build(BuildContext context)=>AuthScaffold(title:tr('ساخت حساب'),children:[TextField(controller:name,decoration:InputDecoration(labelText:tr('نام شما'),border:const OutlineInputBorder())),const SizedBox(height:10),TextField(controller:shop,decoration:InputDecoration(labelText:tr('نام دکان / کسب‌وکار'),border:const OutlineInputBorder())),const SizedBox(height:10),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:InputDecoration(labelText:tr('شماره تماس'),hintText:'07XXXXXXXX',border:const OutlineInputBorder())),const SizedBox(height:10),TextField(controller:password,obscureText:true,decoration:InputDecoration(labelText:'رمز عبور (حداقل ۸ کاراکتر)',border:const OutlineInputBorder())),const SizedBox(height:18),SizedBox(height:52,child:FilledButton(onPressed:loading?null:_register,child:loading?const CircularProgressIndicator():Text(tr('ساخت حساب و ورود'))))]);}


class MonetizationScreen extends StatefulWidget { const MonetizationScreen({super.key}); @override State<MonetizationScreen> createState()=>_MonetizationScreenState(); }
class _MonetizationScreenState extends State<MonetizationScreen>{
  Map<String,dynamic> wallet={}; List<Map<String,dynamic>> packages=[],orders=[],subs=[],products=[]; bool loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{try{final r=await Future.wait([ApiService.getWallet(),ApiService.monetizationPackages(),ApiService.promotionOrders(),ApiService.subscriptions(),ApiService.getProducts()]);if(mounted)setState((){wallet=r[0] as Map<String,dynamic>;packages=r[1] as List<Map<String,dynamic>>;orders=r[2] as List<Map<String,dynamic>>;subs=r[3] as List<Map<String,dynamic>>;products=r[4] as List<Map<String,dynamic>>;loading=false;});}catch(e){if(mounted){setState(()=>loading=false);_msg(e);}}}
  void _msg(Object e)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));
  Future<void> _buy(Map<String,dynamic> pkg)async{
  if(products.isEmpty){_msg(Exception('اول یک آگهی ثبت کنید.'));return;}
  final id=await showDialog<String>(context:context,builder:(_)=>SimpleDialog(title:const Text('انتخاب آگهی'),children:products.map((p)=>SimpleDialogOption(onPressed:()=>Navigator.pop(context,p['id'].toString()),child:Text(p['title']??''))).toList()));
  if(id==null)return;
  final method=await showDialog<String>(context:context,builder:(_)=>SimpleDialog(title:Text('🚀 فعال‌سازی ${pkg['title']}'),children:[
    SimpleDialogOption(onPressed:()=>Navigator.pop(context,'bank_transfer'),child:const ListTile(leading:Icon(Icons.account_balance),title:Text('پرداخت بانکی'),subtitle:Text('پس از تأیید مدیریت فعال می‌شود'))),
  ]));
  if(method==null)return;
  String reference='';
  if(method=='bank_transfer'){
    try{
      final info=await ApiService.paymentInfo();
      final bank=Map<String,dynamic>.from(info['bank']??{});
      final ref=TextEditingController();
      final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('انتقال بانکی'),content:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
        Text('مبلغ: ${pkg['price_afn']} AFN',style:const TextStyle(fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        Text('بانک: ${(bank['name']??'').toString()}'),
        Text('صاحب حساب: ${(bank['account_name']??'').toString()}'),
        Text('شماره حساب: ${(bank['account_number']??'').toString()}'),
        if((bank['branch']??'').toString().isNotEmpty)Text('شعبه: ${(bank['branch']??'').toString()}'),
        if((bank['swift_code']??'').toString().isNotEmpty)Text('SWIFT: ${(bank['swift_code']??'').toString()}'),
        const SizedBox(height:14),
        const Text('بعد از انتقال، شماره پیگیری/رسید را وارد کنید:'),
        const SizedBox(height:8),
        TextField(controller:ref,decoration:const InputDecoration(labelText:'شماره پیگیری',border:OutlineInputBorder())),
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('لغو')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ثبت پرداخت'))]));
      if(ok!=true)return; reference=ref.text.trim();
      if(reference.isEmpty){_msg(Exception('شماره پیگیری را وارد کنید.'));return;}
    }catch(e){_msg(e);return;}
  }
  try{await ApiService.buyPromotion(listingId:id,packageId:pkg['id'].toString(),paymentMethod:'manual',paymentReference:reference);if(mounted){_msg(Exception('درخواست ${pkg['title']} ثبت شد. پس از تأیید پرداخت توسط مدیریت، قابلیت فعال می‌شود.'));_load();}}catch(e){_msg(e);}
}
  Future<void> _sub(String plan,String title,int price)async{
    try{
      final info=await ApiService.paymentInfo();
      final bank=Map<String,dynamic>.from(info['bank']??{});
      final ref=TextEditingController();
      final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:Text(title),content:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
        Text('هزینه: $price AFN',style:const TextStyle(fontWeight:FontWeight.bold)),
        const SizedBox(height:10),
        const Text('برای فعال‌سازی، مبلغ را به حساب بازارک انتقال دهید. اشتراک فقط پس از تأیید مدیریت فعال می‌شود.'),
        const SizedBox(height:12),
        Text('بانک: ${(bank['name']??'').toString()}'),
        Text('صاحب حساب: ${(bank['account_name']??'').toString()}'),
        Text('شماره حساب: ${(bank['account_number']??'').toString()}'),
        if((bank['branch']??'').toString().isNotEmpty)Text('شعبه: ${(bank['branch']??'').toString()}'),
        if((bank['swift_code']??'').toString().isNotEmpty)Text('SWIFT: ${(bank['swift_code']??'').toString()}'),
        const SizedBox(height:12),
        TextField(controller:ref,decoration:const InputDecoration(labelText:'شماره پیگیری / رسید',border:OutlineInputBorder())),
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('لغو')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ثبت درخواست'))]));
      if(ok!=true)return;
      if(ref.text.trim().isEmpty){_msg(Exception('شماره پیگیری را وارد کنید.'));return;}
      await ApiService.buySubscription(plan,paymentReference:ref.text.trim());
      _msg(Exception('درخواست اشتراک ثبت شد و پس از تأیید پرداخت فعال می‌شود.'));
      _load();
    }catch(e){_msg(e);}
  }
  @override Widget build(BuildContext context){if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));final bal=wallet['wallet'] is Map?(wallet['wallet']['balance_afn']??0):0;return Scaffold(appBar:AppBar(title:const Text('🚀 بازارک BOOST')),body:RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(16),children:[Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('🚀 بازارک BOOST',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('آگهی‌ات را بیشتر دیده‌شدن بده! ویژه، پین و BOOST باعث می‌شود آگهی تو برجسته‌تر دیده شود.',style:TextStyle(height:1.5)),const SizedBox(height:10),const Text('قیمت‌ها اقتصادی تنظیم شده‌اند؛ پرداخت بانکی است و فقط بعد از تأیید مدیریت فعال می‌شود.',style:TextStyle(fontWeight:FontWeight.bold))]))),const SizedBox(height:14),Card(child:ListTile(leading:const Icon(Icons.account_balance_wallet),title:const Text('موجودی کیف پول'),subtitle:const Text('برای استفاده‌های آینده'),trailing:Text('${bal.toString()} AFN',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)))),const SizedBox(height:18),const Text('🔥 بسته‌های BOOST و تبلیغ آگهی',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:8),...packages.map((p)=>Card(child:ListTile(leading:CircleAvatar(child:Icon((p['boost_level']??0)>0?Icons.rocket_launch:(p['pin_days']??0)>0?Icons.push_pin:Icons.star)),title:Text(p['title']??'',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text((p['description']??'ارتقای آگهی برای دیده‌شدن بیشتر و جلب توجه خریداران.').toString()),trailing:Text('${p['price_afn']} AFN'),onTap:()=>_buy(p)))),const SizedBox(height:20),const Text('🏪 فروشگاه حرفه‌ای',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),Card(child:ListTile(title:const Text('Basic'),subtitle:const Text('برای فروشنده‌ای که تازه شروع کرده؛ حضور حرفه‌ای و امکانات پایه فروش.'),trailing:const Text('150 AFN / ماه'),onTap:()=>_sub('basic','اشتراک Basic',150))),Card(child:ListTile(title:const Text('Pro'),subtitle:const Text('برای فروشنده‌های فعال؛ مناسب آگهی‌های بیشتر و حضور حرفه‌ای‌تر.'),trailing:const Text('250 AFN / ماه'),onTap:()=>_sub('pro','اشتراک Pro',250))),Card(child:ListTile(title:const Text('Business'),subtitle:const Text('برای فروشگاه‌ها و کسب‌وکارها؛ مناسب فعالیت جدی و برند‌سازی در بازارک.'),trailing:const Text('450 AFN / ماه'),onTap:()=>_sub('business','اشتراک Business',450))),const SizedBox(height:18),if(orders.isNotEmpty)const Text('📋 وضعیت سفارش‌های BOOST',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),...orders.map((o)=>ListTile(title:Text((o['promotion_packages'] is Map?o['promotion_packages']['title']:o['package_id']).toString()),subtitle:Text('${o['amount_afn']} AFN • ${(o['status']=='pending')?'در انتظار تأیید پرداخت':o['status']}'),leading:const Icon(Icons.receipt_long))),if(subs.isNotEmpty)const Text('اشتراک‌های من',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),...subs.map((x)=>ListTile(title:Text('پلن ${(x['plan']??'').toString()}'),subtitle:Text('تا ${(x['ends_at']??'').toString()}'),leading:const Icon(Icons.storefront))) ])));}
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState()=>_ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen>{
  final name=TextEditingController(),shop=TextEditingController(),phone=TextEditingController(),city=TextEditingController();
  Map<String,dynamic> profile={}; List<Map<String,dynamic>> warnings=[]; Uint8List? avatarBytes; String avatarName='avatar.jpg'; bool loading=true,saving=false,uploading=false;
  final picker=ImagePicker();
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{try{final r=await Future.wait([ApiService.getProfile(),ApiService.getMyWarnings()]);final p=r[0] as Map<String,dynamic>;if(mounted)setState((){profile=p;warnings=r[1] as List<Map<String,dynamic>>;name.text=(p['full_name']??'').toString();shop.text=(p['shop_name']??'').toString();phone.text=(p['phone']??'').toString();city.text=(p['city']??'').toString();loading=false;});}catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}}}
  Future<void> _save()async{setState(()=>saving=true);try{await ApiService.updateProfile(fullName:name.text.trim(),shopName:shop.text.trim(),phone:phone.text.trim(),city:city.text.trim());if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('پروفایل ذخیره شد.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>saving=false);}}
  Future<void> _avatar()async{try{final x=await picker.pickImage(source:ImageSource.gallery,imageQuality:80,maxWidth:1200);if(x==null)return;final b=await x.readAsBytes();setState(()=>avatarBytes=b);setState(()=>uploading=true);final url=await ApiService.uploadAvatar(b,x.name);setState(()=>profile={...profile,'avatar_url':url});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تصویر پروفایل به‌روزرسانی شد.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>uploading=false);}}
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final avatar = (profile['avatar_url'] ?? '').toString();
    ImageProvider<Object>? avatarImage;
    if (avatarBytes != null) {
      avatarImage = MemoryImage(avatarBytes!);
    } else if (avatar.isNotEmpty) {
      avatarImage = NetworkImage(avatar);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل من')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 58,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? const Icon(Icons.person, size: 58)
                      : null,
                ),
                FloatingActionButton.small(
                  onPressed: uploading ? null : _avatar,
                  child: uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(),
                        )
                      : const Icon(Icons.camera_alt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'نام و نام خانوادگی',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: shop,
            decoration: const InputDecoration(
              labelText: 'نام دکان / کسب‌وکار',
              prefixIcon: Icon(Icons.store_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'شماره تلفن',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: '07XXXXXXXX',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: city,
            decoration: const InputDecoration(
              labelText: 'شهر / ولایت',
              prefixIcon: Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(saving ? 'در حال ذخیره…' : 'ذخیره پروفایل'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
              );
            },
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('ورود به پنل مدیریت بازارک'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final p = await SharedPreferences.getInstance();
              await p.remove('bazarek_token');
              await p.remove('bazarek_refresh_token');
              ApiService.clearSession();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('خروج از حساب'),
          ),
          const SizedBox(height: 24),
          if (warnings.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'هشدارهای مدیریت',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...warnings.map(
                      (w) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.warning_amber_rounded),
                        title: Text((w['message'] ?? '').toString()),
                        subtitle: Text((w['created_at'] ?? '').toString()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'نکته امنیتی: شماره تلفن شما فقط در آگهی‌هایی نمایش داده می‌شود که گزینه «نمایش شماره تماس» را فعال کرده باشید.',
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class DashboardScreen extends StatefulWidget { const DashboardScreen({super.key}); @override State<DashboardScreen> createState()=>_DashboardScreenState(); }
class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> products = [];
  Map<String, dynamic>? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([ApiService.getProducts(), ApiService.getProfile()]);
      if (mounted) {
        setState(() {
          products = r[0] as List<Map<String, dynamic>>;
          profile = r[1] as Map<String, dynamic>;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _msg(e);
      }
    }
  }

  void _msg(Object e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );

  Future<void> _add() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddProductSheet(),
    );
    if (result == null) return;
    try {
      await ApiService.addProduct(result);
      await _load();
    } catch (e) {
      _msg(e);
    }
  }

  Future<void> _delete(String id) async {
    try {
      await ApiService.deleteProduct(id);
      await _load();
    } catch (e) {
      _msg(e);
    }
  }

  Future<void> _logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('bazarek_token');
    await p.remove('bazarek_refresh_token');
    ApiService.clearSession();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  Widget _stat(String t, String v, IconData i) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(i),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t),
                    Text(v, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final shop = (profile?['shop_name'] ?? '').toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(shop.isEmpty ? 'حساب من' : shop),
        actions: [IconButton(onPressed: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MonetizationScreen())),icon:const Icon(Icons.account_balance_wallet_outlined)),IconButton(onPressed: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ProfileScreen())).then((_)=>_load()),icon:const Icon(Icons.person)),IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('ثبت آگهی'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'سلام ${profile?['full_name'] ?? ''} 👋',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(child:InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MonetizationScreen())),child:const Padding(padding:EdgeInsets.all(14),child:Row(children:[CircleAvatar(child:Icon(Icons.rocket_launch)),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('🚀 بازارک BOOST',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),SizedBox(height:3),Text('آگهی‌ات را ویژه، پین یا BOOST کن و بیشتر دیده شو.')])) ,Icon(Icons.chevron_left)])))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _stat('آگهی‌های من', products.length.toString(), Icons.campaign_outlined),
                      const SizedBox(width: 10),
                      _stat(
                        'موجودی',
                        products.fold<int>(0, (s, p) => s + ((p['stock'] as num?) ?? 0).toInt()).toString(),
                        Icons.inventory_2_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...products.map(
                    (p) => Card(
                      child: ListTile(
                        leading: ImageGallery(images: _imageUrls(p['image_url']), height: 55),
                        title: Text(p['title'] ?? ''),
                        subtitle: Text(_money(p['price'])),
                        trailing: IconButton(
                          onPressed: () => _delete(p['id'].toString()),
                          icon: const Icon(Icons.delete_outline),
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


class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override State<ConversationsScreen> createState()=>_ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>{
  bool loading=true;
  List<Map<String,dynamic>> items=[];
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    if(mounted)setState(()=>loading=true);
    try{items=await ApiService.getConversations();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}
    finally{if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar:AppBar(title:const Text('پیام‌ها')),
      body:RefreshIndicator(
        onRefresh:_load,
        child:loading
          ? const Center(child:CircularProgressIndicator())
          : items.isEmpty
            ? ListView(children:[SizedBox(height:220),Icon(Icons.chat_bubble_outline,size:52),const SizedBox(height:10),const Center(child:Text('هنوز گفتگویی ندارید.')),const SizedBox(height:6),const Center(child:Text('از داخل یک آگهی، «چت با فروشنده» را بزنید.'))])
            : ListView.separated(
                padding:const EdgeInsets.all(12),
                itemCount:items.length,
                itemBuilder:(_,i){
                  final c=items[i];
                  return Card(child:ListTile(
                    leading:const CircleAvatar(child:Icon(Icons.person_outline)),
                    title:Text((c['listing_title']??'آگهی').toString(),maxLines:1,overflow:TextOverflow.ellipsis),
                    subtitle:Text((c['other_user_name']??'کاربر بازارک').toString()),
                    trailing:const Icon(Icons.chevron_left),
                    onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ChatScreen(conversation:c,listingTitle:(c['listing_title']??'آگهی').toString()))).then((_)=>_load()),
                  ));
                },
                separatorBuilder:(_,__)=>const SizedBox(height:6),
              ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Map<String,dynamic> conversation;
  final String listingTitle;
  const ChatScreen({super.key,required this.conversation,required this.listingTitle});
  @override State<ChatScreen> createState()=>_ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>{
  Timer? refreshTimer;
  final controller=TextEditingController();
  final scroll=ScrollController();
  List<Map<String,dynamic>> messages=[];
  bool loading=true;
  bool sending=false;
  String get id=>widget.conversation['id'].toString();
  @override void initState(){super.initState();_load();refreshTimer=Timer.periodic(const Duration(seconds:4),(_)=>_load(silent:true));}
  @override void dispose(){refreshTimer?.cancel();controller.dispose();scroll.dispose();super.dispose();}
  Future<void> _load({bool silent=false}) async {
    try{
      final x=await ApiService.getMessages(id);
      if(mounted)setState(()=>messages=x);
      WidgetsBinding.instance.addPostFrameCallback((_) {if(scroll.hasClients)scroll.jumpTo(scroll.position.maxScrollExtent);});
    }catch(e){if(!silent&&mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> _send() async {
    final text=controller.text.trim();
    if(text.isEmpty||sending)return;
    setState(()=>sending=true);
    try{
      final m=await ApiService.sendMessage(id,text);
      controller.clear();
      setState(()=>messages.add(m));
      WidgetsBinding.instance.addPostFrameCallback((_) {if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:200),curve:Curves.easeOut);});
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}
    finally{if(mounted)setState(()=>sending=false);}
  }
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar:AppBar(title:Text(widget.listingTitle,maxLines:1,overflow:TextOverflow.ellipsis)),
      body:Column(children:[
        Expanded(child:loading
          ? const Center(child:CircularProgressIndicator())
          : messages.isEmpty
            ? const Center(child:Text('اولین پیام را شما بفرستید.'))
            : ListView.builder(controller:scroll,padding:const EdgeInsets.all(12),itemCount:messages.length,itemBuilder:(_,i){final m=messages[i];return _Bubble(message:m,mine:m['sender_id']?.toString()==ApiService.currentUserId);})),
        SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(10,6,10,10),child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
          Expanded(child:TextField(controller:controller,maxLines:4,minLines:1,textInputAction:TextInputAction.newline,decoration:InputDecoration(hintText:'پیام خود را بنویسید…',border:OutlineInputBorder(borderRadius:BorderRadius.circular(18)),contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:10)))),
          const SizedBox(width:8),
          IconButton.filled(onPressed:sending?null:_send,icon:sending?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send)),
        ]))),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget{
  final Map<String,dynamic> message;
  final bool mine;
  const _Bubble({required this.message,required this.mine});
  @override Widget build(BuildContext context){
    return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.78),decoration:BoxDecoration(color:mine?Theme.of(context).colorScheme.primaryContainer:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(16)),child:Text((message['message']??'').toString(),style:const TextStyle(fontSize:15,height:1.4))));
  }
}

class AddProductSheet extends StatefulWidget{const AddProductSheet({super.key});@override State<AddProductSheet> createState()=>_AddProductSheetState();}
class _AddProductSheetState extends State<AddProductSheet> {
  final contactPhone = TextEditingController();
  final locationText = TextEditingController();
  final title = TextEditingController();
  final price = TextEditingController();
  final stock = TextEditingController(text: '1');
  final desc = TextEditingController();
  String category = '';
  List<Uint8List> imageBytes = [];
  List<String> imageNames = [];
  List<String> imageUrls = [];
  bool uploading = false;
  bool allowChat = true;
  bool showPhone = false;
  bool isNegotiable = false;
  final picker = ImagePicker();
  @override void initState(){super.initState();_prefillPhone();}
  Future<void> _prefillPhone() async { try { final p=await ApiService.getProfile(); if(mounted && contactPhone.text.isEmpty) setState(()=>contactPhone.text=(p['phone']??'').toString()); } catch (_) {} }

  final cats = ['موبایل', 'موتر', 'املاک', 'لوازم برقی', 'خانه', 'لباس', 'خدمات', 'کار', 'حیوانات', 'سایر'];

  Future<void> _pickImages() async {
    try {
      final xs = await picker.pickMultiImage(imageQuality: 80, maxWidth: 1600);
      if (xs.isEmpty) return;
      final selected = xs.take(6).toList();
      final bytes = <Uint8List>[];
      final names = <String>[];
      for (final x in selected) {
        bytes.add(await x.readAsBytes());
        names.add(x.name);
      }
      setState(() {
        imageBytes = bytes;
        imageNames = names;
        imageUrls = [];
      });
    } catch (e) {
      _msg(e);
    }
  }

  void _removeImage(int index) {
    if (index < 0 || index >= imageBytes.length) return;
    setState(() {
      imageBytes.removeAt(index);
      imageNames.removeAt(index);
      // The uploaded URL list no longer matches the selected files, so force a re-upload.
      imageUrls = [];
    });
  }

  Future<void> _uploadImages() async {
    if (imageBytes.isEmpty) return;
    setState(() => uploading = true);
    try {
      final urls = await ApiService.uploadImages(imageBytes, imageNames);
      if (!mounted) return;
      setState(() => imageUrls = urls);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${urls.length} عکس با موفقیت آپلود شد.')),
      );
    } catch (e) {
      if (mounted) _msg(e);
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  void _msg(Object e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('ثبت آگهی', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('حداکثر ۶ عکس می‌توانید برای هر آگهی اضافه کنید. برای حذف هر عکس، روی × گوشه آن بزنید.'),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickImages,
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: imageBytes.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 48),
                          SizedBox(height: 8),
                          Text('انتخاب عکس‌ها'),
                          Text('حداکثر ۶ عکس'),
                        ],
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: imageBytes.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemBuilder: (_, i) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(imageBytes[i], fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: uploading ? null : () => _removeImage(i),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            if (imageBytes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: OutlinedButton.icon(
                  onPressed: uploading ? null : _uploadImages,
                  icon: uploading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(imageUrls.isEmpty ? 'آپلود عکس‌ها' : 'عکس‌ها آپلود شد ✓'),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'عنوان آگهی', hintText: 'مثلاً آیفون ۱۳ کارکرده سالم', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: category.isEmpty ? null : category,
              decoration: const InputDecoration(labelText: 'دسته‌بندی', border: OutlineInputBorder()),
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => category = v ?? ''),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'قیمت', suffixText: 'افغانی', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: stock,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'تعداد', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(controller:contactPhone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'شماره تماس آگهی',hintText:'07XXXXXXXX',prefixIcon:Icon(Icons.phone_outlined),border:OutlineInputBorder())),
            const SizedBox(height:10),
            TextField(controller:locationText,decoration:const InputDecoration(labelText:'محل آگهی',hintText:'مثلاً کابل، کارته چهار',prefixIcon:Icon(Icons.location_on_outlined),border:OutlineInputBorder())),
            const SizedBox(height:10),
            Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              const Text('راه‌های ارتباط با خریدار',style:TextStyle(fontWeight:FontWeight.bold)),
              SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('فعال بودن چت با خریدار'),subtitle:const Text('خریداران می‌توانند از داخل آگهی به شما پیام بدهند.'),value:allowChat,onChanged:(v)=>setState(()=>allowChat=v)),
              SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('نمایش شماره تماس'),subtitle:const Text('شماره واردشده در همین آگهی برای خریدار نمایش داده می‌شود.'),value:showPhone,onChanged:(v)=>setState(()=>showPhone=v)),
              SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('قابل مذاکره'),subtitle:const Text('قیمت قابل مذاکره است.'),value:isNegotiable,onChanged:(v)=>setState(()=>isNegotiable=v)),
            ]))),
            const SizedBox(height: 10),
            TextField(
              controller: desc,
              maxLines: 6,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(labelText: 'توضیحات آگهی', hintText: 'وضعیت، مدل، امکانات و نکات مهم را واضح بنویسید…', alignLabelWithHint: true, border: OutlineInputBorder()),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: uploading
                  ? null
                  : () async {
                      if (title.text.trim().isEmpty) {
                        _msg(Exception('عنوان آگهی را وارد کنید.'));
                        return;
                      }
                      if (category.isEmpty) {
                        _msg(Exception('دسته‌بندی را انتخاب کنید.'));
                        return;
                      }
                      if (imageBytes.isNotEmpty && imageUrls.isEmpty) {
                        await _uploadImages();
                        if (imageUrls.isEmpty) return;
                      }
                      Navigator.pop(context, {
                        'title': title.text.trim(),
                        'category': category,
                        'price': double.tryParse(price.text.replaceAll(',', '')) ?? 0,
                        'cost_price': 0,
                        'stock': int.tryParse(stock.text) ?? 0,
                        'description': desc.text.trim(),
                        'image_url': jsonEncode(imageUrls),
                        'allow_chat': allowChat,
                        'show_phone': showPhone,
                        'contact_phone': contactPhone.text.trim(),
                        'location_text': locationText.text.trim(),
                        'is_negotiable': isNegotiable,
                      });
                    },
              icon: const Icon(Icons.publish),
              label: const Text('انتشار آگهی'),
            ),
          ],
        ),
      ),
    );
  }
}
