# High-Level Design (HLD): log-o-logu

**Project Name:** log-o-logu

**Version:** 1.0

**Status:** Draft / For Review

---

## 1. System Architecture Overview

The **log-o-logu** system utilizes a **Serverless Mobile Architecture**. It leverages **Flutter** for a cross-platform client experience and **Firebase** as the backend-as-a-service (BaaS) provider.

The architecture is designed to be reactive; data changes in the cloud (Firestore) are pushed immediately to the client apps, ensuring that Guards and Residents stay in sync without manual refreshes.

---

## 2. Major Components & Modules

### A. The Client App (Flutter)

A single codebase that renders different interfaces based on the user's role:

* **Admin Module:** User management (onboarding/offboarding), master log viewing, and system settings.
* **Resident Module:** QR code generation, guest list management, and real-time push notification handling.
* **Guard Module:** High-speed QR scanner interface, manual entry forms, and entry/exit logging.

### B. Backend Services (Firebase)

* **Firebase Auth:** Handles secure identity management.
* **Cloud Firestore:** NoSQL database for real-time storage of user profiles, invites, and logs.
* **Firebase Cloud Messaging (FCM):** The "Alert System" that notifies residents the moment a QR is scanned.
* **Cloud Functions (Optional/Future):** For server-side logic like cleaning up expired QR codes or generating monthly PDF reports.

---

## 3. Data Flow and Relationships

### 3.1 The "Pre-Approved" Entry Flow

1. **Request:** Resident enters guest details in the app.
2. **Creation:** A document is created in the `invites` collection with a unique `invite_id`.
3. **Generation:** The `invite_id` is converted into a QR code on the Resident's device.
4. **Verification:** The Guard scans the QR. The app queries Firestore for that `invite_id`.
5. **Validation:** If the status is "Active" and the time is valid, the Guard grants entry.
6. **Update:** The `invite` status changes to "Used," and an entry is added to `activity_logs`.

### 3.2 Data Relationships (Firestore Schema)

* **Users:** Linked to **Invites** via `resident_uid`.
* **Invites:** Linked to **Activity Logs** via `invite_id`.
* **Activity Logs:** Linked to **Guards** via `guard_uid` to track who authorized the entry.

---

## 4. Integration Points & External Dependencies

* **WhatsApp API (URL Launcher):** Used to share the generated QR code image/link directly from the Resident's app to the Visitor.
* **QR Scanner/Generator Packages:** Flutter plugins for high-performance scanning (e.g., `mobile_scanner`) and generating (e.g., `qr_flutter`).
* **Firebase SDK:** Deep integration for real-time data streaming and authentication.

---

## 5. Non-Functional Requirements & Constraints

| Category | Requirement |
| --- | --- |
| **Performance** | The "5-Second Gate" rule: QR scanning and verification must complete in under 3 seconds. |
| **Security** | Role-Based Access Control (RBAC) via Firestore Security Rules. Residents cannot see other residents' guests. |
| **Scalability** | Firebase handles concurrent users, supporting communities from 50 to 5,000+ units. |
| **Availability** | The system must be "Offline-Ready" for Guards in areas with spotty gate connectivity (caching). |
| **Constraint** | **No Location Services:** GPS/Geofencing features are excluded from the current MVP and moved to the future roadmap. |

---

## 6. Logic Flowchart

---

### Acceptance Checklist

* [x] Three distinct roles (Admin, Resident, Guard) defined.
* [x] QR-based entry logic detailed.
* [x] Firebase integration points identified.
* [x] Future-facing location features moved to roadmap.

---