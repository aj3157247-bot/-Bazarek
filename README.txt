Bazarek WebView Shell - safe patch

Only the native Android shell and its APK GitHub Actions workflow are changed.
The Flutter Web app source under lib/ and backend/ is intentionally untouched.

The APK loads the existing live site:
https://bazarek-web.onrender.com/?bazarek_app=1&shell=android

This patch uses the Android system WebView directly, not Flutter WebView, to keep
APK size small and avoid the Flutter WebView gray/white-screen path.

Features retained:
- JavaScript / DOM storage / cookies
- image multi-selection
- camera capture
- tel/mailto/sms/whatsapp/geo links
- WebView back navigation
- friendly connection error + retry
- render-process recovery

IMPORTANT:
The package name remains com.bazarek.app. Do not publish this as an update to an
existing APK until its old package/applicationId is confirmed to be the same.
