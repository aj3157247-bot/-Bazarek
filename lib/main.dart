import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

void main() => runApp(const BazarekApp());

class BazarekApp extends StatelessWidget {
  const BazarekApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'بازارک', debugShowCheckedModeBanner: false, locale: const Locale('fa'),
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal, fontFamily: 'Roboto'),
    home: const StartupScreen(),
  );
}

class StartupScreen extends StatefulWidget { const StartupScreen({super.key}); @override State<StartupScreen> createState()=>_StartupScreenState(); }
class _StartupScreenState extends State<StartupScreen> {
  @override void initState(){super.initState();_start();}
  Future<void> _start() async { final p=await SharedPreferences.getInstance(); final t=p.getString('bazarek_token'); if(t!=null&&t.isNotEmpty){ApiService.setToken(t);try{await ApiService.getProfile();if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomeScreen()));return;}catch(_){await p.remove('bazarek_token');}}if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomeScreen())); }
  @override Widget build(BuildContext context)=>const Scaffold(body:Center(child:CircularProgressIndicator()));
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen>{
  final search=TextEditingController(); List<Map<String,dynamic>> listings=[]; bool loading=true; String category='';
  final cats=['همه','موبایل','موتر','املاک','لوازم برقی','خانه','لباس','خدمات','کار','حیوانات'];
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{setState(()=>loading=true);try{final x=await ApiService.getListings(q:search.text,category:category=='همه'?'':category);if(mounted)setState(()=>listings=x);}catch(e){if(mounted)_msg(e);}finally{if(mounted)setState(()=>loading=false);}}
  void _msg(Object e)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));
  Future<void> _openLogin()async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>const LoginScreen()));if(mounted)_load();}
  Future<void> _post()async{final p=await SharedPreferences.getInstance();if(p.getString('bazarek_token')==null){await _openLogin();return;}if(!mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>const DashboardScreen()));}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('بازارک',style:TextStyle(fontWeight:FontWeight.bold)),actions:[IconButton(onPressed:_openLogin,tooltip:'ورود',icon:const Icon(Icons.person_outline))]),floatingActionButton:FloatingActionButton.extended(onPressed:_post,icon:const Icon(Icons.add),label:const Text('ثبت آگهی')),body:RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[Text('بازار افغانستان، ساده و حرفه‌ای',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:12),TextField(controller:search,onSubmitted:(_)=>_load(),textInputAction:TextInputAction.search,decoration:InputDecoration(hintText:'چه چیزی می‌خواهید پیدا کنید؟',prefixIcon:const Icon(Icons.search),suffixIcon:IconButton(onPressed:_load,icon:const Icon(Icons.tune)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(18)))),const SizedBox(height:12),SizedBox(height:44,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:cats.length,itemBuilder:(_,i)=>ChoiceChip(label:Text(cats[i]),selected:(category.isEmpty&&i==0)||category==cats[i],onSelected:(_){setState(()=>category=cats[i]);_load();}),separatorBuilder:(_,__)=>const SizedBox(width:8))),const SizedBox(height:18),if(loading)const Center(child:Padding(padding:EdgeInsets.all(30),child:CircularProgressIndicator())) else if(listings.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(28),child:Column(children:[Icon(Icons.search_off,size:46),SizedBox(height:8),Text('آگهی‌ای پیدا نشد.'),Text('جستجو یا دسته‌بندی را تغییر دهید.')]))) else ...listings.map((p)=>ListingCard(product:p,onTap:()=>_details(p)))])));
  void _details(Map<String,dynamic> p)=>showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>Padding(padding:const EdgeInsets.all(20),child:Wrap(children:[Text(p['title']??'',style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:10),Text('${p['price']??0} افغانی',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),if((p['category']??'').toString().isNotEmpty)Text('دسته‌بندی: ${p['category']}'),const SizedBox(height:12),Text((p['description']??'توضیحی ثبت نشده است.').toString()),const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>_msg(Exception('برای تماس و چت، وارد حساب شوید.')),icon:const Icon(Icons.chat_bubble_outline),label:const Text('چت با فروشنده')))])));
}

class ListingCard extends StatelessWidget{final Map<String,dynamic> product;final VoidCallback onTap;const ListingCard({super.key,required this.product,required this.onTap});@override Widget build(BuildContext context)=>Card(clipBehavior:Clip.antiAlias,child:ListTile(onTap:onTap,leading:Container(width:64,height:64,decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.image_outlined,size:30)),title:Text((product['title']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis),subtitle:Text('${product['price']??0} افغانی • ${(product['category']??'عمومی').toString()}'),trailing:const Icon(Icons.chevron_left)));}

