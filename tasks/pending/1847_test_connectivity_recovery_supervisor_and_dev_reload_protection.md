# 1847 Test Connectivity Recovery Supervisor And Dev Reload Protection

## Objective
Manually validate the connectivity recovery and dev-reload protections that were just implemented for the already-open builder session, and confirm the UX stays coherent when the backend or frontend dev stack goes away and later comes back.

## Exact Implementation Already Completed
- Replaced the old bool-style connectivity model with a snapshot-driven supervisor in [src/utils/NetworkStatus.res](src/utils/NetworkStatus.res) and [src/utils/NetworkStatus.resi](src/utils/NetworkStatus.resi).
- Added richer connectivity phases and retry metadata so the app can distinguish healthy, browser-offline, recovering, and rate-limited states.
- Added active probe and recovery hooks: `probeNow`, `reportBackendUnavailable`, `reportRateLimited`, `reportTransportFailure`, and `reportRequestSuccess`.
- Added retry scheduling with capped backoff and focus-based reprobe so the app can detect backend recovery without a manual full page reload.
- Reworked [src/components/ui/OfflineBanner.res](src/components/ui/OfflineBanner.res) into the connectivity incident controller instead of a simple amber banner.
- Changed the outage UX to one persistent connectivity toast with live retry details instead of stacked red request-failure toasts.
- Added a degraded visual state with a grayscale/dim overlay in [css/layout.css](css/layout.css) while keeping notifications readable and colorful.
- Added toast detail rendering and same-context refresh support in [src/components/NotificationCenter.res](src/components/NotificationCenter.res) and [src/core/NotificationManager.res](src/core/NotificationManager.res) so the retry countdown/status can update in place.
- Integrated request-layer transport and availability failures into the shared connectivity supervisor in [src/systems/Api/AuthenticatedClient.res](src/systems/Api/AuthenticatedClient.res), [src/systems/Api/AuthenticatedClientRequest.res](src/systems/Api/AuthenticatedClientRequest.res), and [src/systems/Api/AuthenticatedClientRequestRuntime.res](src/systems/Api/AuthenticatedClientRequestRuntime.res).
- Kept internal retry flows able to recover during `RecoveringPhase` instead of failing permanently behind the global offline gate.
- Forced an immediate local persistence flush on the first degradation transition in [src/utils/PersistenceLayer.res](src/utils/PersistenceLayer.res) so in-progress work is saved before the user keeps editing offline.
- Restored Rsbuild auto reload/HMR by default in [rsbuild.config.mjs](rsbuild.config.mjs); explicit opt-out is now `RSBUILD_AUTO_RELOAD=0`.

## Manual QA Checklist
- [ ] Start the app normally, confirm no degraded overlay/toast is present while healthy.
- [ ] Stop the backend while the builder tab is already open and confirm:
  - one persistent connectivity toast appears
  - the shell becomes visually degraded
  - local editing remains usable
  - generic red request-failure toasts do not start stacking
- [ ] Restart the backend and confirm the app auto-detects recovery without a manual reload, clears the degraded state, and replaces the outage toast with a recovery message.
- [ ] Turn browser offline mode on and off in DevTools and confirm the same recovery model works for browser connectivity loss.
- [ ] Trigger a retryable request during degradation and confirm the toast updates rather than duplicating incidents.
- [ ] Confirm a first degradation transition forces local persistence without blocking editing.
- [ ] Stop `npm run dev`, keep the already-open browser tab alive, then bring the dev stack back and confirm the frontend reconnects and resumes its normal auto-refresh behavior once the dev server is back.
- [ ] Optionally rerun with `RSBUILD_AUTO_RELOAD=0` and confirm automatic dev reload can still be disabled intentionally.

## Automated Verification Already Completed
- `npm run test:frontend`
- `npm run build`

## Relevant Coverage Added
- [tests/unit/utils/NetworkStatus_v.test.res](tests/unit/utils/NetworkStatus_v.test.res)
- [tests/unit/NotificationManager_v.test.res](tests/unit/NotificationManager_v.test.res)
- [tests/unit/AuthenticatedClient_v.test.res](tests/unit/AuthenticatedClient_v.test.res)
