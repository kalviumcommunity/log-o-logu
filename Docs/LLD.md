# Low-Level Design (LLD) - Log-o-logu

This LLD aligns with the current HLD, database design, and Firebase API specification.

## 1. Architecture & Module Design

### 1.1 Runtime Architecture
- **Client:** Flutter app (role-based UX for `admin`, `resident`, `guard`).
- **Auth:** Firebase Auth with Google OAuth.
- **Data plane:** Direct Firestore SDK operations from client apps.
- **Async backend:** Cloud Functions for event-driven tasks only (notifications + invite expiry).
- **Critical gate logic:** Firestore transaction in Guard app (`5-Second Gate`) for atomic validation.

### 1.2 Feature Modules (Flutter)
```text
lib/
├── core/
│   ├── auth/                 # Auth wrappers, current-user bootstrap
│   ├── routing/              # Role/state based route guards
│   ├── firestore/            # Shared query helpers + converters
│   └── utils/                # Validation, date/time, qr payload helpers
├── features/
│   ├── onboarding/           # Invite code join + profile completion
│   ├── waiting_room/         # Realtime approval listener
│   ├── admin/
│   │   ├── apartment_setup/  # Create apartment + inviteCode
│   │   ├── approvals/        # Approve/Reject users in apartment
│   │   └── dashboard/        # Occupancy and logs
│   ├── resident/
│   │   ├── invites/          # Create/cancel invite + QR display
│   │   └── history/          # Personal visitor history
│   └── guard/
│       ├── scanner/          # QR scan + transaction validation
│       ├── manual_entry/     # Unplanned service entry (no invite)
│       └── exit_logging/     # Update exitTime
└── shared/
    ├── models/               # Firestore models
    └── widgets/              # Shared widgets (loading, errors, list items)
```

### 1.3 User State Machine
On login, app resolves route using `users/{uid}`:
1. `isOnboardingPending == true` → Onboarding flow.
2. `isOnboardingPending == false && isApproved == false` → Waiting Room.
3. `isApproved == true` → Role dashboard.

## 2. Firestore Data Model (Source of Truth)

### 2.1 `apartments` collection
Document ID: auto-generated apartment ID.

| Field | Type | Notes |
| :--- | :--- | :--- |
| `name` | String | Community name |
| `adminUid` | String | Creator/admin UID |
| `inviteCode` | String | 6-character join code, unique per apartment |
| `createdAt` | Timestamp | Creation timestamp |

### 2.2 `users` collection
Document ID: Firebase Auth UID.

| Field | Type | Notes |
| :--- | :--- | :--- |
| `uid` | String | Same as document ID |
| `apartmentId` | String | Tenant boundary key |
| `role` | String | `admin` \| `resident` \| `guard` |
| `name` | String | Display name |
| `email` | String | Email |
| `phone` | String | Phone number |
| `buildingName` | String\|Null | Tower/building for resident/guard context |
| `flatNumber` | String\|Null | Flat/unit identifier |
| `fcmToken` | String\|Null | Notification target |
| `isApproved` | Boolean | Access gate controlled by admin |
| `isOnboardingPending` | Boolean | Whether profile setup is complete |

### 2.3 `invites` collection
Document ID: auto-generated invite ID (also used as QR payload).

| Field | Type | Notes |
| :--- | :--- | :--- |
| `apartmentId` | String | Tenant boundary key |
| `residentUid` | String | Invite owner |
| `guestName` | String | Visitor label |
| `purpose` | String | Example: `delivery`, `guest` |
| `status` | String | `active` \| `used` \| `cancelled` \| `expired` |
| `validFrom` | Timestamp | Start of validity window |
| `validUntil` | Timestamp | End of validity window |
| `buildingName` | String | Denormalized from resident profile |
| `flatNumber` | String | Denormalized from resident profile |

### 2.4 `logs` collection
Document ID: auto-generated log ID.

| Field | Type | Notes |
| :--- | :--- | :--- |
| `apartmentId` | String | Tenant boundary key |
| `inviteId` | String\|Null | `null` for manual service entry |
| `residentUid` | String | Resident being visited |
| `scannedByGuardUid` | String | Guard operator UID |
| `guestName` | String | Copied from invite/manual input |
| `entryTime` | Timestamp | Entry timestamp |
| `exitTime` | Timestamp\|Null | Set when visitor exits |
| `buildingName` | String | Denormalized location context |
| `flatNumber` | String | Denormalized location context |

