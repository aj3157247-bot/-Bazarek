Bazarek Web - همسان‌سازی نسخه وب با APK

این Patch فقط برای رساندن نسخه Web به همان وضعیت فعلی APK آماده شده است.

تغییرات:
- دسته «فروشگاه‌ها و کسب‌وکارها» و زیر‌دسته‌های آن حفظ شده است.
- خطای Web عکس پروفایل «Could not load Blob from its URL» رفع شده است.
- در Web برای عکس پروفایل از file_picker استفاده می‌شود تا bytes واقعی فایل دریافت شود.
- در Android/iOS همان image_picker قبلی حفظ شده و رفتار APK تغییر نمی‌کند.
- backend و Supabase migration تغییر نکرده‌اند.

فایل‌ها:
- lib/main.dart
- pubspec.yaml

بعد از قرار دادن این دو فایل در GitHub، در سرویس Web Render یک Deploy جدید انجام دهید؛ ترجیحاً Clear build cache & deploy.
