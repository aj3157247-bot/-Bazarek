بسته‌ی جذب فروشنده و صفحه‌های SEO شهر (ترتیب نصب)
1) فایل‌های functions/sell.js و functions/city.js را در پوشه‌ی functions ریپو بگذارید.
   - /sell : صفحه‌ی «فروشنده شوید» (عمومی، برای جستجو و جذب فروشنده).
   - /city/{شهر}/{دسته} : آگهی‌های همان شهر و دسته، مثل /city/kabul/vehicles.
     شهرها: kabul, herat, mazar, kandahar, jalalabad, kunduz
     اگر آگهی نباشد صفحه noindex می‌شود (گوگل صفحه‌ی خالی را ایندکس نمی‌کند).
2) functions/sitemap.xml.js را جایگزین کنید تا /sell و صفحه‌های شهر+دسته‌ی دارای آگهی هم در sitemap بیایند.
3) بعد از Deploy وب، این آدرس‌ها را باز کنید: bazarek.pages.dev/sell و bazarek.pages.dev/city/kabul/vehicles
نیازی به SQL یا بک‌اند نیست.