## 3. API-Level Operations (Firestore SDK)

### 3.1 Authentication
- `signInWithGoogle()` returns `uid`, `email`, `displayName`.

### 3.2 Apartment Operations
- **Create Apartment (admin):** write `apartments` doc with `name`, `adminUid`, `inviteCode`, `createdAt`.
- **Join Apartment:** query `apartments.where("inviteCode", "==", code).limit(1)`.

### 3.3 User Operations
- **Complete onboarding:** update `users/{uid}` with apartment + profile + role + pending/approval flags.
- **Waiting room stream:** watch `users/{uid}` for `isApproved` transition to `true`.
- **Approve user (admin):** update `users/{targetUid}` with `isApproved: true`.

### 3.4 Invite Operations
- **Create invite (resident):** write `invites` with denormalized `buildingName` and `flatNumber`.
- **Cancel invite (resident):** set `status = "cancelled"` if not already used/expired.

### 3.5 Gate Operations
- **QR validation (guard):** Firestore transaction:
  1. Read `invites/{inviteId}`.
  2. Validate `status == "active"` and `validUntil > now`.
  3. Update invite `status = "used"`.
  4. Create `logs` document with `entryTime`, `exitTime: null`.
- **Manual service entry (guard):** create `logs` with `inviteId: null`.
- **Exit logging (guard):** update `logs/{logId}` with `exitTime`.

## 4. Cloud Functions (Event-Driven Only)

### 4.1 `onLogCreated` (FCM Push)
- **Trigger:** Firestore `logs` document create.
- **Flow:** read `residentUid` → fetch `users/{residentUid}.fcmToken` → send FCM.
- **Payload:** title `Visitor Arrived`, body `{guestName} has entered the gate.`

### 4.2 `expireStaleInvites` (Scheduled)
- **Trigger:** Cloud Scheduler every 15 minutes.
- **Flow:** query `invites` where `status == "active" && validUntil < now` → batch update to `expired`.
- **Guarantee:** Security still enforced by client-side transaction checks, even if scheduler is delayed.

## 5. Security Rules Contract (Implementation Guidance)

Rules must enforce:
1. All operations require authenticated user.
2. User can access only documents within same `apartmentId` tenant boundary.
3. `isApproved == true` required for operational reads/writes outside onboarding setup.
4. Resident can create/manage own invites; guard can read invite for scan path only.
5. Guard can create logs and update `exitTime`; cannot mutate historical immutable fields.
6. Admin can approve users only within admin’s apartment.

## 6. Key Flows (Sequence-Level)

### 6.1 Planned Guest Entry (`5-Second Gate`)
1. Resident creates invite.
2. Visitor presents QR (payload = `inviteId`).
3. Guard scans QR and runs transaction.
4. On success, invite becomes `used` and log is created atomically.
5. `onLogCreated` function sends push to resident.

### 6.2 Unplanned Service Entry
1. Guard enters service name and resident flat.
2. App writes direct `logs` record (`inviteId: null`).
3. `onLogCreated` sends resident push notification.

### 6.3 New User Onboarding & Approval
1. User signs in and enters apartment invite code.
2. App writes/updates user profile with `isOnboardingPending: false`, `isApproved: false`.
3. Admin sees pending users filtered by `apartmentId` + `isApproved == false`.
4. Admin approves user; waiting-room listener routes user to dashboard.

## 7. Edge Cases & Failure Handling

| Scenario | Handling |
| :--- | :--- |
| Double scan race | Firestore transaction allows only first successful commit; second fails as `status != active`. |
| Expired invite | Guard receives immediate deny if `validUntil <= now`, regardless of cron status. |
| Network failure at gate | QR validation needs internet; app should show manual fallback for service entry path. |
| Missing FCM token | Log write still succeeds; notification function no-ops with retry-safe logging. |

## 8. Non-Functional Design Targets

- QR validation completes in under 1 second under normal network conditions.
- Admin and guard views use denormalized fields to avoid client-side joins.
- Data model scales across apartments through strict `apartmentId` partitioning.
