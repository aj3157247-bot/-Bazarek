Bazarek Web Build Fix 2

Changed files:
- lib/main.dart
- pubspec.yaml

Fixes the Render Web compile errors:
1. Imports kIsWeb from flutter/foundation.dart.
2. Uses PlatformFile.bytes only; PlatformFile has no readAsBytes() method.

Android/APK image picker flow remains image_picker-based and unchanged.
No Supabase migration is required.

After replacing the files in GitHub, deploy the Web Render service.
