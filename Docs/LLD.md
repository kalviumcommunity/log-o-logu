# Low-Level Design (LLD) - Log-o-logu

## 1. System Components & Architecture

### 1.1 Flutter App Architecture (Clean Architecture)
The application will follow a feature-first modular structure to ensure scalability and maintainability.

```text
lib/
├── core/
│   ├── constants/        # App constants, styling, API keys
│   ├── utils/            # Validators, formatters, helpers
│   ├── theme/            # Theme data
│   └── common_widgets/   # Reusable UI components
├── features/
│   ├── auth/             # Login, Registration, Password Reset
│   ├── invites/          # (Resident) QR Generation, Guest List
│   ├── validation/       # (Guard) QR Scanner, Entry Log
│   ├── dashboard/        # (Admin) Analytics, Live Occupancy
│   └── profile/          # User settings
├── data/                 # Repositories & Data Sources
│   ├── datasources/      # Firestore, Firebase Auth interfaces
│   └── models/           # DTOs (Data Transfer Objects)
└── domain/               # Business Logic & Entities
    ├── entities/         # Domain models
    └── repositories/     # Repository interfaces
```

---

## 2. Detailed Database Schema (Cloud Firestore)

### 2.1 `users` (Collection)
| Field | Type | Description |
| :--- | :--- | :--- |
| `uid` | String (PK) | Firebase Auth UID |
| `name` | String | Full name |
| `email` | String | Email address |
| `phone` | String | Verified phone number |
| `role` | Enum | `resident` \| `guard` \| `admin` |
| `apartmentId` | String (FK) | ID of the specific apartment complex |
| `fcmToken` | String | Device token for push notifications |
| `createdAt` | Timestamp | Account creation time |

### 2.2 `apartments` (Collection)
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String (PK) | Unique Apartment ID |
| `name` | String | Name of the complex |
| `address` | String | Detailed address |
| `config` | Map | `{ "geofencing": true, "radius": 1000 }` |
| `location` | Geopoint | Latitude/Longitude of main gate |

### 2.3 `invites` (Collection)
| Field | Type | Description |
| :--- | :--- | :--- |
| `inviteId` | String (PK) | Unique ID for QR |
| `residentUid` | String (FK) | Inviting resident |
| `guestName` | String | Name of guest |
| `guestPhone` | String | Phone of guest |
| `validFrom` | Timestamp | Start validity |
| `validUntil` | Timestamp | Expiry validity |
| `status` | String | `pending` \| `approved` \| `used` \| `expired` \| `cancelled` |
| `type` | String | `one-time` \| `multi-entry` \| `service` |
| `qrCode` | String | Base64 or URL to QR (typically just `inviteId` string) |

### 2.4 `logs` (Collection)
| Field | Type | Description |
| :--- | :--- | :--- |
| `logId` | String (PK) | Auto-generated |
| `inviteId` | String (FK) | Reference to invite (if applicable) |
| `residentUid` | String (FK) | Resident being visited |
| `guardUid` | String (FK) | Guard who validated entry |
| `entryTime` | Timestamp | Timestamp of entry |
| `exitTime` | Timestamp | Timestamp of exit (null if active) |
| `visitorDetails` | Map | `{ "name": "...", "phone": "..." }` |
| `status` | String | `active` \| `completed` |

---

## 3. Cloud Functions (Logic Layer)

### 3.1 `validateInvite` (onCall)
- **Input**: `inviteId`, `guardUid`
- **Logic**:
    1. Fetch invite from Firestore.
    2. Check if `status == "pending"` or `"approved"`.
    3. Verify `now` is between `validFrom` and `validUntil`.
    4. Verify guard's `apartmentId` matches invite's apartment (if applicable).
- **Return**: `{ success: boolean, data?: InviteData, error?: string }`

### 3.2 `processEntry` (onCall)
- **Input**: `inviteId`, `guardUid`, `visitorPhotoUrl` (optional)
- **Logic**:
    1. Transaction: Update `invite.status = "used"`.
    2. Create `logs` document with `entryTime = now` and `status = "active"`.
    3. Trigger `sendNotification` to `residentUid`.
- **Return**: `logId`

### 3.3 `geoFenceExit` (Firestore Trigger / onCall)
- **Input**: `userId` (Resident/Guest) or `logId`
- **Logic**: 
    - If GPS detects exit from radius, update `logs` where `status == "active"` with `exitTime = now`.
    - Mark log as `completed`.

---

## 4. UI/UX Component Breakdown

### 4.1 Resident App Widgets
- `InviteQRCodeCard`: Display generated QR with sharing button (WhatsApp/SMS).
- `ActivityListTile`: Shows real-time status of current and past visitors.
- `InviteSummaryModal`: Bottom sheet to quickly approve/deny a "knock" (service entry).

### 4.2 Guard App Widgets
- `QRScannerOverlay`: Custom implementation using `mobile_scanner` with a scanning window.
- `ValidationResultDialog`: Color-coded feedback (Green: Pass, Red: Fail, Yellow: Requires Manual Approval).
- `ActiveVisitorsGrid`: Dashboard showing who is currently "Inside".

---

## 5. Security & Privacy Implementation

### 5.1 Firestore Security Rules
```javascript
service cloud.firestore {
  match /databases/{database}/documents {
    // Residents can read/write their own invites
    match /invites/{inviteId} {
      allow read, write: if request.auth.uid == resource.data.residentUid;
      allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'guard';
    }
    
    // Guards can create logs but not edit them after creation
    match /logs/{logId} {
      allow create: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'guard';
      allow read: if request.auth.uid == resource.data.residentUid || 
                    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## 6. Sequence Diagrams (Logic Flow)

### 6.1 Guest Entry Flow
1. **Visitor** shows QR to **Guard**.
2. **Guard App** calls `validateInvite` Cloud Function.
3. **Cloud Function** returns success after checking DB.
4. **Guard App** calls `processEntry`.
5. **Backend** updates DB and sends **Push Notification** to **Resident**.
6. **Resident App** displays: "Your guest [Name] has entered the complex."

---

## 7. Edge Case Handling (Technical)

| Scenario | Resolution |
| :--- | :--- |
| **Offline Validation** | Use Firestore's offline persistence for recently fetched invites; sync logs immediately when network returns. |
| **QR Screenshot Reuse** | Use "Time-based OTP" embedded in QR or mark as `used` in DB instantly on first scan. |
| **Guest phone mismatch** | Guard app prompts for manual verification if phone scanned doesn't match invite record. |
| **GPS Jitter (GeoFence)** | Implement a debounce (e.g., must be out of bounds for 3 minutes) before auto-logging exit. |
