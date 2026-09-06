# بازارک — دستیار فروش هوشمند افغانستان

نسخه MVP شامل ثبت‌نام/ورود فروشنده، داشبورد، محصولات و تولید آگهی با AI است.

## راه‌اندازی امن Backend

1. وارد `backend/` شوید.
2. `backend/.env.example` را به `.env` کپی کنید.
3. مقدارهای `SUPABASE_URL`، `SUPABASE_KEY` و `GEMINI_API_KEY` را فقط در محیط سرور/Render وارد کنید.
4. در Supabase، فایل `backend/supabase_schema.sql` را یک‌بار در SQL Editor اجرا کنید.
5. سپس:

```bash
npm install
npm start
```

**هرگز `backend/.env` یا کلیدهای خصوصی را در GitHub commit نکنید.**

## Flutter

آدرس Backend از طریق `--dart-define` قابل تغییر است:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://YOUR-BACKEND.example.com/api
```

برای GitHub Actions نیز همین متغیر را به صورت Secret/Variable تنظیم کنید.