class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState()=>_LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen>{final email=TextEditingController(),password=TextEditingController();bool loading=false;Future<void> _login()async{setState(()=>loading=true);try{final t=await ApiService.login(email.text.trim(),password.text);final p=await SharedPreferences.getInstance();await p.setString('bazarek_token',t);if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const HomeScreen()),(_)=>false);}catch(e){_msg(e);}finally{if(mounted)setState(()=>loading=false);}}void _msg(Object e)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));@override Widget build(BuildContext context)=>AuthScaffold(title:'ورود به بازارک',children:[TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ایمیل',prefixIcon:Icon(Icons.email_outlined),border:OutlineInputBorder())),const SizedBox(height:14),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'رمز عبور',prefixIcon:Icon(Icons.lock_outline),border:OutlineInputBorder())),const SizedBox(height:20),SizedBox(width:double.infinity,height:52,child:FilledButton(onPressed:loading?null:_login,child:loading?const CircularProgressIndicator():const Text('ورود'))),TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RegisterScreen())),child:const Text('حساب ندارید؟ ثبت‌نام کنید')),const Divider(height:28),TextButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminLoginScreen())),icon:const Icon(Icons.admin_panel_settings_outlined),label:const Text('ورود مدیریت'))]);}

class AdminLoginScreen extends StatefulWidget{const AdminLoginScreen({super.key});@override State<AdminLoginScreen> createState()=>_AdminLoginScreenState();}
class _AdminLoginScreenState extends State<AdminLoginScreen>{final email=TextEditingController(),password=TextEditingController();bool loading=false;Future<void> _login()async{setState(()=>loading=true);try{final t=await ApiService.adminLogin(email.text.trim(),password.text);final p=await SharedPreferences.getInstance();await p.setString('bazarek_admin_token',t);if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>AdminDashboardScreen(token:t)));}catch(e){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>loading=false);}}@override Widget build(BuildContext context)=>AuthScaffold(title:'پنل مدیریت بازارک',children:[const Text('این بخش فقط برای مدیر سیستم است.',textAlign:TextAlign.center),const SizedBox(height:20),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ایمیل مدیر',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'رمز عبور مدیر',border:OutlineInputBorder())),const SizedBox(height:18),SizedBox(height:52,child:FilledButton(onPressed:loading?null:_login,child:loading?const CircularProgressIndicator():const Text('ورود امن به مدیریت')))]);}

class AdminDashboardScreen extends StatefulWidget{final String token;const AdminDashboardScreen({super.key,required this.token});@override State<AdminDashboardScreen> createState()=>_AdminDashboardScreenState();}
class _AdminDashboardScreenState extends State<AdminDashboardScreen>{Map<String,dynamic> stats={};List<Map<String,dynamic>> products=[];bool loading=true;@override void initState(){super.initState();_load();}Future<void> _load()async{setState(()=>loading=true);try{final a=await ApiService.adminStats(widget.token);final b=await ApiService.adminProducts(widget.token);if(mounted)setState((){stats=a;products=b;});}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>loading=false);}}Future<void> _status(Map<String,dynamic> p,bool active)async{try{await ApiService.adminSetProductStatus(widget.token,p['id'].toString(),active);await _load();}catch(e){_err(e);}}Future<void> _delete(String id)async{try{await ApiService.adminDeleteProduct(widget.token,id);await _load();}catch(e){_err(e);}}void _err(Object e)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));Future<void> _logout()async{final p=await SharedPreferences.getInstance();await p.remove('bazarek_admin_token');if(mounted)Navigator.pop(context);}@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('مدیریت بازارک'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh)),IconButton(onPressed:_logout,icon:const Icon(Icons.logout))]),body:RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(16),children:[if(loading)const LinearProgressIndicator(),const SizedBox(height:8),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.7,children:[_stat('کاربران',stats['users']??0,Icons.people_outline),_stat('آگهی‌ها',stats['products']??0,Icons.campaign_outlined)]),const SizedBox(height:18),const Text('مدیریت آگهی‌ها',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),...products.map((p)=>Card(child:ListTile(title:Text(p['title']??''),subtitle:Text('${p['price']??0} افغانی • ${p['category']??'بدون دسته'}'),leading:Icon(p['is_active']==true?Icons.visibility:Icons.visibility_off),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='active')_status(p,true);if(v=='off')_status(p,false);if(v=='delete')_delete(p['id'].toString());},itemBuilder:(_)=>const[PopupMenuItem(value:'active',child:Text('فعال کردن')),PopupMenuItem(value:'off',child:Text('غیرفعال کردن')),PopupMenuItem(value:'delete',child:Text('حذف آگهی'))]))))])));
 Widget _stat(String t,Object v,IconData i)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Icon(i,size:30),const SizedBox(width:10),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t),Text('$v',style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold))])])));
}

