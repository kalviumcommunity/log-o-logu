## Phase 1 — Core Mechanics Hardening (Now)
Implement true transaction-based gate validation (invite state transition + log write).
Normalize invite status contract across app, repo, and functions.
Enforce strict apartment scoping across repositories + security rules.
## Phase 2 — Guard Operations Completion
Integrate real QR scanner (mobile_scanner) into guard flow.
Add anti-reuse and idempotency protections.
Implement manual service entry + exit logging on logs.
## Phase 3 — Admin Tenant-Safe Operations
Tenant-scoped approvals, metrics, and live occupancy from logs.
Add log filtering/search with indexed queries.
Remove placeholder data (guard directory/logs).
## Phase 4 — Backend Reliability + Observability
Add integration tests for onboarding→approval→invite→scan→log lifecycle.
Align Cloud Functions to final domain contract (validate/processEntry/logExit/onLogCreated/expire cadence).
Add retry/error taxonomy and telemetry.
