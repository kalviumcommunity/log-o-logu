# API Specification (Firebase Backend) - Log-o-logu

Because this architecture uses Firebase as a Backend-as-a-Service (BaaS), the "API" consists of direct client-to-database operations via the Firestore SDK, protected by Security Rules, and background Cloud Functions.

Here is the specification mapping exactly how the Flutter frontend interacts with the backend.

---

## 1. Authentication

**Mechanism:** Google OAuth via Firebase Auth SDK.

* **Action:** `signInWithGoogle()`
* **Output:** Firebase Auth `uid`, `email`, `displayName`.

---

## 2. Firestore Client Operations (The "Endpoints")

### 🏢 Apartments

**Create Community (Admin Only)**

* **Type:** `WRITE` (Auto-ID)
* **Collection:** `apartments`
* **Payload:** ```json
{
"name": "kalvium Homes",
"adminUid": "uid_string",
"inviteCode": "X7B9WQ",
"createdAt": "timestamp"
}
```


```



**Get Community by Invite Code**

* **Type:** `READ` (Query)
* **Query:** `apartments.where("inviteCode", "==", "X7B9WQ").limit(1)`
* **Returns:** Apartment Document ID to be saved to the User's profile.

### 👤 Users

**Complete Onboarding (Resident/Guard)**

* **Type:** `UPDATE`
* **Document:** `users/{uid}`
* **Payload:**
```json
{
  "apartmentId": "apartment_id_string",
  "role": "resident",
  "buildingName": "Tower A",
  "flatNumber": "A-123",
  "phone": "1234567890",
  "isOnboardingPending": false,
  "isApproved": false
}

```



**Listen for Admin Approval (Waiting Room)**

* **Type:** `READ` (Real-time Stream)
* **Document:** `users/{uid}`
* **Condition:** Flutter `StreamBuilder` listens for `isApproved` to change from `false` to `true`.

**Approve User (Admin Only)**

* **Type:** `UPDATE`
* **Document:** `users/{target_uid}`
* **Payload:** `{"isApproved": true}`

### 🎟️ Invites (Digital Pass)

**Create Guest Invite (Resident Only)**

* **Type:** `WRITE` (Auto-ID)
* **Collection:** `invites`
* **Payload:**
```json
{
  "apartmentId": "apartment_id_string",
  "residentUid": "uid_string",
  "guestName": "Amazon Delivery",
  "purpose": "delivery",
  "status": "active",
  "validFrom": "timestamp",
  "validUntil": "timestamp",
  "buildingName": "Tower A",
  "flatNumber": "A-123"
}

```


* **Response:** Returns the `inviteId` string, which the frontend converts to a QR Code.

### 📖 Logs (Gate Operations)

**QR Scan & Validate (The 5-Second Gate Transaction)**

* **Type:** `TRANSACTION` (Atomic Read + Write)
* **Logic:**
1. `READ`: `invites/{scanned_inviteId}`
2. `CHECK`: `if (invite.status == 'active' && invite.validUntil > now)`
3. `WRITE`: Update `invites/{scanned_inviteId}` -> `{"status": "used"}`
4. `WRITE`: Create new `logs` document.


* **Log Payload:**
```json
{
  "apartmentId": "apartment_id_string",
  "inviteId": "scanned_inviteId",
  "residentUid": "resident_uid_string",
  "scannedByGuardUid": "guard_uid_string",
  "guestName": "Amazon Delivery",
  "buildingName": "Tower A",
  "flatNumber": "A-123",
  "entryTime": "timestamp",
  "exitTime": null
}

```



**Manual Service Entry (Unplanned Visitor)**

* **Type:** `WRITE` (Auto-ID)
* **Collection:** `logs`
* **Payload:** Exact same as above, but `inviteId` is `null` and `guestName` is typed manually by the guard.

**Log Exit**

* **Type:** `UPDATE`
* **Document:** `logs/{logId}`
* **Payload:** `{"exitTime": "timestamp"}`

---

## 3. Cloud Functions (Background Async Logic)

These are server-side scripts that run automatically based on database events. The Flutter app does not call these directly.

**1. FCM Push Notifications (`onLogCreated`)**

* **Trigger:** `onCreate` event in the `logs` collection.
* **Logic:** 1. Extracts `residentUid`, `guestName`, and `entryTime` from the new log.
2. Queries `users/{residentUid}` to get the `fcmToken`.
3. Uses Firebase Admin SDK to send a push payload:
* *Title:* "Visitor Arrived"
* *Body:* "{guestName} has entered the gate."



**2. Auto-Expire Old Invites (`expireStaleInvites`)**

* **Trigger:** Cron Job (runs every 15 minutes via Cloud Scheduler).
* **Logic:** 1. Queries `invites` where `status == 'active'` AND `validUntil < NOW`.
2. Batch updates `status` to `'expired'`.
3. *First Principle note:* This keeps the database clean, but the client-side QR transaction *also* checks expiry time to guarantee security even if this cron job is delayed.