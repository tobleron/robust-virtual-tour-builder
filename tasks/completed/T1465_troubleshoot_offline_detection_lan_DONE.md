# T1465 Troubleshoot Offline Detection on LAN

## Hypothesis (Ordered Expected Solutions)
1. [x] **navigator.onLine Unreliability**: Implemented a secondary "heartbeat" check against the backend API via a new `/health` endpoint. `NetworkStatus.res` now probes this endpoint to confirm true connectivity.
2. [x] **Race Condition during Initialization**: Initial probe added to `initialize`.
3. [x] **Service Worker Interference**: Periodic probe added to ensure recovery even if service worker or browser events are unreliable.

## Activity Log
- [x] Initial research: Checked `src/utils/NetworkStatus.res` and identified reliance on `navigator.onLine`.
- [x] Located error message in `src/components/ui/OfflineBanner.res`.
- [x] Added `/api/health` endpoint to Rust backend (`backend/src/api/health.rs`, `backend/src/api/mod.rs`).
- [x] Updated `NetworkStatus.res` with active probing logic and periodic retry.
- [x] Updated `NetworkStatus.resi` to expose `probe`.
- [x] Enhanced `OfflineBanner.res` with a manual "Retry Connection" button.
- [x] Verified build passes with `npm run build`.

## Code Change Ledger
- `backend/src/api/mod.rs`: Added `/health` route.
- `backend/src/api/health.rs`: Implemented health check.
- `src/utils/NetworkStatus.res`: Implemented `probe()` using `/api/health`, added periodic check.
- `src/utils/NetworkStatus.resi`: Exposed `probe()`.
- `src/components/ui/OfflineBanner.res`: Added "Retry Connection" button.

## Rollback Check
- [x] (Confirmed CLEAN or REVERTED non-working changes).

## Context Handoff
Troubleshooting complete. The offline detection is now "active" and probes the backend server directly, bypassing OS-level `onLine` reporting bugs on LAN.
