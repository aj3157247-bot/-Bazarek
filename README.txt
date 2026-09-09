Bazarek v31 – Boost + Social Pages + Pashto Localization

Changed files only:
- lib/main.dart
- backend/src/server.js
- supabase/migrations/202609090003_boost_system.sql

Changes:
1) Boost UI is split into short-term single-listing Boosts and monthly/yearly all-listings Boosts.
2) Short-term prices: 24h=10 AFN, 3d=20 AFN, 7d=35 AFN. Each must be activated separately for a selected listing.
3) Global Boost prices: monthly=250 AFN, yearly=2200 AFN. They apply to all active listings of the seller after admin approval.
4) Boost ranking remains automatic: higher effective boost level gets higher listing priority.
5) Added social-pages category with YouTube, TikTok, Instagram, Facebook Page, Telegram, Snapchat, X and other.
6) Social-page listings can store an external URL and the detail page opens it directly.
7) Added public /api/translate endpoint using a free translation service fallback, and localized visible user-generated listing text into Pashto when the app language is Pashto. Translation is cached in-app.
8) Category, subcategory and province labels are localized to Pashto.
9) Chat and Add Listing screens now react immediately to the shared AuthService session instead of requiring a separate registration per section.

Deployment:
- Run the SQL migration in Supabase.
- Deploy backend/src/server.js to Render.
- Replace only lib/main.dart in the Flutter project.

No new Flutter dependency is introduced by this version.
