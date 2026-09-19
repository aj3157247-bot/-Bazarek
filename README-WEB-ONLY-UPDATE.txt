Bazarek — Website responsive marketplace UI update

Changed file:
- lib/main.dart

Scope:
- New responsive marketplace hero and listing-card grid are rendered only when kIsWeb is true.
- Web layout supports 2 columns on narrow/mobile screens, 3 on tablet, and 4–5 on wider desktop screens.
- Web content max width increased to 1440px.
- Existing non-web/Android listing layout is kept behind the non-web branch; no payment, auth, API, or database logic was intentionally changed.

Apply:
1. Extract this ZIP.
2. In the GitHub repository, open lib/main.dart and replace its full contents with this file.
   Do NOT upload it into a new nested folder.
3. Commit the change to the branch connected to the Render Web service.
4. In Render, deploy the latest commit for the WEBSITE service (Dockerfile.web / existing web build configuration).
5. Open the website in a private/incognito tab or hard-refresh to avoid cached Flutter Web assets.

Important:
- This project shares lib/main.dart between Flutter Web and Android. The new hero/grid are gated by kIsWeb so they are intended for the website only.
- Flutter build could not be run in this environment; confirm Render's Web build succeeds before considering it verified.
