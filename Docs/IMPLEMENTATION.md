# Implementation Design - Log-o-logu

## 🟢 R — Requirements
- Build cross-platform mobile application
- Integrate QR-based invite system
- Implement real-time logging
- Ensure role-based authentication
- Provide admin monitoring panel
- Support guest & service partner flows

## 🟢 T — Technical Approach
### Frontend
- **Framework**: Flutter (Layered Architecture)
- **State Management**: Provider / Riverpod
- **Pattern**: Clean Architecture (Domain, Data, Presentation)

### Backend
- **Auth**: Firebase Auth
- **Database**: Firestore
- **Backend Logic**: Cloud Functions
- **Notifications**: Firebase Cloud Messaging (FCM)

## 🟢 C — Component Implementation

### 1️⃣ Authentication Layer
- Role-based login (Resident, Guard, Admin)
- Token refresh handling
- Guard/Admin segregation logic in UI

### 2️⃣ Invite Service
- Generate UUID-based invite IDs
- Store with expiration timestamps
- QR generation using `qr_flutter` package

### 3️⃣ Validation Engine
- Triggered by Cloud Functions
- Transaction-based invite validation to prevent double-entry
- Log creation upon successful validation

### 4️⃣ Notification Layer
- FCM token storage per user device
- Push trigger on entry/exit events

## 🟢 R — Runtime Flow (Guest Entry)
1. **Resident** → Create Invite
2. **Firestore** → Write Invite Record
3. **App** → QR Generated
4. **Guard** → Scan QR
5. **Cloud Function** → Validate & Log Entry
6. **Backend** → FCM Notify Resident
