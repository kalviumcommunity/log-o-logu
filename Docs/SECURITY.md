# Security Design - Log-o-logu

## 🟢 R — Security Requirements
- Secure authentication and session management
- Prevent QR reuse and replay attacks
- Prevent unauthorized access to logs and user data
- Encrypt sensitive data in transit and at rest
- Strict Role-Based Access Control (RBAC)

## 🟢 T — Technologies Used
- **Firebase Auth**: Secure identity management
- **Firebase Security Rules**: Server-side access control
- **HTTPS (TLS 1.3)**: Encryption in transit
- **RBAC**: Enforced via custom user claims or Firestore roles

## 🟢 C — Security Controls

### 1️⃣ Authentication Security
- Email/OTP login for verified residents
- Token expiration and secure refresh cycles
- Guard/Admin role separation enforced at the database layer

### 2️⃣ QR Security
- UUID-based random IDs (unguessable)
- Single-use validation (status updated to `used` instantly)
- Expiration timestamp enforcement (server-side check)

### 3️⃣ Firestore Rules Example
```javascript
match /logs/{logId} {
  // Only admins can see all logs
  allow read: if request.auth.token.role == "admin";
  // Residents can only see logs where they are the resident
  allow read: if request.auth.uid == resource.data.residentUid;
}
```

### 4️⃣ Data Privacy
- Minimal personal data stored (PII reduction)
- No continuous background tracking
- GDPR-style data deletion support functionality

## 🟢 R — Risk Mitigation
| Risk | Mitigation |
| :--- | :--- |
| **QR Reuse** | Mark as `used` in DB transaction during first scan |
| **Fake GPS** | Secondary QR validation or manual guard check |
| **Data Leak** | Strict Firestore security rules and scoped queries |
| **Unauthorized Access** | Role-based rules and custom claims |
