# Updated High-Level Design (HLD) - Log-o-logu

Here is the revised HLD built from first principles. It incorporates the NoSQL denormalization strategy, the multi-tenant onboarding flow, and the optimized transaction logic for the "5-Second Gate" rule.

## 🟢 R — Requirements

The system must:

* **New:** Support Multi-Tenant architecture (Multiple apartments with unique 6-character invite codes).
* **New:** Enforce a strict "Waiting Room" approval state machine for new users.
* Replace manual visitor logs with digital logging.
* Support Pre-Approved QR Guest Invite system.
* Support Service Partner quick-entry validation (unplanned visitors).
* Provide Admin live dashboard (zero client-side joins for instant loading).
* Enable real-time push notifications.
* Log entry and exit timestamps automatically.

## 🟢 T — Technical Stack

| Layer | Technology | First Principle Purpose |
| --- | --- | --- |
| **Frontend** | Flutter (Dart) | Single codebase, rapid UI building. |
| **Authentication** | Firebase Auth | Google OAuth identity verification. |
| **Database** | Firestore (NoSQL) | Denormalized data for single-read dashboard loads. |
| **Core Logic** | Firestore Transactions | Atomic client-side validation (< 500ms) to prevent double-scans. |
| **Async Backend** | Cloud Functions | Background tasks (Push notifications, scheduled expiry). |
| **Notifications** | FCM | Asynchronous alerts to residents. |
| **QR Handling** | `mobile_scanner` | Fast, on-device QR string extraction. |

## 🟢 C — Components

### 1️⃣ Resident Mobile App

* Complete onboarding (Select apartment, enter flat number).
* Wait for Admin approval (Listening state).
* Create pre-approved guest invites (QR generation).
* View personal visitor history.

### 2️⃣ Guard App

* Scan QR codes (Transaction-based instant validation).
* Process unplanned Service Entry (Direct log writing).
* Manually log visitor exits.

### 3️⃣ Admin Dashboard

* Create Apartment & generate `inviteCode`.
* Approve/Reject pending Resident and Guard access requests.
* View live community occupancy and historical logs.

### 4️⃣ Firebase Backend

* **Firestore DB:** `apartments`, `users`, `invites`, `logs`.
* **Cloud Functions:** 1. Trigger FCM push notifications on new `logs` document.
2. Cron job to auto-expire old `invites`.
* **Security Rules:** Enforce `isApproved == true` for read/write access.

## 🟢 R — Responsibilities (Module Breakdown)

#### 🔐 3.1 Authentication & State Module

* **Responsibilities:** Identity validation, multi-tenant routing, state machine execution.
* **State Logic:** - `isOnboardingPending == true` ➔ Route to Setup Screen.
* `isApproved == false` ➔ Route to Waiting Room.
* `isApproved == true` ➔ Route to Main Dashboard.



#### 🎟 3.2 Guest Invite Module

* **Responsibilities:** Generate unique time-limited document, convert ID to QR.
* **Data Structure:** `invites` collection includes denormalized `buildingName` and `flatNumber` for instant Guard UI rendering.

#### ⚡ 3.3 QR Validation Module (Optimized)

* **Responsibilities:** Extract QR payload, run atomic transaction, grant/deny access.
* **Validation Logic (Client-Side Transaction):** `Read Invite ➔ Check Expiry & Status ➔ If Valid: Update Status to 'used' + Write to Logs ➔ Show Green Screen.`

#### 📦 3.4 Service Entry Module (Unplanned)

* **Responsibilities:** Handle delivery agents without QR codes.
* **Logic:** Guard manually inputs name/company. Bypasses `invites` collection entirely. Writes directly to `logs` collection with `inviteId: null`.

#### 🔔 3.5 Notification Module

* **Responsibilities:** Alert residents securely.
* **Trigger:** Cloud function watches the `logs` collection. When a new log appears, it finds the `fcmToken` of the `residentUid` and sends the push.

## 📊 4. Data Flow Documentation

### 4.1 Planned Guest Flow (The 5-Second Gate)

1. **Resident App:** Creates `invite` document ➔ Generates QR.
2. **Visitor:** Shows QR at the gate.
3. **Guard App:** Scans QR ➔ Executes Firestore Transaction ➔ Verifies & Writes `log` document.
4. **Backend:** Cloud Function detects new `log` ➔ Sends FCM push to Resident.

### 4.2 Unplanned Delivery Flow

1. **Visitor:** Arrives without QR.
2. **Guard App:** Enters "Swiggy" & selects Flat A-123 ➔ Writes directly to `log`.
3. **Backend:** Cloud Function detects new `log` ➔ Sends FCM push to Resident: *"Swiggy is at the gate."*

## 🚨 6. Edge Case & Failure Handling

* **Double Scan / QR Reuse:** Firestore Transactions lock the document. If two guards scan exactly at the same time, the transaction ensures only one succeeds; the second gets "Already Used."
* **Network Failure at Gate:** Firestore offline persistence caches the log, but real-time validation requires internet. Guard must use manual override if offline.
* **Geo-Fencing Limitations:** Mobile OS kills background location tracking to save battery. Geo-fencing is removed from the critical exit flow. Exits must be manually logged by the Guard to prevent "ghost" occupancy.

## 🔟 Non-Functional Requirements

* **Performance:** QR validation must execute in < 1 second using client-side transactions.
* **Read Efficiency:** Dashboards must load in a single query (0 client-side joins).
* **Scalability:** NoSQL structure supports unlimited apartments via the `apartmentId` index.