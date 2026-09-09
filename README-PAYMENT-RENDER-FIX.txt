Bazarek – Payment / Boost Render Fix

این نسخه بخش پرداخت Boost را فقط به Environment Variables در Render متصل می‌کند.
Supabase برای نمایش اطلاعات پرداخت دیگر استفاده نمی‌شود.

در Render > Environment Variables این متغیرها را تنظیم کنید:

PAYMENT_BANK_NAME=نام بانک
PAYMENT_ACCOUNT_NAME=نام صاحب حساب
PAYMENT_ACCOUNT_NUMBER=شماره حساب (اختیاری)
PAYMENT_CARD_NUMBER=شماره کارت واقعی
PAYMENT_BANK_BRANCH=شعبه (اختیاری)
PAYMENT_INSTRUCTIONS=۱) مبلغ دقیق را به کارت بالا انتقال دهید.
۲) رسید یا شماره پیگیری را نگه دارید.
۳) شماره پیگیری را در برنامه وارد کنید.
۴) درخواست را ثبت کنید.
۵) پس از تأیید پرداخت توسط مدیریت، Boost فعال می‌شود.

مهم:
- PAYMENT_CARD_NUMBER باید دقیقاً شامل شماره کارت واقعی باشد.
- بعد از تغییر Environment Variables در Render، سرویس را Redeploy/Restart کنید.
- این نسخه چند نام قدیمی را هم می‌پذیرد: CARD_NUMBER، BANK_CARD_NUMBER، PAYMENT_CARD.
- قیمت Boost در این پروژه: ۱۰ / ۲۰ / ۳۵ افغانی برای کوتاه‌مدت و ۳۰۰ / ۲۵۰۰ افغانی برای ماهانه/سالانه است.
