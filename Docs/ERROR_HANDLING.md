# Error Handling Strategy - Log-o-logu

## 🟢 R — Requirements
- Graceful failure for all user actions
- User-friendly error messages (no technical jargon)
- Robust retry mechanisms for flaky networks

## 🟢 T — Implementation
- **Repository Layer**: Try-catch blocks wrapping all Firebase calls.
- **Centralized Logger**: Log events to Firebase Crashlytics for debugging.
- **UI Feedback**: Use Toasts/Snackbars for transient errors.

## 🟢 C — Handling Strategy
| Error | Handling |
| :--- | :--- |
| **Invite not found** | Show "Invalid QR" and deny entry |
| **Firestore timeout** | Automatic retry (3 times) with exponential backoff |
| **FCM failure** | Log error and continue (don't block entry flow) |
| **GPS disabled** | Prompt user to enable location for GeoFencing |
