BAZAREK APK SHELL

The Android APK is intentionally a WebView shell.

Live source:
https://bazarek-web.onrender.com/

Important behavior:
- The APK loads the live Bazarek Web app instead of maintaining a second UI.
- HTTP cache is cleared on launch; local storage/session data is preserved.
- A cache-busting query is added to the initial request so a newly deployed Web build is preferred.
- Back navigation stays inside the WebView when possible.
- tel:, mailto:, sms:, whatsapp: and geo: links open in the appropriate external Android app.
- Image/file selection and camera capture are wired for WebView file inputs.
- Android release builds receive INTERNET, CAMERA and location permissions through CI.

Therefore normal UI/feature changes should be deployed to the Web service only; users should not need a new APK for those changes. APK updates are reserved for native-shell changes such as the launcher icon, WebView engine/plugin changes, permissions, or other Android-only capabilities.
