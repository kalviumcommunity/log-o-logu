# Log-O-Logu 🛡️

Smart Visitor Management System built with **Flutter** & **Firebase**. 

Digitalizing community security by replacing traditional logbooks with a verified, real-time digital entry system.

---

## 🚀 Key Features
- **Instant Digital Entry**: 5-second gate entry via QR scanning.
- **Pre-Approved Invites**: Residents generate QR codes for guests.
- **Real-Time Notifications**: Instant alerts for guest arrivals.
- **Searchable Logs**: Reliable digital trails for all visitors.
- **Role-Based Access**: Governance for Admins, Guards, and Residents.

---

## 🛠 Prerequisites

Before you begin, ensure you have the following installed:
- [Flutter (Stable Channel 3.40+)](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) / [VS Code](https://code.visualstudio.com/)
- [Firebase Account](https://console.firebase.google.com/)
- [Node.js & NPM](https://nodejs.org/) (Required for Firebase CLI)

---

## 📦 First-Time Setup (2026 Recommended)

The project core is located in the `/flutter` directory.

### 1️⃣ Prepare Environment
```bash
cd flutter
flutter pub get
```

### 2️⃣ Activate Firebase CLI
We recommend using the official CLI to avoid manual JSON management:
```bash
# 1. Install Firebase Tools (if not already installed)
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Activate FlutterFire CLI
dart pub global activate flutterfire_cli

# 4. Configure Firebase inside the flutter directory
flutterfire configure
```
*Note: This will automatically generate `lib/firebase_options.dart` and link your apps.*

### 3️⃣ Enable Firebase Services
In your Firebase Console, enable:
- **Authentication**: Email/Password.
- **Cloud Firestore**: Create a database.
- **Cloud Messaging**: Enable for push notifications.

---

## 🏃 Run Project
```bash
cd flutter
flutter run
```

---

## 🏗 Folder Architecture
The project follows a **Modular Clean Architecture**:
```text
flutter/lib/
 ├── core/          # Constants, global services, and utilities
 ├── features/      # Feature-specific logic (auth, logs, invite, etc.)
 ├── shared/        # Reusable widgets and models
 └── main.dart      # Application entry point
```

---

## 🆘 Troubleshooting & Environment Fixes
If you face the "Failed to start Dart CLI isolate" or Gradle errors:
1. **Reset Cache**: `flutter clean && rm -rf ~/.dart_tool && flutter pub get`
2. **Accept Licenses**: `flutter doctor --android-licenses`
3. **Check SDK Path**: Ensure `android/local.properties` points to a valid Android SDK.
4. **Update Gradle**: Verify `flutter/android/app/build.gradle` has `compileSdk 34`.

---
© 2026 Log-O-Logu Team. Built with ❤️ for safer communities.
