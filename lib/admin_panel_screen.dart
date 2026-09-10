import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class _AdminApi {
  static const baseUrl = 'https://bazarek.onrender.com/api';
  static Map<String, String> headers([String? token]) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static dynamic decode(http.Response r) {
    try { return jsonDecode(r.body); } catch (_) { throw Exception('پاسخ نامعتبر از سرور (${r.statusCode})'); }
  }

  static Future<String> login(String email, String password) async {
    final r = await http.post(Uri.parse('$baseUrl/admin/login'), headers: headers(), body: jsonEncode({'email': email, 'password': password}));
    final d = decode(r);
    if (r.statusCode != 200) throw Exception(d is Map ? (d['error'] ?? 'ورود مدیریت ناموفق بود.') : 'ورود مدیریت ناموفق بود.');
    final token = d['token']?.toString();
    if (token == null || token.isEmpty) throw Exception('نشست مدیریت دریافت نشد.');
    return token;
  }

  static Future<List<Map<String, dynamic>>> list(String path, String token) async {
    final r = await http.get(Uri.parse('$baseUrl$path'), headers: headers(token));
    final d = decode(r);
    if (r.statusCode != 200) throw Exception(d is Map ? (d['error'] ?? 'خطا در دریافت اطلاعات.') : 'خطا در دریافت اطلاعات.');
    if (d is! List) throw Exception('ساختار پاسخ سرور نامعتبر است.');
    return d.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> map(String path, String token) async {
    final r = await http.get(Uri.parse('$baseUrl$path'), headers: headers(token));
    final d = decode(r);
    if (r.statusCode != 200) throw Exception(d is Map ? (d['error'] ?? 'خطا در دریافت اطلاعات.') : 'خطا در دریافت اطلاعات.');
    return Map<String, dynamic>.from(d as Map);
  }

  static Future<void> patch(String path, String token, Map<String, dynamic> body) async {
    final r = await http.patch(Uri.parse('$baseUrl$path'), headers: headers(token), body: jsonEncode(body));
    final d = decode(r);
    if (r.statusCode != 200) throw Exception(d is Map ? (d['error'] ?? 'عملیات ناموفق بود.') : 'عملیات ناموفق بود.');
  }

  static Future<void> post(String path, String token, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$baseUrl$path'), headers: headers(token), body: jsonEncode(body));
    final d = decode(r);
    if (r.statusCode != 200 && r.statusCode != 201) throw Exception(d is Map ? (d['error'] ?? 'عملیات ناموفق بود.') : 'عملیات ناموفق بود.');
  }

  static Future<void> delete(String path, String token) async {
    final r = await http.delete(Uri.parse('$baseUrl$path'), headers: headers(token));
    final d = decode(r);
    if (r.statusCode != 200) throw Exception(d is Map ? (d['error'] ?? 'حذف ناموفق بود.') : 'حذف ناموفق بود.');
  }
}

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});
  @override
  Widget build(BuildContext context) => const _AdminLoginScreen();
}

class _AdminLoginScreen extends StatefulWidget {
  const _AdminLoginScreen();
  @override State<_AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<_AdminLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> _login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) { _message('ایمیل و رمز عبور مدیر را وارد کنید.'); return; }
    setState(() => loading = true);
    try {
      final token = await _AdminApi.login(email.text.trim(), password.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _AdminDashboard(token: token)));
    } catch (e) { _message(e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => loading = false); }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.red));
  @override void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ورود مدیریت بازارک')),
    body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const Icon(Icons.admin_panel_settings, size: 72), const SizedBox(height: 16),
      const Text('پنل مدیریت', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      const Text('ورود مدیر با اطلاعات امن ذخیره‌شده روی Render انجام می‌شود.', textAlign: TextAlign.center), const SizedBox(height: 24),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'ایمیل مدیر', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
      const SizedBox(height: 16),
      TextField(controller: password, obscureText: obscure, onSubmitted: (_) => _login(), decoration: InputDecoration(labelText: 'رمز عبور', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => obscure = !obscure)))),
      const SizedBox(height: 22),
      SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(onPressed: loading ? null : _login, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login), label: Text(loading ? 'در حال ورود...' : 'ورود به پنل'))),
    ]))))),
  ));
}

