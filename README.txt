Bazarek Fix 37

1) Admin panel now shows Boost remaining time and exact approval/start time; it refreshes the countdown every 30 seconds.
2) Admin monetization endpoint now returns Boost/Featured/Pinned timestamps for each promotion order.
3) Home page no longer exposes raw browser errors such as "ClientException: Failed to fetch" when internet is unavailable. It shows a friendly Persian/Pashto connection message instead.

Changed files only:
- lib/main.dart
- lib/admin_panel_screen.dart
- backend/src/server.js

The existing automatic Boost expiry worker from Fix 36 is preserved in server.js.
