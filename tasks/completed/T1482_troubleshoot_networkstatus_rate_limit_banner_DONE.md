# T1482 - Troubleshoot NetworkStatus False Offline on Rate Limit

## Goal
Make the app report the real issue when backend health checks are rate-limited, instead of showing a generic offline banner.

## Hypothesis (Ordered Expected Solutions)
- [ ] Health probe treats all non-2xx as offline; classify 429 separately and expose reason/details to UI.
- [ ] Offline banner currently only renders boolean state and static text; it should read status details from NetworkStatus.
- [ ] Logging should include degraded/rate-limited condition to aid diagnosis.

## Activity Log
- [ ] Inspect NetworkStatus + OfflineBanner flow.
- [ ] Add status details API and reason classification in probe.
- [ ] Update banner text for rate-limit case (include retry-after seconds if available).
- [ ] Verify with build.

## Code Change Ledger
- [ ] src/utils/NetworkStatus.res - reason/details model and probe classification for 429.
- [ ] src/components/ui/OfflineBanner.res - dynamic message rendering by reason.
- [ ] (Optional) src/utils/Logger.res - richer message handling if needed.

## Rollback Check
- [ ] Confirm only intended files changed; revert non-working changes if any.

## Context Handoff
If interrupted: NetworkStatus currently exposes only bool and emits generic offline state. The fix is to add reason metadata and classify HTTP 429 from /api/health as backend-rate-limited/degraded. OfflineBanner should render that reason directly so users know they are blocked by rate limiting, not disconnected.
