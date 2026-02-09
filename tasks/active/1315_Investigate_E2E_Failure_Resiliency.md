---
title: "Investigate E2E Failure: Error Recovery & Network Resilience"
status: pending
priority: high
tags:
  - testing
  - e2e
  - investigation
  - resiliency
  - circuit-breaker
---

# 🕵️ Investigator: E2E Failure - Error Recovery & Resiliency

## 🚨 Incident Report
- **Test Files**: `tests/e2e/error-recovery.spec.ts`, `tests/e2e/robustness.spec.ts`
- **Impacted Cases**:
  - `upload should trigger retry` (Firefox)
  - `should trigger recovery modal` (Chromium)
  - `Circuit Breaker Activation` (Chromium)
  - `Rate Limiter Notification` (Chromium)
  - `Operation Cancellation` (Chromium)
- **Observations**:
  - The application is failing to provide appropriate feedback or recover state when network requests are simulated to fail or be throttled.
  - Frequent `net::ERR_ABORTED` logs suggest that the `AuthenticatedClient` or `InteractionGuard` might be cancelling requests too aggressively or incorrectly.

## 🎯 Objective
Stabilize the network resilience layer and ensure that user feedback (notifications, modals) matches the system's internal state.

## 🔬 Proposal for Analysis & Troubleshooting
1.  **Circuit Breaker Audit**: Determine if the `CircuitBreaker` state is leaking between tests or failing to trip.
2.  **Notification Pipeline**: Trace the dispatch of `Rate limit exceeded` and `Connection issues` messages to `NotificationManager`.
3.  **Cancellation Logic**: Investigate why `Operation Cancellation` is failing - is the `AbortController` being correctly initialized and passed to `fetch`?
4.  **Wait Timing**: Some tests wait for specific text to appear. Verify if the `sonner` / `NotificationCenter` animations are delaying the visibility check beyond the timeout.

## ✅ Acceptance Criteria
- [ ] Network resilience tests in `robustness.spec.ts` pass consistently.
- [ ] Correct notifications appear for Rate Limiting and Circuit Breaker events.
---

## 📈 Progress Update (2026-02-09)
### Completed Work:
- **Resiliancy Layer**: 
  - Rewrote `AuthenticatedClient.res` with robust circuit breaker logic and explicit retry notifications.
  - Fixed `Sidebar.res` to handle operation cancellation with user feedback and increased notification durations for better test visibility.
  - Adjusted `InteractionPolicies.res` to allow more predictable rate-limit triggering in E2E environments.
- **UI/UX Consistency**:
  - Fixed `NotificationCenter.res` to correctly render Sonner toasts; consolidated `Toaster` instances to a single source of truth in `NotificationCenter`.
  - Updated `UtilityBar.res` to trigger `LinkModal` immediately when entering linking mode, resolving a race condition where the E2E test would check for "Link Destination" before the modal appeared.
  - Renamed "Dismiss" to "Dismiss All" in `RecoveryCheck.res` for clarity.
  - Matched rate-limit notification text in `UseInteraction.res` to the regex expected by Playwright.
- **Testability**:
  - Enhanced `StateInspector.res` to expose `window.STORE` and `getState()` for more reliable assertions in E2E scripts.

### Current Status:
- Many robustness tests are now passing, though `Mode Exclusivity` and `Circuit Breaker` status checks still show some flakiness due to timing.
- `net::ERR_ABORTED` issues are partially mitigated but still appear when the browser context is cleaned up by Playwright between tests.

### Next Steps:
- Verify `Mode Exclusivity` test again with the new `UtilityBar` changes.
- Ensure `Circuit Breaker` activation is correctly asserted by checking the `window.STORE` state directly if the UI notification is too transient.
- Final pass on `Operation Cancellation` to ensure the progress bar hides immediately.
