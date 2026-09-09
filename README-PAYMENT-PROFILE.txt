Bazarek – Payment + Profile Update

Changes:
1) Boost monthly = 300 AFN.
2) Boost yearly = 2500 AFN.
3) Boost checkout now loads payment information from Supabase table `payment_settings`.
4) Checkout explains exactly how to transfer money and enter the receipt/tracking number.
5) Card/account number can be copied from the dialog.
6) Profile page now lets the signed-in user select and upload a profile photo.

IMPORTANT – why the card was missing before:
The previous backend `/api/payment-info` endpoint read PAYMENT_* environment variables from Render, not a Supabase table. So adding a card somewhere in Supabase did not automatically make it appear in the app.

Run the new migration in Supabase:
supabase/migrations/202609090004_payment_settings_profile.sql

Then put your real payment details in the single row:

UPDATE public.payment_settings
SET
  bank_name = 'نام بانک',
  account_name = 'نام صاحب حساب',
  account_number = 'شماره حساب (اگر دارید)',
  card_number = 'شماره کارت واقعی بازارک',
  branch = '',
  swift_code = '',
  instructions = 'لطفاً مبلغ دقیق را انتقال دهید، رسید را نگه دارید و شماره پیگیری را در برنامه وارد کنید. پس از تأیید مدیریت، Boost فعال می‌شود.',
  updated_at = now()
WHERE id = 1;

Do NOT put the card number in the Flutter source code. Keep it in Supabase so it can be changed later without rebuilding the APK.

Deploy backend/src/server.js to Render and replace lib/main.dart in the Flutter project.

Profile photos:
The backend already creates/uses the public Supabase Storage bucket `profile-avatars` automatically when the first profile photo is uploaded. No manual bucket creation is required.
