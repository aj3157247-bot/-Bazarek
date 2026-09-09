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
    try {
      return jsonDecode(r.body);
    } catch (_) {
      throw Exception('پاسخ نامعتبر از سرور (${r.statusCode})');
    }
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
  @override
  State<_AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<_AdminLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> _login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      _message('ایمیل و رمز عبور مدیر را وارد کنید.');
      return;
    }
    setState(() => loading = true);
    try {
      final token = await _AdminApi.login(email.text.trim(), password.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _AdminDashboard(token: token)));
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.red));

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ورود مدیریت بازارک')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.admin_panel_settings, size: 72),
                      const SizedBox(height: 16),
                      const Text('پنل مدیریت', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('ورود مدیر با اطلاعات امن ذخیره‌شده روی Render انجام می‌شود.', textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'ایمیل مدیر', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      TextField(controller: password, obscureText: obscure, onSubmitted: (_) => _login(), decoration: InputDecoration(labelText: 'رمز عبور', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => obscure = !obscure)))),
                      const SizedBox(height: 22),
                      SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(onPressed: loading ? null : _login, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login), label: Text(loading ? 'در حال ورود...' : 'ورود به پنل'))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _AdminDashboard extends StatefulWidget {
  final String token;
  const _AdminDashboard({required this.token});
  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController tabs;
  bool loading = true;
  String? loadError;
  Map<String, dynamic> stats = {};
  Map<String, dynamic> money = {};
  List<Map<String, dynamic>> users = [], products = [], reports = [], warnings = [];

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 6, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

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
      ]);
      if (!mounted) return;
      setState(() {
        stats = Map<String, dynamic>.from(results[0] as Map);
        users = List<Map<String, dynamic>>.from(results[1] as List);
        products = List<Map<String, dynamic>>.from(results[2] as List);
        reports = List<Map<String, dynamic>>.from(results[3] as List);
        warnings = List<Map<String, dynamic>>.from(results[4] as List);
        money = Map<String, dynamic>.from(results[5] as Map);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; loadError = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _run(Future<void> Function() action, {String success = 'عملیات با موفقیت انجام شد.'}) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success), backgroundColor: Colors.green));
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('حذف آگهی'), content: Text('آگهی «${p['title'] ?? ''}» حذف شود؟ این عملیات قابل برگشت نیست.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف'))]));
    if (ok == true) await _run(() => _AdminApi.delete('/admin/products/${p['id']}', widget.token), success: 'آگهی حذف شد.');
  }

  Future<void> _warnUser(Map<String, dynamic> u) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text('هشدار برای ${u['full_name'] ?? 'کاربر'}'), content: TextField(controller: c, maxLines: 4, decoration: const InputDecoration(labelText: 'متن هشدار', border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ارسال'))]));
    if (ok == true && c.text.trim().isNotEmpty) await _run(() => _AdminApi.post('/admin/users/${u['id']}/warnings', widget.token, {'message': c.text.trim()}), success: 'هشدار برای کاربر ثبت شد.');
    c.dispose();
  }

  Future<void> _blockUser(Map<String, dynamic> u) async {
    final blocked = u['is_blocked'] == true;
    final reason = TextEditingController(text: blocked ? '' : 'تخلف از قوانین بازارک');
    final days = TextEditingController(text: '7');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(blocked ? 'رفع مسدودی' : 'مسدود کردن کاربر'), content: blocked ? const Text('دسترسی این کاربر دوباره فعال شود؟') : Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: reason, decoration: const InputDecoration(labelText: 'دلیل')), const SizedBox(height: 12), TextField(controller: days, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مدت (روز، ۰ یعنی بدون تاریخ انقضا)'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(blocked ? 'رفع مسدودی' : 'مسدود کردن'))]));
    if (ok == true) await _run(() => _AdminApi.patch('/admin/users/${u['id']}/block', widget.token, {'blocked': !blocked, 'duration_days': int.tryParse(days.text) ?? 0, 'reason': reason.text.trim()}), success: blocked ? 'مسدودی رفع شد.' : 'کاربر مسدود شد.');
    reason.dispose(); days.dispose();
  }

  Future<void> _creditWallet(Map<String, dynamic> u) async {
    final amount = TextEditingController();
    final desc = TextEditingController(text: 'شارژ کیف پول توسط مدیریت');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('شارژ کیف پول'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ افغانی')), const SizedBox(height: 12), TextField(controller: desc, decoration: const InputDecoration(labelText: 'توضیح'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('شارژ'))]));
    if (ok == true) await _run(() => _AdminApi.post('/admin/wallets/${u['id']}/credit', widget.token, {'amount_afn': int.tryParse(amount.text) ?? 0, 'description': desc.text.trim()}), success: 'کیف پول شارژ شد.');
    amount.dispose(); desc.dispose();
  }

  Future<void> _promotion(Map<String, dynamic> p) async {
    final feature = TextEditingController(text: p['is_featured'] == true ? '7' : '0');
    final pin = TextEditingController(text: p['is_pinned'] == true ? '7' : '0');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('ویژه / پین آگهی'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: feature, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'روزهای ویژه')), const SizedBox(height: 12), TextField(controller: pin, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'روزهای پین'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره'))]));
    if (ok == true) await _run(() => _AdminApi.patch('/admin/products/${p['id']}/promotion', widget.token, {'feature_days': int.tryParse(feature.text) ?? 0, 'pin_days': int.tryParse(pin.text) ?? 0}), success: 'وضعیت ویژه/پین آگهی ذخیره شد.');
    feature.dispose(); pin.dispose();
  }

  Future<void> _reportStatus(Map<String, dynamic> r, String status) => _run(() => _AdminApi.patch('/admin/reports/${r['id']}', widget.token, {'status': status}), success: 'وضعیت گزارش تغییر کرد.');
  Future<void> _subscriptionStatus(Map<String, dynamic> s, String status) => _run(() => _AdminApi.patch('/admin/subscriptions/${s['id']}', widget.token, {'status': status}), success: 'وضعیت اشتراک تغییر کرد.');
  Future<void> _orderStatus(Map<String, dynamic> o, String status) => _run(() => _AdminApi.patch('/admin/promotions/orders/${o['id']}', widget.token, {'status': status}), success: 'وضعیت سفارش تغییر کرد.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت بازارک', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh), tooltip: 'به‌روزرسانی'), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.logout), tooltip: 'خروج')],
        bottom: TabBar(controller: tabs, isScrollable: true, tabs: const [Tab(text: 'داشبورد', icon: Icon(Icons.dashboard_outlined)), Tab(text: 'آگهی‌ها', icon: Icon(Icons.campaign_outlined)), Tab(text: 'کاربران', icon: Icon(Icons.people_outline)), Tab(text: 'شکایات', icon: Icon(Icons.report_problem_outlined)), Tab(text: 'هشدارها', icon: Icon(Icons.notifications_outlined)), Tab(text: 'مالی', icon: Icon(Icons.account_balance_wallet_outlined))]),
      ),
      body: loading ? const Center(child: CircularProgressIndicator()) : loadError != null ? _ErrorState(error: loadError!, retry: _loadAll) : TabBarView(controller: tabs, children: [_overview(), _products(), _users(), _reports(), _warnings(), _finance()]),
    );
  }

  Widget _overview() {
    final openReports = reports.where((x) => x['status'] == 'open').length;
    final blocked = users.where((x) => x['is_blocked'] == true).length;
    return RefreshIndicator(onRefresh: _loadAll, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('خلاصه وضعیت', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 14),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.45, children: [_stat('کاربران', stats['users'] ?? users.length, Icons.people), _stat('آگهی‌ها', stats['products'] ?? products.length, Icons.campaign), _stat('شکایات باز', openReports, Icons.report_problem), _stat('مسدودها', blocked, Icons.block)],),
      const SizedBox(height: 18), Card(child: ListTile(leading: const Icon(Icons.payments_outlined, size: 36), title: const Text('درآمد ثبت‌شده'), subtitle: Text('${money['revenue_afn'] ?? 0} افغانی'), trailing: const Icon(Icons.chevron_left))),
      Card(child: ListTile(leading: const Icon(Icons.pending_actions), title: const Text('سفارش‌های ارتقای آگهی'), subtitle: Text('${(money['orders'] as List?)?.where((x) => x is Map && x['status'] == 'pending').length ?? 0} مورد در انتظار بررسی'))),
      Card(child: ListTile(leading: const Icon(Icons.subscriptions_outlined), title: const Text('اشتراک‌ها'), subtitle: Text('${(money['subscriptions'] as List?)?.length ?? 0} درخواست/اشتراک'))),
    ]));
  }

  Widget _stat(String title, dynamic value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 4),
                    Text(
                      '$value',
                      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _products() => _searchableList(products, 'آگهی‌ای وجود ندارد', (p) => Card(child: ListTile(leading: _productImage(p), title: Text(p['title']?.toString() ?? 'بدون عنوان', maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text('${p['price'] ?? 0} افغانی • ${p['category'] ?? ''}\n${p['is_active'] == true ? 'فعال' : 'غیرفعال'}${p['is_featured'] == true ? ' • ویژه' : ''}${p['is_pinned'] == true ? ' • پین' : ''}'), isThreeLine: true, trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'status') _run(() => _AdminApi.patch('/admin/products/${p['id']}/status', widget.token, {'is_active': p['is_active'] != true}), success: p['is_active'] == true ? 'آگهی غیرفعال شد.' : 'آگهی فعال شد.'); if (v == 'promotion') _promotion(p); if (v == 'delete') _confirmDelete(p); }, itemBuilder: (_) => [PopupMenuItem(value: 'status', child: Text(p['is_active'] == true ? 'غیرفعال کردن' : 'فعال کردن')), const PopupMenuItem(value: 'promotion', child: Text('ویژه / پین')), const PopupMenuItem(value: 'delete', child: Text('حذف آگهی'))]))));

  Widget _users() => _searchableList(users, 'کاربری وجود ندارد', (u) => Card(child: ListTile(leading: CircleAvatar(child: Text((u['full_name']?.toString() ?? 'ک').characters.first)), title: Text(u['full_name']?.toString().isNotEmpty == true ? u['full_name'] : 'کاربر بدون نام'), subtitle: Text('${u['phone'] ?? ''}\n${u['city'] ?? ''}${u['is_blocked'] == true ? '\n🚫 مسدود: ${u['block_reason'] ?? ''}' : ''}'), isThreeLine: true, trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'block') _blockUser(u); if (v == 'warn') _warnUser(u); if (v == 'wallet') _creditWallet(u); }, itemBuilder: (_) => [PopupMenuItem(value: 'block', child: Text(u['is_blocked'] == true ? 'رفع مسدودی' : 'مسدود کردن')), const PopupMenuItem(value: 'warn', child: Text('ارسال هشدار')), const PopupMenuItem(value: 'wallet', child: Text('شارژ کیف پول'))]))));

  Widget _reports() => _searchableList(
        reports,
        'گزارشی ثبت نشده است',
        (r) => Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.report_problem_outlined),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('گزارش آگهی', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    _statusChip(r['status']?.toString() ?? 'open'),
                  ],
                ),
                const SizedBox(height: 10),
                Text('دلیل: ${r['reason'] ?? '-'}'),
                Text('آگهی: ${r['listing_id'] ?? '-'}'),
                Text('گزارش‌دهنده: ${r['reporter_id'] ?? '-'}'),
                Text('تاریخ: ${r['created_at'] ?? '-'}'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (r['status'] != 'reviewed')
                      OutlinedButton(
                        onPressed: () => _reportStatus(r, 'reviewed'),
                        child: const Text('بررسی‌شده'),
                      ),
                    if (r['status'] != 'dismissed')
                      OutlinedButton(
                        onPressed: () => _reportStatus(r, 'dismissed'),
                        child: const Text('رد کردن'),
                      ),
                    if (r['status'] != 'open')
                      TextButton(
                        onPressed: () => _reportStatus(r, 'open'),
                        child: const Text('بازگردانی به باز'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _warnings() => _searchableList(warnings, 'هشداری ثبت نشده است', (w) => Card(child: ListTile(leading: const Icon(Icons.warning_amber_outlined), title: Text(w['message']?.toString() ?? '-'), subtitle: Text('کاربر: ${w['user_id'] ?? '-'}\n${w['created_at'] ?? '-'}'), isThreeLine: true)));

  Widget _finance() {
    final orders = List<Map<String, dynamic>>.from((money['orders'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    final subs = List<Map<String, dynamic>>.from((money['subscriptions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    final tx = List<Map<String, dynamic>>.from((money['transactions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    return RefreshIndicator(onRefresh: _loadAll, child: ListView(padding: const EdgeInsets.all(12), children: [
      Card(child: ListTile(title: const Text('درآمد کل', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${money['revenue_afn'] ?? 0} افغانی', style: const TextStyle(fontSize: 22)))),
      const Padding(padding: EdgeInsets.fromLTRB(4, 12, 4, 6), child: Text('سفارش‌های ارتقا', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
      if (orders.isEmpty) const Card(child: ListTile(title: Text('سفارشی وجود ندارد'))),
      ...orders.take(100).map((o) => Card(child: ListTile(title: Text('${o['amount_afn'] ?? 0} افغانی • ${o['status'] ?? ''}'), subtitle: Text('کاربر: ${o['user_id'] ?? '-'}\nآگهی: ${o['listing_id'] ?? '-'}\nرسید: ${o['payment_reference'] ?? '-'}'), isThreeLine: true, trailing: o['status'] == 'pending' ? PopupMenuButton<String>(onSelected: (v) => _orderStatus(o, v), itemBuilder: (_) => const [PopupMenuItem(value: 'paid', child: Text('تأیید پرداخت')), PopupMenuItem(value: 'rejected', child: Text('رد پرداخت')), PopupMenuItem(value: 'cancelled', child: Text('لغو سفارش'))]) : null))),
      const Padding(padding: EdgeInsets.fromLTRB(4, 18, 4, 6), child: Text('اشتراک‌ها', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
      if (subs.isEmpty) const Card(child: ListTile(title: Text('اشتراکی وجود ندارد'))),
      ...subs.take(100).map((s) => Card(child: ListTile(title: Text('${s['plan'] ?? '-'} • ${s['price_afn'] ?? 0} افغانی • ${s['status'] ?? ''}'), subtitle: Text('کاربر: ${s['user_id'] ?? '-'}\nرسید: ${s['payment_reference'] ?? '-'}'), isThreeLine: true, trailing: s['status'] == 'pending' ? PopupMenuButton<String>(onSelected: (v) => _subscriptionStatus(s, v), itemBuilder: (_) => const [PopupMenuItem(value: 'active', child: Text('تأیید و فعال‌سازی')), PopupMenuItem(value: 'rejected', child: Text('رد درخواست')), PopupMenuItem(value: 'cancelled', child: Text('لغو'))]) : null))),
      const Padding(padding: EdgeInsets.fromLTRB(4, 18, 4, 6), child: Text('تراکنش‌های کیف پول', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
      ...tx.take(100).map((t) => Card(child: ListTile(title: Text('${t['type'] ?? '-'} • ${t['amount_afn'] ?? 0} افغانی'), subtitle: Text('کاربر: ${t['user_id'] ?? '-'}\n${t['description'] ?? ''}'), isThreeLine: true))),
    ]));
  }

  Widget _searchableList(List<Map<String, dynamic>> source, String empty, Widget Function(Map<String, dynamic>) builder) => _AdminListView(source: source, empty: empty, builder: builder);

  Widget _productImage(Map<String, dynamic> p) {
    String? url;
    try { final v = jsonDecode(p['image_url']?.toString() ?? ''); if (v is List && v.isNotEmpty) url = v.first.toString(); else if (p['image_url']?.toString().startsWith('http') == true) url = p['image_url'].toString(); } catch (_) {}
    return SizedBox(width: 64, height: 64, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: url != null ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined)) : const Icon(Icons.image_outlined)));
  }

  Widget _statusChip(String s) => Chip(label: Text(s == 'open' ? 'باز' : s == 'reviewed' ? 'بررسی‌شده' : 'ردشده'));
}

class _AdminListView extends StatefulWidget {
  final List<Map<String, dynamic>> source;
  final String empty;
  final Widget Function(Map<String, dynamic>) builder;
  const _AdminListView({required this.source, required this.empty, required this.builder});
  @override
  State<_AdminListView> createState() => _AdminListViewState();
}

class _AdminListViewState extends State<_AdminListView> {
  final search = TextEditingController();
  String q = '';
  @override
  void dispose() { search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final items = widget.source.where((x) => q.isEmpty || x.values.any((v) => v.toString().toLowerCase().contains(q.toLowerCase()))).toList();
    return Column(children: [Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 4), child: TextField(controller: search, onChanged: (v) => setState(() => q = v.trim()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'جستجو در این بخش...', border: OutlineInputBorder()))), Expanded(child: items.isEmpty ? Center(child: Text(widget.empty)) : ListView.builder(padding: const EdgeInsets.fromLTRB(12, 8, 12, 24), itemCount: items.length, itemBuilder: (_, i) => widget.builder(items[i])))]);
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback retry;
  const _ErrorState({required this.error, required this.retry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 56), const SizedBox(height: 12), Text(error, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('تلاش دوباره'))])));
}
