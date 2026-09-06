import 'package:flutter/material.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoggedIn = false;

  void login() {
    if (_emailController.text == "abdullahjafari712@gmail.com" &&
        _passwordController.text == "05050505") {
      setState(() {
        isLoggedIn = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("اطلاعات ورود ادمین اشتباه است!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("پنل مدیریت سیستم")),
      body: !isLoggedIn
          ? Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: "ایمیل ادمین"),
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "رمز عبور"),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: login,
                    child: Text("ورود به پنل ادمین"),
                  )
                ],
              ),
            )
          : ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                Card(
                  child: ListTile(
                    title: Text("تعداد کاربران کل"),
                    trailing: Text("1,250", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text("درآمد این ماه (افغانی)"),
                    trailing: Text("102,000 AFN", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text("مصرف کل AI"),
                    trailing: Text("8,450 درخواست"),
                  ),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.price_change),
                  title: Text("تنظیم قیمت پلن‌ها"),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.block),
                  title: Text("مسدودسازی کاربر"),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.notification_important),
                  title: Text("ارسال اعلان عمومی به فروشندگان"),
                  onTap: () {},
                ),
              ],
            ),
    );
  }
}