class _AdminDashboard extends StatefulWidget {
  final String token;
  const _AdminDashboard({required this.token});
  @override State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController tabs;
  bool loading = true;
  String? loadError;
  Map<String, dynamic> stats = {}, money = {};
  List<Map<String, dynamic>> users = [], products = [], reports = [], warnings = [], securityEvents = [];

  @override void initState() { super.initState(); tabs = TabController(length: 7, vsync: this); _loadAll(); }
  @override void dispose() { tabs.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() { loading = true; loadError = null; });
    try {
      final results = await Future.wait([
        _AdminApi.map('/admin/stats', widget.token),
        _AdminApi.list('/admin/users', widget.token),
        _AdminApi.list('/admin/products', widget.token),
        _AdminApi.list('/admin/reports', widget.token),
        _AdminApi.list('/admin/warnings', widget.token),
        _AdminApi.map('/admin/monetization', widget.token),
        _AdminApi.list('/admin/security/events', widget.token),
      ]);
      if (!mounted) return;
      setState(() {
        stats = Map<String, dynamic>.from(results[0] as Map);
        users = List<Map<String, dynamic>>.from(results[1] as List);
        products = List<Map<String, dynamic>>.from(results[2] as List);
        reports = List<Map<String, dynamic>>.from(results[3] as List);
        warnings = List<Map<String, dynamic>>.from(results[4] as List);
        money = Map<String, dynamic>.from(results[5] as Map);
        securityEvents = List<Map<String, dynamic>>.from(results[6] as List);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; loadError = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _run(Future<void> Function() action, {String success = 'عملیات با موفقیت انجام شد.'}) async {
    try { await action(); if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success), backgroundColor: Colors.green)); await _loadAll(); }
    catch (e) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red)); }
  }

  String _person(Map<String, dynamic>? p, {String fallback = 'ناشناس'}) {
    if (p == null) return fallback;
    final shop = p['shop_name']?.toString().trim() ?? '';
    final name = p['full_name']?.toString().trim() ?? '';
    return shop.isNotEmpty ? '$shop ($name)' : (name.isNotEmpty ? name : fallback);
  }

  Future<void> _showListing(Map<String, dynamic> p) async {
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(p['title']?.toString() ?? 'آگهی'),
      content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _productImage(p, height: 210, width: double.infinity), const SizedBox(height: 12),
        Text('${p['price'] ?? 0} افغانی', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        Text('دسته: ${p['category'] ?? '-'}${p['subcategory']?.toString().isNotEmpty == true ? ' / ${p['subcategory']}' : ''}'),
        Text('ولایت: ${p['province'] ?? '-'}'), const SizedBox(height: 8),
        Text(p['description']?.toString() ?? '-', maxLines: 12, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10), Text('وضعیت: ${p['is_active'] == true ? 'فعال' : 'بسته/غیرفعال'}'),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))],
    ));
  }

  Future<void> _confirmDelete(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('حذف آگهی'), content: Text('آگهی «${p['title'] ?? ''}» حذف شود؟ این عملیات قابل برگشت نیست.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف'))]));
    if (ok == true) await _run(() => _AdminApi.delete('/admin/products/${p['id']}', widget.token), success: 'آگهی حذف شد.');
  }

  Future<void> _warnUser(Map<String, dynamic> u, {String? preset}) async {
    final c = TextEditingController(text: preset ?? 'لطفاً قوانین بازارک را رعایت کنید.');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text('هشدار برای ${_person(u)}'), content: TextField(controller: c, maxLines: 5, decoration: const InputDecoration(labelText: 'متن هشدار', border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ارسال'))]));
    if (ok == true && c.text.trim().isNotEmpty) await _run(() => _AdminApi.post('/admin/users/${u['id']}/warnings', widget.token, {'message': c.text.trim()}), success: 'هشدار برای کاربر ثبت شد.');
    c.dispose();
  }

  Future<void> _blockUser(Map<String, dynamic> u) async {
    final blocked = u['is_blocked'] == true;
    final reason = TextEditingController(text: blocked ? '' : 'تخلف از قوانین بازارک');
    final days = TextEditingController(text: '7');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(blocked ? 'رفع مسدودی' : 'مسدود کردن کاربر'), content: blocked ? const Text('دسترسی این کاربر دوباره فعال شود؟') : Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: reason, decoration: const InputDecoration(labelText: 'دلیل')), const SizedBox(height: 10), TextField(controller: days, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مدت (روز)؛ صفر = دائمی'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(blocked ? 'رفع مسدودی' : 'مسدود کردن'))]));
    if (ok == true) await _run(() => _AdminApi.patch('/admin/users/${u['id']}/block', widget.token, {'blocked': !blocked, 'duration_days': int.tryParse(days.text) ?? 0, 'reason': reason.text.trim()}), success: blocked ? 'مسدودی رفع شد.' : 'کاربر مسدود شد.');
    reason.dispose(); days.dispose();
  }

  Future<void> _creditWallet(Map<String, dynamic> u) async {
    final amount = TextEditingController(); final desc = TextEditingController(text: 'شارژ کیف پول توسط مدیریت');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text('شارژ کیف پول ${_person(u)}'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ افغانی')), const SizedBox(height: 10), TextField(controller: desc, decoration: const InputDecoration(labelText: 'توضیح'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('شارژ'))]));
    if (ok == true) await _run(() => _AdminApi.post('/admin/wallets/${u['id']}/credit', widget.token, {'amount_afn': int.tryParse(amount.text) ?? 0, 'description': desc.text.trim()}), success: 'کیف پول شارژ شد.');
    amount.dispose(); desc.dispose();
  }

  Future<void> _promotion(Map<String, dynamic> p) async {
    final feature = TextEditingController(text: p['is_featured'] == true ? '7' : '0'); final pin = TextEditingController(text: p['is_pinned'] == true ? '7' : '0');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('ویژه / پین آگهی'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: feature, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'روزهای ویژه')), const SizedBox(height: 12), TextField(controller: pin, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'روزهای پین'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره'))]));
    if (ok == true) await _run(() => _AdminApi.patch('/admin/products/${p['id']}/promotion', widget.token, {'feature_days': int.tryParse(feature.text) ?? 0, 'pin_days': int.tryParse(pin.text) ?? 0}), success: 'وضعیت ویژه/پین ذخیره شد.');
    feature.dispose(); pin.dispose();
  }

  Future<void> _reportAction(Map<String, dynamic> r) async {
    final listing = r['listing'] is Map ? Map<String, dynamic>.from(r['listing']) : null;
    final owner = r['listing_owner'] is Map ? Map<String, dynamic>.from(r['listing_owner']) : null;
    final reporter = r['reporter'] is Map ? Map<String, dynamic>.from(r['reporter']) : null;
    bool disable = false, thank = false, sendWarning = false;
    final warning = TextEditingController(text: 'آگهی شما به دلیل نقض قوانین بازارک بررسی و غیرفعال شد. لطفاً پیش از انتشار بعدی قوانین را رعایت کنید.');
    final note = TextEditingController();
    final valid = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
      title: const Text('رسیدگی به گزارش'),
      content: SizedBox(width: 560, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (listing != null) _productImage(listing, height: 180, width: double.infinity),
        const SizedBox(height: 10), Text('آگهی: ${listing?['title'] ?? r['listing_id'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('صاحب آگهی: ${_person(owner)}'), Text('شماره صاحب آگهی: ${owner?['phone'] ?? '-'}'),
        Text('گزارش‌دهنده: ${_person(reporter)}'), Text('شماره گزارش‌دهنده: ${reporter?['phone'] ?? '-'}'),
        const SizedBox(height: 8), Text('دلیل گزارش: ${r['reason'] ?? '-'}'), const SizedBox(height: 12),
        CheckboxListTile(value: disable, onChanged: (v) => setLocal(() => disable = v == true), contentPadding: EdgeInsets.zero, title: const Text('اگر تخلف تأیید شد، آگهی را ببند')),
        CheckboxListTile(value: sendWarning, onChanged: (v) => setLocal(() => sendWarning = v == true), contentPadding: EdgeInsets.zero, title: const Text('برای صاحب آگهی اخطار ارسال شود')),
        CheckboxListTile(value: thank, onChanged: (v) => setLocal(() => thank = v == true), contentPadding: EdgeInsets.zero, title: Text('اگر گزارش درست بود، از گزارش‌دهنده تشکر کن${reporter == null ? ' (اطلاعات کاربر موجود نیست)' : ''}')),
        if (sendWarning) TextField(controller: warning, maxLines: 4, decoration: const InputDecoration(labelText: 'متن هشدار', border: OutlineInputBorder())),
        const SizedBox(height: 10), TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'یادداشت رسیدگی مدیر', border: OutlineInputBorder())),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت رسیدگی'))],
    )));
    if (valid == true) {
      await _run(() => _AdminApi.post('/admin/reports/${r['id']}/action', widget.token, {
        'status': 'reviewed', 'disable_listing': disable, 'thank_reporter': thank,
        'warning_message': sendWarning ? warning.text.trim() : '', 'resolution_note': note.text.trim()
      }), success: 'گزارش رسیدگی و اقدامات انتخاب‌شده ثبت شد.');
    }
    warning.dispose(); note.dispose();
  }

  Future<void> _orderStatus(Map<String, dynamic> o, String status) => _run(() => _AdminApi.patch('/admin/promotions/orders/${o['id']}', widget.token, {'status': status}), success: status == 'paid' ? 'پرداخت تأیید و ارتقا فعال شد.' : 'وضعیت سفارش تغییر کرد.');
  Future<void> _subscriptionStatus(Map<String, dynamic> s, String status) => _run(() => _AdminApi.patch('/admin/subscriptions/${s['id']}', widget.token, {'status': status}), success: status == 'active' ? 'اشتراک تأیید و فعال شد.' : 'وضعیت اشتراک تغییر کرد.');
  Future<void> _archiveTransaction(Map<String, dynamic> t) => _run(() => _AdminApi.patch('/admin/transactions/${t['id']}/archive', widget.token, {}), success: 'تراکنش بایگانی شد.');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('مدیریت بازارک', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh), tooltip: 'به‌روزرسانی'), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.logout), tooltip: 'خروج')],
      bottom: TabBar(controller: tabs, isScrollable: true, tabs: const [
        Tab(text: 'داشبورد', icon: Icon(Icons.dashboard_outlined)), Tab(text: 'آگهی‌ها', icon: Icon(Icons.campaign_outlined)), Tab(text: 'کاربران', icon: Icon(Icons.people_outline)), Tab(text: 'شکایات', icon: Icon(Icons.report_problem_outlined)), Tab(text: 'هشدارها', icon: Icon(Icons.notifications_outlined)), Tab(text: 'مالی', icon: Icon(Icons.account_balance_wallet_outlined)), Tab(text: 'امنیت', icon: Icon(Icons.security_outlined)),
      ]),
    ),
    body: loading ? const Center(child: CircularProgressIndicator()) : loadError != null ? _ErrorState(error: loadError!, retry: _loadAll) : TabBarView(controller: tabs, children: [_overview(), _products(), _users(), _reports(), _warnings(), _finance(), _security()]),
  );

  void _go(int index) => tabs.animateTo(index);

  Widget _overview() {
    final openReports = reports.where((x) => x['status'] == 'open').length;
    final blocked = users.where((x) => x['is_blocked'] == true).length;
    final pendingOrders = (money['orders'] as List? ?? []).where((x) => x is Map && x['status'] == 'pending').length;
    final pendingSubs = (money['subscriptions'] as List? ?? []).where((x) => x is Map && x['status'] == 'pending').length;
    final revenue = NumberFormatLike.afn(money['revenue_afn']);
    return RefreshIndicator(onRefresh: _loadAll, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('خلاصه وضعیت', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 14),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.45, children: [
        _clickStat('کاربران', stats['users'] ?? users.length, Icons.people, 2), _clickStat('آگهی‌ها', stats['products'] ?? products.length, Icons.campaign, 1), _clickStat('شکایات باز', openReports, Icons.report_problem, 3), _clickStat('مسدودها', blocked, Icons.block, 2),
      ]),
      const SizedBox(height: 18),
      _dashboardCard(Icons.payments_outlined, 'درآمد ثبت‌شده', '$revenue افغانی', 5),
      _dashboardCard(Icons.pending_actions, 'سفارش‌های ارتقای آگهی', '$pendingOrders مورد در انتظار بررسی', 5),
      _dashboardCard(Icons.subscriptions_outlined, 'اشتراک‌ها', '$pendingSubs درخواست در انتظار بررسی', 5),
      _dashboardCard(Icons.report_gmailerrorred_outlined, 'شکایات', '$openReports گزارش باز', 3),
      _dashboardCard(Icons.security_outlined, 'امنیت مدیریت', '${securityEvents.length} ورود اخیر ثبت شده', 6),
      Card(child: ListTile(leading: const Icon(Icons.info_outline), title: const Text('منطق درآمد'), subtitle: Text('فقط پرداخت‌های تأییدشده در درآمد حساب می‌شوند. پرداخت‌های در انتظار بررسی: ${NumberFormatLike.afn(money['pending_afn'])} افغانی.'))),
    ]));
  }

  Widget _clickStat(String title, dynamic value, IconData icon, int index) => InkWell(onTap: () => _go(index), borderRadius: BorderRadius.circular(16), child: _stat(title, value, icon));
  Widget _dashboardCard(IconData icon, String title, String subtitle, int index) => Card(child: InkWell(onTap: () => _go(index), borderRadius: BorderRadius.circular(16), child: ListTile(leading: Icon(icon, size: 36), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_left))));
  Widget _stat(String title, dynamic value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Icon(icon, size: 32), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), const SizedBox(height: 4), Text('$value', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold))]))])));

  Widget _products() => _searchableList(products, 'آگهی‌ای وجود ندارد', (p) => Card(child: ListTile(leading: _productImage(p), onTap: () => _showListing(p), title: Text(p['title']?.toString() ?? 'بدون عنوان', maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text('${p['price'] ?? 0} افغانی • ${p['province'] ?? ''}\n${p['is_active'] == true ? 'فعال' : 'غیرفعال'}${p['is_featured'] == true ? ' • ویژه' : ''}${p['is_pinned'] == true ? ' • پین' : ''}'), isThreeLine: true, trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'view') _showListing(p); if (v == 'status') _run(() => _AdminApi.patch('/admin/products/${p['id']}/status', widget.token, {'is_active': p['is_active'] != true}), success: p['is_active'] == true ? 'آگهی غیرفعال شد.' : 'آگهی فعال شد.'); if (v == 'promotion') _promotion(p); if (v == 'delete') _confirmDelete(p); }, itemBuilder: (_) => [const PopupMenuItem(value: 'view', child: Text('مشاهده آگهی')), PopupMenuItem(value: 'status', child: Text(p['is_active'] == true ? 'غیرفعال کردن' : 'فعال کردن')), const PopupMenuItem(value: 'promotion', child: Text('ویژه / پین')), const PopupMenuItem(value: 'delete', child: Text('حذف آگهی'))]))));

  Widget _users() => _searchableList(users, 'کاربری وجود ندارد', (u) => Card(child: ListTile(leading: CircleAvatar(child: Text((_person(u).isEmpty ? 'ک' : _person(u)).characters.first)), title: Text(_person(u)), subtitle: Text('${u['phone'] ?? ''}\n${u['city'] ?? ''}${u['is_blocked'] == true ? '\n🚫 مسدود: ${u['block_reason'] ?? ''}' : ''}'), isThreeLine: true, trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'block') _blockUser(u); if (v == 'warn') _warnUser(u); if (v == 'wallet') _creditWallet(u); }, itemBuilder: (_) => [PopupMenuItem(value: 'block', child: Text(u['is_blocked'] == true ? 'رفع مسدودی' : 'مسدود کردن')), const PopupMenuItem(value: 'warn', child: Text('ارسال هشدار')), const PopupMenuItem(value: 'wallet', child: Text('شارژ کیف پول'))]))));

  Widget _reports() => _searchableList(reports, 'گزارشی ثبت نشده است', (r) {
    final listing = r['listing'] is Map ? Map<String, dynamic>.from(r['listing']) : null;
    final owner = r['listing_owner'] is Map ? Map<String, dynamic>.from(r['listing_owner']) : null;
    final reporter = r['reporter'] is Map ? Map<String, dynamic>.from(r['reporter']) : null;
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [if (listing != null) _productImage(listing, height: 70, width: 70) else const Icon(Icons.report_problem_outlined, size: 38), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(listing?['title']?.toString() ?? 'آگهی حذف شده/نامشخص', style: const TextStyle(fontWeight: FontWeight.bold)), Text('صاحب: ${_person(owner)}'), Text('گزارش‌دهنده: ${_person(reporter)}')])), _statusChip(r['status']?.toString() ?? 'open')]),
      const SizedBox(height: 8), Text('دلیل: ${r['reason'] ?? '-'}'), Text('شماره صاحب: ${owner?['phone'] ?? '-'} • شماره گزارش‌دهنده: ${reporter?['phone'] ?? '-'}'), Text('تاریخ: ${r['created_at'] ?? '-'}'),
      const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: [FilledButton.icon(onPressed: () => _reportAction(r), icon: const Icon(Icons.gavel), label: const Text('رسیدگی کامل')), if (listing != null) OutlinedButton.icon(onPressed: () => _showListing(listing), icon: const Icon(Icons.visibility), label: const Text('مشاهده آگهی')), if (r['status'] != 'dismissed') TextButton(onPressed: () => _run(() => _AdminApi.patch('/admin/reports/${r['id']}', widget.token, {'status': 'dismissed'}), success: 'گزارش رد شد.'), child: const Text('رد گزارش'))]),
    ])));
  });

  Widget _warnings() => _searchableList(warnings, 'هشداری ثبت نشده است', (w) => Card(child: ListTile(leading: const Icon(Icons.warning_amber_outlined), title: Text(w['message']?.toString() ?? '-'), subtitle: Text('کاربر: ${w['user_id'] ?? '-'}\n${w['created_at'] ?? '-'}'), isThreeLine: true)));

  Widget _finance() {
    final orders = List<Map<String, dynamic>>.from((money['orders'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    final subs = List<Map<String, dynamic>>.from((money['subscriptions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    final tx = List<Map<String, dynamic>>.from((money['transactions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    return RefreshIndicator(onRefresh: _loadAll, child: ListView(padding: const EdgeInsets.all(12), children: [
      Card(child: ListTile(title: const Text('درآمد واقعی', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${NumberFormatLike.afn(money['revenue_afn'])} افغانی', style: const TextStyle(fontSize: 24)))),
      Card(child: ListTile(title: const Text('در انتظار تأیید'), subtitle: Text('${NumberFormatLike.afn(money['pending_afn'])} افغانی'), leading: const Icon(Icons.hourglass_top))),
      const Padding(padding: EdgeInsets.fromLTRB(4, 12, 4, 6), child: Text('سفارش‌های ارتقا', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
      if (orders.isEmpty) const Card(child: ListTile(title: Text('سفارشی وجود ندارد'))),
      ...orders.take(100).map((o) => Card(child: ListTile(onTap: () { final l = o['listing']; if (l is Map) _showListing(Map<String, dynamic>.from(l)); }, leading: o['listing'] is Map ? _productImage(Map<String, dynamic>.from(o['listing']), height: 58, width: 58) : const Icon(Icons.campaign), title: Text('${o['package']?['title'] ?? o['package_id'] ?? 'ارتقا'} • ${o['amount_afn'] ?? 0} افغانی'), subtitle: Text('کاربر: ${_person(o['user'] is Map ? Map<String, dynamic>.from(o['user']) : null)}\nآگهی: ${o['listing']?['title'] ?? o['listing_id'] ?? '-'}\nرسید/پیگیری: ${o['payment_reference'] ?? '-'}\n${o['created_at'] ?? '-'}'), isThreeLine: true, trailing: o['status'] == 'pending' ? PopupMenuButton<String>(onSelected: (v) => _orderStatus(o, v), itemBuilder: (_) => const [PopupMenuItem(value: 'paid', child: Text('تأیید پرداخت')), PopupMenuItem(value: 'rejected', child: Text('رد پرداخت')), PopupMenuItem(value: 'cancelled', child: Text('لغو سفارش'))]) : Chip(label: Text(o['status']?.toString() ?? '-'))))),
      const Padding(padding: EdgeInsets.fromLTRB(4, 18, 4, 6), child: Text('اشتراک‌ها', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
      ...subs.take(100).map((s) => Card(child: ListTile(title: Text('${s['plan'] ?? '-'} • ${s['price_afn'] ?? 0} افغانی • ${s['status'] ?? ''}'), subtitle: Text('کاربر: ${_person(s['user'] is Map ? Map<String, dynamic>.from(s['user']) : null)}\nرسید/پیگیری: ${s['payment_reference'] ?? '-'}'), isThreeLine: true, trailing: s['status'] == 'pending' ? PopupMenuButton<String>(onSelected: (v) => _subscriptionStatus(s, v), itemBuilder: (_) => const [PopupMenuItem(value: 'active', child: Text('تأیید و فعال‌سازی')), PopupMenuItem(value: 'rejected', child: Text('رد درخواست')), PopupMenuItem(value: 'cancelled', child: Text('لغو'))]) : null))),
      const Padding(padding: EdgeInsets.fromLTRB(4, 18, 4, 6), child: Text('تراکنش‌های کیف پول', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
      if (tx.isEmpty) const Card(child: ListTile(title: Text('تراکنش فعال وجود ندارد'))),
      ...tx.take(100).map((t) => Card(child: ListTile(title: Text('${t['type'] ?? '-'} • ${t['amount_afn'] ?? 0} افغانی'), subtitle: Text('کاربر: ${_person(t['user'] is Map ? Map<String, dynamic>.from(t['user']) : null)}\n${t['description'] ?? ''}\n${t['created_at'] ?? ''}'), isThreeLine: true, trailing: IconButton(tooltip: 'بایگانی', onPressed: () => _archiveTransaction(t), icon: const Icon(Icons.archive_outlined))))),
      const SizedBox(height: 8), const Text('تراکنش بایگانی‌شده از فهرست اصلی حذف می‌شود و برای جلوگیری از به‌هم‌ریختگی گزارش مالی، رکورد اصلی پاک نمی‌شود.'),
    ]));
  }

  Widget _security() => _searchableList(securityEvents, 'هنوز رویداد امنیتی ثبت نشده است', (e) => Card(child: ListTile(leading: Icon(e['success'] == true ? Icons.check_circle_outline : Icons.error_outline), title: Text(e['success'] == true ? 'ورود موفق مدیریت' : 'تلاش ناموفق ورود مدیریت'), subtitle: Text('ایمیل: ${e['email'] ?? '-'}\nIP: ${e['ip_address'] ?? '-'}\nتاریخ: ${e['created_at'] ?? '-'}'), isThreeLine: true)));

  Widget _searchableList(List<Map<String, dynamic>> source, String empty, Widget Function(Map<String, dynamic>) builder) => _AdminListView(source: source, empty: empty, builder: builder);

  Widget _productImage(Map<String, dynamic> p, {double? height, double? width}) {
    String? url;
    try { final v = jsonDecode(p['image_url']?.toString() ?? ''); if (v is List && v.isNotEmpty) url = v.first.toString(); else if (p['image_url']?.toString().startsWith('http') == true) url = p['image_url'].toString(); } catch (_) {}
    return SizedBox(width: width ?? 64, height: height ?? 64, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: url != null ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined)) : const Icon(Icons.image_outlined)));
  }

  Widget _statusChip(String s) => Chip(label: Text(s == 'open' ? 'باز' : s == 'reviewed' ? 'بررسی‌شده' : 'ردشده'));
}

class NumberFormatLike {
  static String afn(dynamic value) {
    final n = num.tryParse(value?.toString() ?? '') ?? 0;
    return n.toStringAsFixed(n % 1 == 0 ? 0 : 2).replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => ',');
  }
}

class _AdminListView extends StatefulWidget {
  final List<Map<String, dynamic>> source; final String empty; final Widget Function(Map<String, dynamic>) builder;
  const _AdminListView({required this.source, required this.empty, required this.builder});
  @override State<_AdminListView> createState() => _AdminListViewState();
}
class _AdminListViewState extends State<_AdminListView> {
  final search = TextEditingController(); String q = '';
  @override void dispose() { search.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final items = widget.source.where((x) => q.isEmpty || x.values.any((v) => v.toString().toLowerCase().contains(q.toLowerCase()))).toList();
    return Column(children: [Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 4), child: TextField(controller: search, onChanged: (v) => setState(() => q = v.trim()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'جستجو در این بخش...', border: OutlineInputBorder()))), Expanded(child: items.isEmpty ? Center(child: Text(widget.empty)) : ListView.builder(padding: const EdgeInsets.fromLTRB(12, 8, 12, 24), itemCount: items.length, itemBuilder: (_, i) => widget.builder(items[i]))) ]);
  }
}

class _ErrorState extends StatelessWidget {
  final String error; final VoidCallback retry;
  const _ErrorState({required this.error, required this.retry});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 56), const SizedBox(height: 12), Text(error, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('تلاش دوباره'))])));
}
