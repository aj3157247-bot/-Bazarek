Bazarek final patch: profile image upload + Afghan stores category

Changed files:
- lib/main.dart: robust image detection/upload for Web + Android and new stores category with subcategories.
- backend/src/server.js: accepts client image MIME/extension headers and AVIF; keeps Supabase Storage profile avatar flow.
- pubspec.yaml: image_picker 1.2.3.

Deployment:
1. Replace these files in the project.
2. Push to GitHub.
3. Let the Web build on Render complete.
4. Build a new APK from the same source.
5. Hard refresh the website after deployment.

Manual bank-transfer payment flow is not changed.
