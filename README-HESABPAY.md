# پرداخت آنلاین HesabPay در بازارک

سیستم پرداخت دستی فعلی حذف نشده است؛ کاربر هنگام خرید Boost می‌تواند «پرداخت دستی» یا «پرداخت آنلاین HesabPay» را انتخاب کند.

## تنظیمات Render
این متغیرها را در Environment Variables بک‌اند اضافه کنید:

- `HESABPAY_API_KEY` = کلید API حساب HesabPay
- `HESABPAY_ENV` = `sandbox` برای تست یا `production` برای پرداخت واقعی
- `BAZAREK_PUBLIC_URL` = `https://bazarek.onrender.com`

کلید API را داخل Flutter، index.html یا GitHub قرار ندهید.

## Supabase
فایل migration زیر را یک‌بار در SQL Editor اجرا کنید:
`supabase/migrations/202609100002_hesabpay_online_payments.sql`

## Webhook
بعد از فعال‌سازی HesabPay، این URL را در Developer Dashboard ثبت کنید:
`https://bazarek.onrender.com/api/payments/hesabpay/webhook`

رویدادهای `payment_success` و `payment_failure` را فعال کنید. بازارک قبل از تغییر وضعیت سفارش، امضای Webhook را با HesabPay بررسی می‌کند.

## روند
1. بازارک سفارش را با وضعیت pending ایجاد می‌کند.
2. بک‌اند بازارک Payment Session را از HesabPay می‌گیرد.
3. کاربر به Hosted Checkout منتقل می‌شود.
4. HesabPay نتیجه را به Webhook بازارک می‌فرستد.
5. پس از تأیید امضا و تطبیق مبلغ، Boost/اشتراک فعال می‌شود.

پرداخت دستی همچنان با شماره پیگیری و تأیید مدیر کار می‌کند.
