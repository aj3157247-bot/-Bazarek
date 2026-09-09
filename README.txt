Bazarek - Boost + Auth + Categories fix

Changed files only:
- lib/main.dart
- backend/src/server.js
- supabase/migrations/202609090003_boost_system.sql

What this fixes/adds:
1) One successful login/register is shared across ثبت آگهی, گفتگو, آگهی‌های من and Boost. Auth state is refreshed across the whole app.
2) آگهی‌های من now loads the user's real ads from backend and shows a 🚀 بوست آگهی button for each ad.
3) Boost catalog:
   - ⚡ توربو 24h: 20 AFN, one ad
   - 🔥 انفجاری 3d: 40 AFN, one ad
   - 💥 قدرتی 7d: 70 AFN, one ad
   - 👑 ماهانه: 400 AFN, all active ads
   - 🏆 سالانه: 3500 AFN, all active ads
4) Listing ranking is automatic: annual global boost level 5 > monthly level 4 > short-term power level 3 > explosive level 2 > turbo level 1 > normal.
5) Boosted listings receive special labels such as ⚡ توربو, 🔥 انفجاری, 💥 قدرتی, 👑 فروشنده ویژه, 🏆 فروشنده طلایی.
6) Categories on Home are tappable. Opening a category shows its subcategories; selecting a subcategory loads all active ads for that exact subcategory.
7) Backend /api/listings supports subcategory filtering and calculates global boost priority from active boost subscriptions.
8) The Supabase migration adds boost fields, updates the promotion package catalog, and permits boost_monthly/boost_yearly subscriptions.

IMPORTANT:
Run the new SQL migration in Supabase before deploying the backend, then redeploy backend on Render.
The existing manual payment flow remains: user enters transfer/reference number, then admin approves the order/subscription; ranking activates after approval.
