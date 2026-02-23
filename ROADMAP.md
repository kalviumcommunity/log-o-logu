# 🗺️ Log-O-Logu — MVP Development Roadmap

> **Timeline**: 1 Week · **Team Size**: 3 Members  
> Each member owns a **full vertical slice** — UI, logic, and backend for their domain.

---

## 👥 Team Ownership

| Member | Domain | Scope |
| :--- | :--- | :--- |
| **Member A** | 🏠 Resident App | Auth, Invites, QR Generation, Notifications, Error Handling |
| **Member B** | 🛡️ Guard App | QR Scanner, Invite Validation, Entry/Exit Processing, Active Visitors |
| **Member C** | 📊 Admin + Infra | Dashboard, Log Search, User Management, Firestore Rules, DevOps |

---

## 📅 Day 1 — Setup & Foundation

All members collaborate on shared setup before splitting into their domains.

| Issue | Task | Owner |
| :---: | :--- | :--- |
| [#13](https://github.com/kalviumcommunity/log-o-logu/issues/13) | Add remaining Flutter dependencies to `pubspec.yaml` | Member A |
| [#14](https://github.com/kalviumcommunity/log-o-logu/issues/14) | Create Firestore collections schema, security rules & indexes | Member C |

---

## 📅 Day 2 — Authentication (Shared Foundation)

Member A builds auth end-to-end. Members B & C can start scaffolding their screens.

| Issue | Task | Owner |
| :---: | :--- | :--- |
| [#15](https://github.com/kalviumcommunity/log-o-logu/issues/15) | Implement role-based login and signup with Firebase Auth | Member A |
| [#16](https://github.com/kalviumcommunity/log-o-logu/issues/16) | Build Login and Registration UI screens | Member A |
| [#17](https://github.com/kalviumcommunity/log-o-logu/issues/17) | Implement role-based routing after login | Member A |

---

## 📅 Day 3 — Core Features (Parallel Development)

Each member works on their own slice simultaneously.

### 🏠 Member A — Resident Invite Flow

| Issue | Task |
| :---: | :--- |
| [#18](https://github.com/kalviumcommunity/log-o-logu/issues/18) | Implement guest invite creation with UUID invite IDs |
| [#19](https://github.com/kalviumcommunity/log-o-logu/issues/19) | Generate and display QR code (InviteQRCodeCard widget) |
| [#20](https://github.com/kalviumcommunity/log-o-logu/issues/20) | Implement invite expiration logic (validFrom / validUntil) |
| [#21](https://github.com/kalviumcommunity/log-o-logu/issues/21) | Display real-time invite list with status (ActivityListTile) |

### 🛡️ Member B — Guard Scanning & Validation

| Issue | Task |
| :---: | :--- |
| [#22](https://github.com/kalviumcommunity/log-o-logu/issues/22) | Implement QR Scanner using `mobile_scanner` (QRScannerOverlay) |
| [#23](https://github.com/kalviumcommunity/log-o-logu/issues/23) | Implement `validateInvite` Cloud Function |
| [#24](https://github.com/kalviumcommunity/log-o-logu/issues/24) | Implement `processEntry` Cloud Function (log entry, mark used) |
| [#25](https://github.com/kalviumcommunity/log-o-logu/issues/25) | Build ValidationResultDialog (✅ Green / ❌ Red result screen) |

### 📊 Member C — Admin Dashboard (Start)

| Issue | Task |
| :---: | :--- |
| [#29](https://github.com/kalviumcommunity/log-o-logu/issues/29) | Build Admin live occupancy dashboard |
| [#30](https://github.com/kalviumcommunity/log-o-logu/issues/30) | Implement log filtering and search (by date, type, resident) |

---

## 📅 Day 4 — Advanced Features (Parallel Development)

### 🏠 Member A — Notifications & Reliability

| Issue | Task |
| :---: | :--- |
| [#33](https://github.com/kalviumcommunity/log-o-logu/issues/33) | Implement FCM token storage and push notification on guest entry |
| [#34](https://github.com/kalviumcommunity/log-o-logu/issues/34) | Implement Snackbar error messages and Firestore retry logic (3× backoff) |

### 🛡️ Member B — Guard Advanced Features

| Issue | Task |
| :---: | :--- |
| [#26](https://github.com/kalviumcommunity/log-o-logu/issues/26) | Implement POST `/logExit` Cloud Function |
| [#27](https://github.com/kalviumcommunity/log-o-logu/issues/27) | Enforce QR anti-reuse via Firestore transaction (deny second scan) |
| [#28](https://github.com/kalviumcommunity/log-o-logu/issues/28) | Build ActiveVisitorsGrid — Guard live occupancy view |
| [#31](https://github.com/kalviumcommunity/log-o-logu/issues/31) | Implement service partner entry flow (delivery/service session) |

### 📊 Member C — Admin Management & Security

| Issue | Task |
| :---: | :--- |
| [#32](https://github.com/kalviumcommunity/log-o-logu/issues/32) | Build resident and guard account management for admin |
| [#35](https://github.com/kalviumcommunity/log-o-logu/issues/35) | Finalize and deploy Firestore role-based security rules to production |

---

## 📅 Day 5 — Testing & Deployment (All Members)

| Issue | Task | Owner |
| :---: | :--- | :--- |
| [#36](https://github.com/kalviumcommunity/log-o-logu/issues/36) | Manual QA — Full invite lifecycle, double-scan, and network failure tests | All Members |
| [#37](https://github.com/kalviumcommunity/log-o-logu/issues/37) | Deploy Cloud Functions + Firestore rules + build release APK | Member C (lead) |

---

## 📊 Workload Summary

| Member | Total Issues | Days Active |
| :--- | :---: | :--- |
| **Member A** (Resident) | 10 | Day 1–4 + QA on Day 5 |
| **Member B** (Guard) | 8 | Day 3–4 + QA on Day 5 |
| **Member C** (Admin + Infra) | 7 | Day 1, 3–5 |

> 💡 **Tip**: Members B and C can start scaffolding their home screens on Day 2 while Member A builds auth.
