Bazarek - Render Web Build Fix

مشکل اصلی:
در lib/main.dart کلاس _DetectedImageType و تابع _detectImageType داخل بدنه ApiService قرار گرفته بودند. Dart اجازه تعریف class در داخل class را نمی‌دهد و باعث می‌شد flutter build web با exit code 1 متوقف شود.

اصلاح:
کلاس _DetectedImageType و تابع _detectImageType به سطح فایل و قبل از ApiService منتقل شدند. هیچ قابلیت دیگری تغییر نکرده است.

فایل تغییرکرده:
- lib/main.dart

نسخه وب و APK هر دو از همین main.dart استفاده می‌کنند.

مراحل:
1. فقط lib/main.dart را در GitHub جایگزین کن.
2. Commit/Push کن.
3. Render پروژه Web را Deploy کن.
4. بعد از موفق شدن Web، همان commit برای Build APK هم استفاده شود.

Migration جدید Supabase برای این اصلاح لازم نیست.
