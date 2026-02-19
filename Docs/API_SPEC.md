# API Specification - Log-o-logu

## 🟢 R — API Requirements
- Invite validation (Guard access)
- Entry/Exit logging
- Admin filtering and reporting

## 🟢 T — Cloud Function Endpoints

### 1. `POST /validateInvite`
Validates a QR code scanned by the guard.

**Request Body:**
```json
{
  "inviteId": "uuid-string",
  "guardUid": "guard-auth-id"
}
```

**Response (Success):**
```json
{
  "status": "Approved",
  "message": "Entry allowed",
  "visitorName": "John Doe"
}
```

**Response (Denied):**
```json
{
  "status": "Denied",
  "message": "Invite expired or already used"
}
```

### 2. `POST /logExit`
Logs a visitor's exit.

**Request Body:**
```json
{
  "logId": "log-document-id"
}
```

## 🟢 C — Interactions
Flutter App → Cloud Function (HTTPS Call) → Firestore (DB Update) → Success/Fail Response

## 🟢 R — Response Standards
- **HTTP 200**: Success
- **HTTP 400**: Validation/Client error
- **HTTP 403**: Unauthorized (Invalid role)
- **HTTP 500**: Internal server error