class RegisterScreen extends StatefulWidget { const RegisterScreen({super.key}); @override State<RegisterScreen> createState()=>_RegisterScreenState(); }
class _RegisterScreenState extends State<RegisterScreen>{final name=TextEditingController(),shop=TextEditingController(),phone=TextEditingController(),email=TextEditingController(),password=TextEditingController();bool loading=false;Future<void> _register()async{setState(()=>loading=true);try{final d=await ApiService.register(email:email.text.trim(),password:password.text,fullName:name.text,shopName:shop.text,phone:phone.text);if(d['token']!=null){final p=await SharedPreferences.getInstance();await p.setString('bazarek_token',d['token']);if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const HomeScreen()),(_)=>false);}else if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(d['message']??'ایمیل خود را بررسی کنید.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>loading=false);}}@override Widget build(BuildContext context)=>AuthScaffold(title:'ساخت حساب',children:[TextField(controller:name,decoration:const InputDecoration(labelText:'نام شما',border:OutlineInputBorder())),const SizedBox(height:10),TextField(controller:shop,decoration:const InputDecoration(labelText:'نام دکان / کسب‌وکار',border:OutlineInputBorder())),const SizedBox(height:10),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'شماره تماس',border:OutlineInputBorder())),const SizedBox(height:10),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ایمیل',border:OutlineInputBorder())),const SizedBox(height:10),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'رمز عبور (حداقل ۸ کاراکتر)',border:OutlineInputBorder())),const SizedBox(height:18),FilledButton(onPressed:loading?null:_register,child:loading?const CircularProgressIndicator():const Text('ساخت حساب'))]);}

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
      final r = await Future.wait([
        ApiService.getProducts(),
        ApiService.getProfile(),
      ]);
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

  void _msg(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }

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
    ApiService.setToken(null);
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = (profile?['shop_name'] ?? '').toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(shop.isEmpty ? 'حساب من' : shop),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
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
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _stat(
                        'آگهی‌های من',
                        products.length.toString(),
                        Icons.campaign_outlined,
                      ),
                      const SizedBox(width: 10),
                      _stat(
                        'موجودی',
                        products
                            .fold<int>(
                              0,
                              (s, p) => s + ((p['stock'] as num?) ?? 0).toInt(),
                            )
                            .toString(),
                        Icons.inventory_2_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...products.map(
                    (p) => Card(
                      child: ListTile(
                        title: Text(p['title'] ?? ''),
                        subtitle: Text(
                          '${p['price'] ?? 0} افغانی • موجودی: ${p['stock'] ?? 0}',
                        ),
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

  Widget _stat(String t, String v, IconData i) {
    return Expanded(
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
                  Text(
                    v,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
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
  final category = TextEditingController();
  final price = TextEditingController();
  final cost = TextEditingController();
  final stock = TextEditingController(text: '0');
  final desc = TextEditingController();

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
            const Text(
              'ثبت آگهی',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'عنوان آگهی',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: category,
              decoration: const InputDecoration(
                labelText: 'دسته‌بندی',
                hintText: 'مثلاً موبایل',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'قیمت (افغانی)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: stock,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'تعداد',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: desc,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'توضیحات',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isEmpty) return;
                Navigator.pop(
                  context,
                  {
                    'title': title.text.trim(),
                    'category': category.text.trim(),
                    'price': double.tryParse(price.text) ?? 0,
                    'cost_price': double.tryParse(cost.text) ?? 0,
                    'stock': int.tryParse(stock.text) ?? 0,
                    'description': desc.text.trim(),
                    'image_url': '',
                  },
                );
              },
              child: const Text('انتشار آگهی'),
            ),
          ],
        ),
      ),
    );
  }
}


class AuthScaffold extends StatelessWidget{final String title;final List<Widget> children;const AuthScaffold({super.key,required this.title,required this.children});@override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:520),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Icon(Icons.storefront_rounded,size:64),const SizedBox(height:12),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:24),...children]))))));}
