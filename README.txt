Bazarek - Payment card number display fix

Changed file only:
- main.dart

Fix:
- Payment/card number is isolated in LTR direction so Arabic/Persian RTL layout cannot reverse its groups.
- Card number is displayed as a standalone value while the Persian/Pashto label remains RTL.
- Copy button copies the original card string unchanged.

Replace only lib/main.dart with this file.
