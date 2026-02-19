# Testing Strategy - Log-o-logu

## 🟢 R — Requirements
- Validate full invite lifecycle (Creation -> Scan -> Entry -> Exit)
- Prevent duplicate entries (double-scan check)
- Test app behavior during network failures

## 🟢 T — Testing Types
- **Unit Testing**: Business logic in Flutter (Controllers/Services)
- **Integration Testing**: Firebase Emulator suite (Functions + Firestore)
- **Manual QA**: Field testing with guard and resident apps in real-time

## 🟢 C — Test Scenarios
| Scenario | Expected Result |
| :--- | :--- |
| **Expired QR** | Denied (Validation error) |
| **Double scan** | Second attempt denied (Invite status check) |
| **Network drop** | Graceful retry or offline log caching |
| **Wrong role login** | Residents blocked from Guard/Admin dashboards |

## 🟢 R — Performance Targets
- **QR Validation**: < 2.0 seconds
- **Log Retrieval**: < 1.0 second
- **Dashboard Load**: < 3.0 seconds
