بازارک — همگام‌سازی کامل نسخه وب و پنل مدیریت

این بسته فقط فایل‌های تغییرکرده را دارد و کل پروژه نیست.

فایل‌ها:
- lib/main.dart
- lib/admin_panel_screen.dart
- backend/src/server.js
- supabase/migrations/202609100001_admin_moderation_finance_security.sql

تغییرات مهم:
- امکانات جدید پنل مدیریت به نسخه وب منتقل شده است.
- سفارش‌های ارتقا: نمایش نام/مشخصات کاربر، آگهی، تصویر آگهی و رسید/شماره پیگیری + امکان مشاهده آگهی و تأیید/رد.
- شکایات: نمایش گزارش‌دهنده، صاحب آگهی، شماره‌ها، آگهی و دلیل گزارش + رسیدگی کامل.
- در صورت تأیید تخلف: بستن آگهی، ارسال اخطار به صاحب آگهی و پیام تشکر به گزارش‌دهنده.
- داشبورد: کارت‌های قابل کلیک برای ورود مستقیم به بخش مربوطه.
- درآمد: فقط پرداخت‌های تأییدشده در درآمد حساب می‌شوند؛ مبلغ در انتظار جداگانه نمایش داده می‌شود.
- تراکنش‌ها: بایگانی تراکنش به جای حذف رکورد مالی اصلی.
- امنیت: ثبت و نمایش ورودهای موفق/ناموفق مدیریت.
- آپلود عکس پروفایل در Flutter Web: استفاده از readAsBytes و MultipartFile.fromBytes؛ مشکل image.path در Web برطرف شده است.
- جدول user_notifications و admin_login_events و ستون archive تراکنش‌ها در migration اضافه/تکمیل می‌شوند.

اعمال روی GitHub:
1) فایل‌های ZIP را در همان مسیرهای پروژه جایگزین کنید.
2) Commit و Push به branch main.
3) اگر Backend و Web هر دو Render Service متصل به همین repo/branch هستند، هر دو با Push دوباره deploy می‌شوند.
4) Build Command فعلی Web که در Render دارید را تغییر ندهید؛ همان flutter build web --release --base-href / کافی است.
5) اگر Auto Deploy خاموش است، در Render برای Web و Backend گزینه Manual Deploy > Deploy latest commit را بزنید.
6) migration زیر را یک‌بار در Supabase SQL Editor اجرا کنید، مگر اینکه قبلاً اجرا شده باشد:
   supabase/migrations/202609100001_admin_moderation_finance_security.sql

بعد از Deploy:
- سایت: https://bazarek-web.onrender.com/
- Backend: https://bazarek.onrender.com/
- برای عکس پروفایل، یک بار از حساب خارج و دوباره وارد شوید و سپس عکس را انتخاب کنید.
