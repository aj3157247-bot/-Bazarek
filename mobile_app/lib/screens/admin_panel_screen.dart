import 'package:flutter/material.dart';

/// Admin authentication must be moved to a server-side protected endpoint.
/// Credentials are intentionally not embedded in the APK.
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پنل مدیریت بازارک')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_outline, size: 64),
              SizedBox(height: 16),
              Text(
                'پنل مدیریت در نسخه امن بعدی فعال می‌شود.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'اطلاعات ورود مدیر عمداً داخل برنامه ذخیره نشده است.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
