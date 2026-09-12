Bazarek Automatic Boost Expiry - v36

Changes:
1. Boost duration starts ONLY when admin approves the promotion order (status=paid).
2. 24h / 3d / 7d listing Boosts automatically expire at their exact boost_until time.
3. Featured and pinned flags are also automatically cleared when their *_until time is reached.
4. Monthly/yearly seller Boost subscriptions automatically become expired after ends_at.
5. Backend runs an automatic cleanup every 30 seconds as a fallback.
6. Supabase migration adds a database function and, when pg_cron is enabled, a 1-minute scheduler.

Apply the SQL migration manually in Supabase SQL Editor:
supabase/migrations/202609120001_automatic_boost_expiry.sql

No Flutter/UI files are changed because the APK is a WebView shell and the Boost timing is a backend/database behavior shared by the website and APK.
