Bazarek - Profile Image Fix

Changed files only:
- lib/main.dart
- backend/src/server.js
- pubspec.yaml

Fixes:
1. Flutter Web profile image picker no longer uses the optional resize/compression path that can trigger:
   "Could not load Blob from its URL. Has it been revoked?"
2. image_picker upgraded from 1.1.2 to 1.2.1.
3. Backend accepts image uploads whose multipart MIME type arrives as application/octet-stream and infers MIME from the extension.
4. Existing Supabase profile-avatars bucket is forced public so getPublicUrl() can actually be loaded by Web/APK.
5. Each upload gets a unique storage path and profile avatar_url is updated.
6. Avatar state is refreshed immediately in Flutter.

Do not change the existing manual payment flow. HesabPay remains disabled.

Deployment:
- Replace only these 3 files in the project.
- Push to GitHub.
- Let Render/Web build run normally.
- For Web, hard-refresh the browser after deployment.
