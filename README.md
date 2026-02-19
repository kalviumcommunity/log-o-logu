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
- [Flutter (Stable Channel)](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) / [VS Code](https://code.visualstudio.com/)
- [Firebase account](https://console.firebase.google.com/)
- Android SDK (installed via Android Studio)

---

## 📦 First-Time Setup

### 1️⃣ Clone Repository
```bash
git clone <repo-url>
cd log-o-logu
```

### 2️⃣ Install Dependencies
```bash
flutter pub get
```

### 3️⃣ Setup Firebase
1.  Create a project in the [Firebase Console](https://console.firebase.google.com/).
2.  Register a new **Android app**:
    - Package name: `com.example.logologu`
    - Download `google-services.json`.
    - Place it inside `android/app/`.
3.  Register a new **iOS app** (Optional):
    - Download `GoogleService-Info.plist`.
    - Place it inside `ios/Runner/`.

### 4️⃣ Enable Firebase Services
In your Firebase Console, enable the following:
- **Authentication**: Enable Email/Password or Phone.
- **Cloud Firestore**: Create a database in production or test mode.
- **Cloud Messaging**: Enable for push notifications.

---

## 🏃 Run Project
```bash
flutter run
```

---

## 🏗 Folder Architecture
The project follows a **Modular Clean Architecture**:
```text
lib/
 ├── core/          # Constants, global services, and utilities
 ├── features/      # Feature-specific logic (auth, logs, invite, etc.)
 ├── shared/        # Reusable widgets and models
 └── main.dart      # Application entry point
```

---

## 📦 Build Release APK
```bash
flutter build apk --release
```

---

## 🆘 Known Issues & Support
- **Gradle mismatch?** Update Android Gradle Plugin in `android/build.gradle`.
- **Firebase not initialized?** Verify `google-services.json` is in the correct directory.
- **API level error?** Ensure `compileSdkVersion` is at least 34 in `android/app/build.gradle`.

---
© 2026 Log-O-Logu Team. Built with ❤️ for safer communities.
