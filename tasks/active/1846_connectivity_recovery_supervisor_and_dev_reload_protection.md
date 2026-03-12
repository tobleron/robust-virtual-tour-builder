Assignee: Codex
Capacity Class: B
Objective: Make the already-open builder recover gracefully from backend/dev-server outages with one persistent retrying toast, degraded-but-usable UI, automatic reconnect detection, and no destructive dev auto reload.
Boundary: src/utils/, src/components/, src/systems/Api/, src/Main.res, src/App*.res, css/, rsbuild.config.mjs, tests/unit/
Owned Interfaces: NetworkStatus snapshot/retry API, offline/recovery notification UX, request retry connectivity classification, dev server reload policy
No-Touch Zones: backend/, project/export runtime logic, scene traversal/pathfinding behavior
Independent Verification: `npm run test:frontend` and `npm run build` pass, and the frontend compiles with connectivity snapshot + toast recovery behavior.
Depends On: 1845

# 1846 Connectivity Recovery Supervisor And Dev Reload Protection

Implement a resilient connectivity supervisor for the already-open builder session. When the backend or dev stack goes away, the app should enter a clear degraded mode, keep local editing usable, show a single persistent toast that explains retry status, and probe for recovery automatically with sensible backoff. When the backend returns, the app should detect recovery on its own and clear the outage state without requiring a manual page refresh.

The current experience is fragmented across an amber offline banner, generic API retry/error toasts, and Rsbuild dev-server refresh behavior that can wipe unsaved work. Unify those flows so users see one coherent recovery model and the open tab stays stable while services restart.

Acceptance:
- Outages drive a single persistent connectivity toast with live retry/recovery messaging instead of stacked red request toasts.
- The app enters a degraded-but-usable visual state while offline/recovering.
- Local editing remains usable during degradation while server-backed actions still fail fast/cleanly.
- Recovery is detected automatically when the backend returns and the connectivity toast clears cleanly.
- The first outage transition forces an immediate local persistence flush.
- Dev auto reload/HMR is enabled by default again so frontend source changes refresh the active builder during development.
- `npm run build` succeeds.

Implementation Notes:
- Extend `NetworkStatus` to publish richer connectivity snapshots with retry timing and recovery phases.
- Replace `OfflineBanner`’s visual banner role with connectivity toast/orchestration behavior tied to `NotificationManager`.
- Fold request-layer transport failures and retries into the same connectivity incident instead of independent warning/error chains.
- Apply degraded visual treatment via app/body classes and a non-blocking overlay while preserving colorful notifications.
- Keep a dev-only Rsbuild toggle so automatic refresh can still be explicitly disabled when needed.

Verification:
- `npm run test:frontend`
- `npm run build`
