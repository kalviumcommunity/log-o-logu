🏢 1. apartments Collection
Purpose: Stores only the global identity of the community. During onboarding, residents/guards will likely fetch this collection to select their apartment from a dropdown list.

Document ID: e.g., FBFcyi1o0LLqci5GDpPe

Fields:

name (String): e.g., "kalvium Homes"

createdAt (Timestamp): e.g., 3 March 2026 at 10:02:29 UTC+5:30

👤 2. users Collection
Purpose: The core access control matrix. It holds identity, state, and role.

Document ID: Firebase Auth UID (e.g., YwV1bJLBnjOrXEjauihlsV6ySs13)

Fields:

uid (String)

apartmentId (String): e.g., "FBFcyi1o0LLqci5GDpPe"

role (String): "admin", "resident", or "guard"

name (String): e.g., "Balaji R"

email (String): e.g., "rkb.fox@gmail.com"

phone (String): e.g., "1234567890"

buildingName (String | Null): e.g., "Tower A"

flatNumber (String | Null): e.g., "A-123"

fcmToken (String | Null)

isApproved (Boolean): false

isOnboardingPending (Boolean): false

🎟️ 3. invites Collection
Purpose: The stateful Digital Pass (QR Code data).

Document ID: Auto-generated

Fields:

apartmentId (String): Crucial for Admin filtering.

residentUid (String): Links to the creator.

guestName (String): e.g., "Swiggy Delivery"

purpose (String): e.g., "delivery"

status (String): "active", "used", "cancelled"

validFrom (Timestamp)

validUntil (Timestamp)

buildingName (String): Copied from the user profile.

flatNumber (String): Copied from the user profile.

📖 4. logs Collection
Purpose: The immutable history ledger.

Document ID: Auto-generated

Fields:

apartmentId (String): Crucial for Admin filtering.

inviteId (String)

residentUid (String)

scannedByGuardUid (String)

guestName (String): Copied from the invite.

entryTime (Timestamp)

exitTime (Timestamp | Null)

buildingName (String): Copied from the user profile.

flatNumber (String): Copied from the user profile.

🟢 How The System Flows Now:
Creation: Admin logs in. App creates kalvium Homes in apartments. App creates Admin's profile in users with isApproved: true and the new apartmentId.

Onboarding: Balaji logs in. He selects "kalvium Homes" from a list. The app sets his apartmentId to FBFcyi1o0LLqci5GDpPe, sets isOnboardingPending: false, and isApproved: false.

Approval: The Admin dashboard queries all users where apartmentId == "FBFcyi1o0LLqci5GDpPe" AND isApproved == false. The admin taps approve, changing Balaji's boolean to true.