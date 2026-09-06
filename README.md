# Bazarek — Smart Sales Assistant

مرحله ۲: سیستم حساب فروشنده و مدیریت محصولات.

## Backend environment
Set these variables on Render/server (never commit real values):
- SUPABASE_URL
- SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY
- GEMINI_API_KEY
- GEMINI_MODEL (optional)
- ADMIN_EMAIL
- ADMIN_PASSWORD
- ADMIN_SESSION_SECRET

## Supabase
Run migrations in order:
1. `supabase/migrations/202609060001_bazarek_schema.sql`
2. `supabase/migrations/202609060002_products_upgrade.sql`

## Flutter
Run `flutter pub get`, then build the APK. The app stores only the Supabase access token locally and never embeds admin credentials.

## Security
Real `.env` files and API keys must stay out of Git. Rotate any key that was previously committed to a public repository.
