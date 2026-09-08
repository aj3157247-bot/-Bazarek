ثبت‌نام با تأیید SMS

فایل‌های تغییرکرده:
- lib/main.dart
- lib/api_service.dart
- backend/src/server.js

Backend نیاز به این Environment Variables در Render دارد:
- TWILIO_ACCOUNT_SID
- TWILIO_AUTH_TOKEN
- TWILIO_VERIFY_SERVICE_SID

این سه مقدار باید از Twilio Verify گرفته شوند. بدون تنظیم سرویس SMS، کد واقعاً به تلفن ارسال نمی‌شود.

مراحل ثبت‌نام:
1. کاربر شماره افغانستان را وارد می‌کند.
2. سرور شماره را به +93 تبدیل می‌کند.
3. Twilio Verify کد SMS می‌فرستد.
4. کاربر کد را داخل برنامه وارد می‌کند.
5. فقط بعد از تأیید موفق، حساب Supabase ساخته و کاربر وارد می‌شود.
