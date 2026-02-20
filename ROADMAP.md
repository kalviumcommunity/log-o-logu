# 🗺️ Log-O-Logu Development Roadmap

This roadmap tracks the development of the MVP (1-week timeline). Each item is linked to its tracking issue on GitHub.

## 📅 Day 1: Setup (Remainder)
| Issue | Task | Role | Status |
| :---: | :--- | :--- | :--- |
| [#13](https://github.com/kalviumcommunity/log-o-logu/issues/13) | [Setup] Add remaining Flutter dependencies to `pubspec.yaml` | Resident App | 🔴 Open |
| [#14](https://github.com/kalviumcommunity/log-o-logu/issues/14) | [Setup] Create Firestore collections schema and rules | Backend | 🔴 Open |

## 📅 Day 2: Authentication
| Issue | Task | Role | Status |
| :---: | :--- | :--- | :--- |
| [#15](https://github.com/kalviumcommunity/log-o-logu/issues/15) | [Auth] Implement role-based login and signup | Backend | 🔴 Open |
| [#16](https://github.com/kalviumcommunity/log-o-logu/issues/16) | [Auth] Build Login and Registration UI screens | Resident App | 🔴 Open |
| [#17](https://github.com/kalviumcommunity/log-o-logu/issues/17) | [Auth] Implement role-based routing after login | Resident App | 🔴 Open |

## 📅 Day 3: Invite + QR + Guard App
| Issue | Task | Role | Status |
| :---: | :--- | :--- | :--- |
| [#18](https://github.com/kalviumcommunity/log-o-logu/issues/18) | [Invite] Implement guest invite creation (UUID) | Backend | 🔴 Open |
| [#19](https://github.com/kalviumcommunity/log-o-logu/issues/19) | [Invite] Generate and display QR code (InviteQRCodeCard) | Resident App | 🔴 Open |
| [#20](https://github.com/kalviumcommunity/log-o-logu/issues/20) | [Invite] Implement invite expiration logic | Backend | 🔴 Open |
| [#21](https://github.com/kalviumcommunity/log-o-logu/issues/21) | [Invite] Display real-time invite list (ActivityListTile) | Resident App | 🔴 Open |
| [#22](https://github.com/kalviumcommunity/log-o-logu/issues/22) | [Guard] Implement QR Scanner (QRScannerOverlay) | Guard App | 🔴 Open |
| [#23](https://github.com/kalviumcommunity/log-o-logu/issues/23) | [Backend] Implement `validateInvite` Cloud Function | Backend | 🔴 Open |
| [#24](https://github.com/kalviumcommunity/log-o-logu/issues/24) | [Backend] Implement `processEntry` Cloud Function | Backend | 🔴 Open |
| [#25](https://github.com/kalviumcommunity/log-o-logu/issues/25) | [Guard] Build ValidationResultDialog (✅/❌ screen) | Guard App | 🔴 Open |

## 📅 Day 4: Admin Dashboard + Backend
| Issue | Task | Role | Status |
| :---: | :--- | :--- | :--- |
| [#26](https://github.com/kalviumcommunity/log-o-logu/issues/26) | [Backend] Implement POST `/logExit` Cloud Function | Backend | 🔴 Open |
| [#27](https://github.com/kalviumcommunity/log-o-logu/issues/27) | [Security] Enforce QR anti-reuse via Firestore transaction | Security | 🔴 Open |
| [#28](https://github.com/kalviumcommunity/log-o-logu/issues/28) | [Guard] Build ActiveVisitorsGrid (Guard live view) | Guard App | 🔴 Open |
| [#29](https://github.com/kalviumcommunity/log-o-logu/issues/29) | [Admin] Build Admin live occupancy dashboard | Admin App | 🔴 Open |
| [#30](https://github.com/kalviumcommunity/log-o-logu/issues/30) | [Admin] Implement log filtering and search | Admin App | 🔴 Open |
| [#31](https://github.com/kalviumcommunity/log-o-logu/issues/31) | [Guard] Implement service partner entry flow | Guard App | 🔴 Open |
| [#32](https://github.com/kalviumcommunity/log-o-logu/issues/32) | [Admin] Build resident and guard account management | Admin App | 🔴 Open |

## 📅 Day 5 AM: Notifications + Security + Reliability
| Issue | Task | Role | Status |
| :---: | :--- | :--- | :--- |
| [#33](https://github.com/kalviumcommunity/log-o-logu/issues/33) | [Notifications] Implement FCM token storage and push notifications | Backend | 🔴 Open |
| [#34](https://github.com/kalviumcommunity/log-o-logu/issues/34) | [Reliability] Implement Snackbar error messages and retries | Resident App | 🔴 Open |
| [#35](https://github.com/kalviumcommunity/log-o-logu/issues/35) | [Security] Finalize/deploy Firestore role-based rules | Security | 🔴 Open |

## 📅 Day 5 PM: Testing + Deployment
| Issue | Task | Role | Status |
| :---: | :--- | :--- | :--- |
| [#36](https://github.com/kalviumcommunity/log-o-logu/issues/36) | [Testing] Manual QA — Full invite lifecycle & edge cases | All | 🔴 Open |
| [#37](https://github.com/kalviumcommunity/log-o-logu/issues/37) | [DevOps] Deploy Cloud Functions + Security Rules + Release APK | DevOps | 🔴 Open |
