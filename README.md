# log-o-logu: Smart Visitor Management System

**log-o-logu** is a streamlined, mobile-first solution designed to replace outdated physical visitor logbooks in gated communities. By shifting the responsibility of security from a lone guard to a distributed network of residents, it transforms the entry process into a verified, **5-second digital transaction**.

## 🚀 The Core Philosophy

The "Correct" solution to gate security isn't more paperwork—it's **Pre-Approved Digital Verification**.

* **Verification over Decoration:** No more fake names or phone numbers. Every guest is "digitally signed" by a verified resident.
* **The 5-Second Gate:** QR scanning eliminates the "human bottleneck" of manual handwriting.
* **Real-Time Accountability:** Searchable digital logs replace dusty, unsearchable notebooks.
* **Direct Communication:** Instant Firebase Cloud Messaging (FCM) replaces broken intercoms.

## 👥 Role-Based Access Control (RBAC)

| Role | Responsibility | Key Features |
| --- | --- | --- |
| **Admin** | System Governance | Onboard/offboard Residents and Guards, view global entry logs. |
| **Resident** | Personal Security | Generate QR invites, receive arrival alerts, view personal guest history. |
| **Guard** | Execution | Scan QR codes, log unannounced visitors, trigger emergency alerts. |

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase (Firestore, Authentication, Cloud Functions, Cloud Messaging)
* **Communication:** WhatsApp API (for QR sharing)
* **Scanner:** Mobile camera-based QR detection

## 📥 Getting Started

1. **Clone the Repository:**
```bash
git clone https://github.com/kalviumcommunity/log-o-logu.git

```


2. **Firebase Configuration:**
* Create a Firebase project at [console.firebase.google.com]().
* Enable **Email/Password Authentication** and **Cloud Firestore**.
* Download and add `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) to the respective project folders.


3. **Install Dependencies:**
```bash
flutter pub get

```


4. **Run the App:**
```bash
flutter run

```



## 🛤️ Future Roadmap

* **Geofencing:** Ensure Guards can only scan codes when within the society perimeter.
* **Location-Based ETA:** Real-time tracking of delivery partners once they enter the gate.
* **Face Recognition:** Secondary verification for frequent staff and domestic help.

---
