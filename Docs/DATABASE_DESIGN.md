# Database Design - Log-o-logu

## 🟢 R — Requirements
- Fast read access for guards
- Scalable logging system
- Multi-apartment (multi-tenant) support
- Secure data isolation per apartment/resident

## 🟢 T — Firestore Collections

### `users`
- `userId` (PK)
- `role` (resident | guard | admin)
- `apartmentId`
- `name`
- `phone`

### `invites`
- `inviteId` (PK)
- `residentId`
- `status` (pending | used | expired)
- `validFrom`
- `validUntil`
- `guestName`

### `logs`
- `logId` (PK)
- `inviteId` (FK)
- `entryTime`
- `exitTime`
- `type` (guest | service)
- `residentUid`
- `apartmentId`

## 🟢 C — Relationships
`users` → `invites` → `logs`

## 🟢 R — Indexing Strategy
- **Composite Index**: `apartmentId` + `entryTime` (for admin dashboard logs)
- **Single Index**: `inviteId` (for quick guard validation)
- **Single Index**: `exitTime` (for finding active sessions)
