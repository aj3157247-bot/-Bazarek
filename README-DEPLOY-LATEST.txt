بازارک — نسخه وب همگام با آخرین نسخه برنامه

این بسته فقط فایل‌های تغییرکرده را دارد و باید روی همان پروژه اصلی Bazarek جایگزین شوند.

فایل‌های اصلی:
- lib/main.dart
- lib/admin_panel_screen.dart
- backend/src/server.js
- supabase/migrations/202609100001_admin_moderation_finance_security.sql
- .github/workflows/build.yml
- Dockerfile.web
- nginx.web.conf
- render-web.yaml

کارهای لازم:
1) فایل‌ها را در ریشه همان repository بازارک قرار دهید و Commit/Push به branch main کنید.
2) migration جدید را یک بار در Supabase SQL Editor اجرا کنید:
   supabase/migrations/202609100001_admin_moderation_finance_security.sql
3) سرویس Backend در Render را Deploy کنید تا server.js جدید فعال شود.
4) سرویس bazarek-web در Render را Manual Deploy / Deploy latest commit کنید.
5) بعد از Deploy سایت را با Ctrl+F5 یا پاک کردن cache باز کنید.

این نسخه شامل:
- نمایش مشخصات صاحب آگهی و آگهی در سفارش‌های ارتقا
- نمایش تصویر و اطلاعات آگهی قبل از تأیید
- نمایش گزارش‌دهنده و صاحب آگهی در شکایات
- بازبینی آگهی، بستن آگهی، هشدار صاحب آگهی، تشکر از گزارش‌دهنده و یادداشت مدیریت
- اعلان‌های داخل برنامه با امکان خواندن و حذف
- کارت‌های داشبورد قابل کلیک
- درآمد فقط از پرداخت‌های تأییدشده + مبلغ در انتظار تأیید
- بایگانی تراکنش‌ها بدون حذف رکورد مالی
- ثبت رویدادهای ورود مدیریت برای امنیت
- آپلود عکس پروفایل در Flutter Web با bytes برای رفع مشکل Blob URL
