Bazarek – HesabPay reserved for future use

Current status:
- HesabPay is NOT active.
- Existing manual/bank-transfer payment flow is unchanged.
- HESABPAY_ENABLED defaults to false.
- Do not add a real API key yet.

When a verified merchant/API account is available, set HESABPAY_ENABLED=true and add HESABPAY_API_KEY on the backend only, then implement the approved payment-session/webhook flow.

Frontend note:
- The same Flutter lib/main.dart is used by the Android app and Flutter Web build, so the reserved payment-method API is available to both without introducing a visible payment option while disabled.
