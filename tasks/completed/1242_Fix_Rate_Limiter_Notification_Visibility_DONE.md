# Task 1242: Fix Rate Limiter Notification Coverage

## Objective
Ensure that the rate limiter notification is visible to the user across all throttled systems, specifically in `ViewerSnapshot`.

## Problem Analysis
- `Hooks.useThrottledAction` correctly dispatches notifications via `EventBus`.
- However, `ViewerSnapshot.res` uses `RateLimiter` directly with a custom `Debounce` and only logs `SNAPSHOT_RATE_LIMITED` without notifying the UI.

## Proposed Solution
- Update `ViewerSnapshot.res` to dispatch a `ShowNotification` event when `RateLimiter.canCall` returns false.
- Standardize the message to include "Please wait" to satisfy E2E test requirements.

## Acceptance Criteria
- [ ] A notification containing "wait" (or similar) appears when rate limiting is active.
- [ ] Corresponding test in `robustness.spec.ts` passes.
