import 'package:flutter/material.dart';
import 'api_service.dart';

void main() => runApp(const BazarekApp());

class BazarekApp extends StatelessWidget {
  const BazarekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بازارک - دستیار فروش هوشمند',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal, fontFamily: 'Roboto'),
      home: const EntryScreen(),
    );
  }
}

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});
  @override State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  bool loading = true;
  @override
  void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    if (await ApiService.hasSession()) {
      try { await ApiService.me(); if (mounted) _go(const DashboardScreen()); }
      catch (_) { await ApiService.logout(); }
    }
    if (mounted) setState(() => loading = false);
  }
  void _go(Widget page) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  @override Widget build(BuildContext context) => loading
      ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : AuthScreen(onLoggedIn: () => _go(const DashboardScreen()));
}

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const AuthScreen({super.key, required this.onLoggedIn});
  @override State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool register = false, loading = false, obscure = true;
  final name = TextEditingController(), shop = TextEditingController(), email = TextEditingController(), password = TextEditingController();

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.isEmpty || (register && (name.text.trim().isEmpty || shop.text.trim().isEmpty))) {
      _msg('لطفاً همه معلومات ضروری را وارد کنید.'); return;
    }
    setState(() => loading = true);
    try {
      if (register) {
        final data = await ApiService.signUp(fullName: name.text.trim(), shopName: shop.text.trim(), email: email.text.trim(), password: password.text);
        if (data['requiresEmailConfirmation'] == true) {
          _msg('حساب ساخته شد. ایمیل خود را تأیید کنید و سپس وارد شوید.');
          setState(() => register = false);
        } else { widget.onLoggedIn(); }
      } else { await ApiService.login(email.text.trim(), password.text); widget.onLoggedIn(); }
    } catch (e) { _msg(e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => loading = false); }
  }
  void _msg(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Icon(Icons.storefront, size: 72), SizedBox(height: 12),
        Text('بازارک', textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
        Text('دستیار فروش هوشمند افغانستان', textAlign: TextAlign.center), SizedBox(height: 28),
        if (register) ...[
          TextField(controller: name, decoration: const InputDecoration(labelText: 'نام شما', border: OutlineInputBorder())), SizedBox(height: 12),
          TextField(controller: shop, decoration: const InputDecoration(labelText: 'نام دکان / کسب‌وکار', border: OutlineInputBorder())), SizedBox(height: 12),
        ],
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'ایمیل', border: OutlineInputBorder())), SizedBox(height: 12),
        TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'رمز عبور', border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility : Icons.visibility_off)))),
        SizedBox(height: 18),
        FilledButton(onPressed: loading ? null : submit, child: Padding(padding: const EdgeInsets.all(13), child: loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator()) : Text(register ? 'ساخت حساب فروشنده' : 'ورود به بازارک'))),
        TextButton(onPressed: loading ? null : () => setState(() => register = !register), child: Text(register ? 'قبلاً حساب دارم؛ ورود' : 'حساب فروشنده ندارم؛ ثبت‌نام')),
      ]),
    )))),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> data = {}; Map<String, dynamic> vendor = {}; bool loading = true;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    try { final results = await Future.wait([ApiService.getDashboard(), ApiService.me()]); if (mounted) setState(() { data = results[0]; vendor = (results[1] as Map<String, dynamic>)['vendor'] ?? {}; loading = false; }); }
    catch (e) { if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); } }
  }
  Future<void> logout() async { await ApiService.logout(); if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const EntryScreen()), (_) => false); }
  @override Widget build(BuildContext context) {
    final shop = vendor['shop_name']?.toString() ?? 'دکان شما';
    return Scaffold(appBar: AppBar(title: Text(shop), actions: [IconButton(onPressed: logout, icon: const Icon(Icons.logout))]), body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(16), children: [
      Text('سلام ${vendor['full_name'] ?? ''} 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 6), const Text('امروز دکانت را هوشمندتر مدیریت کن.'), const SizedBox(height: 20),
      Row(children: [_stat('محصولات', '${data['productCount'] ?? 0}', Icons.inventory_2), const SizedBox(width: 10), _stat('سفارش‌ها', '${data['orderCount'] ?? 0}', Icons.shopping_bag)]), const SizedBox(height: 10),
      Row(children: [_stat('در انتظار', '${data['pendingOrders'] ?? 0}', Icons.pending_actions), const SizedBox(width: 10), _stat('فروش', '${data['totalSales'] ?? 0} افغانی', Icons.payments)]), const SizedBox(height: 24),
      _action('افزودن محصول', Icons.add_box, () => _addProduct()), _action('تولید آگهی با هوش مصنوعی', Icons.auto_awesome, () => _generateAd()),
      const SizedBox(height: 18), const Text('آخرین محصولات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      ...((data['recentProducts'] as List? ?? []).map((p) => Card(child: ListTile(leading: const Icon(Icons.inventory), title: Text('${p['title']}'), subtitle: Text('موجودی: ${p['stock']}'), trailing: Text('${p['price']} افغانی'))))),
    ])));
  }
  Widget _stat(String title, String value, IconData icon) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Icon(icon, size: 28), const SizedBox(height: 7), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center), Text(title)]))));
  Widget _action(String title, IconData icon, VoidCallback tap) => Card(child: ListTile(leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_left), onTap: tap));
  Future<void> _addProduct() async { final n = TextEditingController(), p = TextEditingController(), d = TextEditingController(), s = TextEditingController(text: '0'); final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('محصول جدید'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, decoration: const InputDecoration(labelText: 'نام محصول')), TextField(controller: p, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت (افغانی)')), TextField(controller: s, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'موجودی')), TextField(controller: d, decoration: const InputDecoration(labelText: 'توضیحات'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ثبت'))])); if (ok == true) { try { await ApiService.addProduct({'title': n.text, 'price': double.tryParse(p.text) ?? 0, 'stock': int.tryParse(s.text) ?? 0, 'description': d.text}); await load(); } catch (e) { _show(e); } } }
  Future<void> _generateAd() async { final n = TextEditingController(), d = TextEditingController(); final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('تولید آگهی هوشمند'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, decoration: const InputDecoration(labelText: 'نام محصول')), TextField(controller: d, decoration: const InputDecoration(labelText: 'توضیحات'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تولید'))])); if (ok == true) { showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator())); try { final ad = await ApiService.generateAd(n.text, d.text); if (mounted) { Navigator.pop(context); showDialog(context: context, builder: (_) => AlertDialog(title: const Text('آگهی آماده شد'), content: SingleChildScrollView(child: SelectableText(ad)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))])); } } catch (e) { if (mounted) Navigator.pop(context); _show(e); } } }
  void _show(Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
}
