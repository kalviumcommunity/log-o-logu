# High-Level Design (HLD) - Log-o-logu

## 🟢 R — Requirements
The system must:
- Replace manual visitor logs with digital logging
- Support Pre-Approved QR Guest Invite system
- Support Service Partner quick-entry validation
- Provide Admin live dashboard (occupancy tracking)
- Enable real-time notifications
- Log entry and exit timestamps automatically
- Maintain secure, searchable records
- Ensure privacy and data protection
- Be scalable for multiple apartments

## 🟢 T — Technical Stack
| Layer | Technology |
| :--- | :--- |
| **Frontend** | Flutter (Dart) |
| **Authentication** | Firebase Auth |
| **Database** | Firestore |
| **Backend Logic** | Firebase Cloud Functions |
| **Notifications** | Firebase Cloud Messaging (FCM) |
| **QR Handling** | Flutter QR Scanner Library |
| **Geo-Fencing** | Flutter Geolocator |
| **UI Design** | Figma |
| **Maps** | Google Maps SDK |

## 🟢 C — Components

### 1️⃣ Resident Mobile App
- Create guest invite
- Generate QR Code
- Approve / deny visitors
- View visitor history

### 2️⃣ Guard App
- Scan QR codes
- Validate delivery agents
- View active visitors
- Manually override entry (admin-only)

### 3️⃣ Admin Dashboard
- View live occupancy
- Filter logs
- Export records
- Manage residents & guards

### 4️⃣ Firebase Backend
- **Firebase Auth**: Role-based authentication (Resident, Guard, Admin).
- **Firestore Database**: Stores Users, Invites, Logs, Service sessions.
- **Cloud Functions**: Validate QR, Trigger notifications, Auto-expire invites, Handle exit detection.
- **Firebase Cloud Messaging**: Push approval requests, Alert suspicious activity.

## 🟢 R — Responsibilities (Module Breakdown)

### 2️⃣ Module Architecture
**Mobile App (Flutter)**
- Authentication Module
- Invite Module
- QR Module
- GeoFence Module
- Notification Module

**Backend (Firebase)**
- Auth Service
- Firestore DB
- Cloud Functions
- FCM Service

**Admin Web Panel**

### 3️⃣ Detailed Module Description

#### 🔐 3.1 Authentication Module
- **Responsibilities**: Register/Login users, Role validation, Token management.
- **Interfaces**: `FirebaseAuth.signIn()`, `FirebaseAuth.createUser()`.
- **Edge Cases**: 
    - Invalid credentials -> Show error.
    - Expired token -> Auto re-login.
    - Role mismatch -> Block access.

#### 🎟 3.2 Guest Invite Module
- **Responsibilities**: Generate unique invite ID, Generate QR Code, Store invite in Firestore.
- **Data Structure**: `Invite { inviteId, residentId, guestName, phoneNumber, validFrom, validUntil, status }`.
- **Flow**: Resident → Create Invite → Firestore → QR Generated → Sent via WhatsApp.

#### 📷 3.3 QR Validation Module
- **Responsibilities**: Scan QR, Send inviteId to Cloud Function, Validate existence/expiry/usage.
- **Validation Logic**: `if invite.exists AND invite.validUntil > now AND invite.status == Approved: logEntry(); notifyResident(); else: denyEntry();`

#### 📍 3.4 GeoFence Module (Optional Enhancement)
- **Responsibilities**: Detect entry within 1KM radius, Auto-log exit when outside boundary.
- **Libraries**: `geolocator`, `Google Maps SDK`.

#### 🔔 3.5 Notification Module
- **Uses**: Firebase Cloud Messaging.
- **Triggers**: Guest arrival, Delivery partner entry, Exit confirmation, Suspicious attempt.

## 📊 4. Data Flow Documentation

### 4.1 Guest Entry Flow
Resident App → Create Invite → Firestore → QR Generated → Visitor shows QR → Guard scans → Cloud Function validates → Entry Log stored → FCM notifies Resident.

### 4.2 Delivery Partner Flow
Guard selects "Service Entry" → Capture Name/Order ID → Temporary Session Created → Entry Logged → Exit Scan → Session Closed.

### 4.3 Exit Flow (GeoFence Enabled)
User leaves 1KM radius → GeoFence Trigger → Cloud Function updates exitTime → Session Closed.

## 🚨 6. Edge Case & Failure Handling
- **Network Failure**: Use local cache, retry sync.
- **QR Reuse**: Mark as "Used", deny second scan.
- **Expired Invite**: Deny entry, notify resident.
- **Multiple Guards**: Use Firestore transaction locking.
- **Battery Saver**: Fallback to QR-based exit.

## 🔟 Non-Functional Requirements
- **Performance**: QR validation < 2 sec.
- **Availability**: 99.9% uptime.
- **Scalability**: Support 10,000+ users.
- **Security**: Encrypted authentication.
- **Reliability**: No data loss.