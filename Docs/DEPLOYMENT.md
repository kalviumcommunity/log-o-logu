# Deployment Plan - Log-o-logu

## 🟢 R — Requirements
- Stable production release environment
- CI/CD integration for Flutter and Firebase
- Secure environment variable management

## 🟢 T — Deployment Stack
- **Firebase Hosting**: For Admin Web Dashboard
- **Firebase Functions**: Node.js/TypeScript backend logic
- **Play Store / App Store**: Internal and production testing tracks

## 🟢 C — Deployment Steps
1. **Firebase Project Setup**: Create production and staging projects.
2. **Environment Config**: Setup `.env` files for Flutter and Firebase.
3. **Firestore Rules**: Deploy `firestore.rules` for security.
4. **Cloud Functions**: Deploy TypeScript functions using `firebase deploy --only functions`.
5. **Flutter Build**: Run `flutter build apk --release` or `ipa` for distribution.

## 🟢 R — Rollback Plan
- Maintain versioned history of Cloud Functions (v1, v2).
- Git tagging for every stable release.
- Backup of Firestore rules and indexes before deployment.
