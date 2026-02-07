# Task 1280: Fix Notification System Regression Dectected in E2E

## Objective
Restore critical user feedback by invalidating and fixing the Notification/Modal system regression causing E2E failures.

## Context
During a full E2E test run, `tests/e2e/error-recovery.spec.ts` failed multiple scenarios because expected UI feedback was missing:
1.  **Retry Notification**: `expect(locator('text=/Retrying/i')).toBeVisible()` timed out (30s).
2.  **Error Toast**: `expect(locator('text=/Failed to load project/i')).toBeVisible()` timed out (10s).
3.  **Recovery Modal**: `expect(locator('role=dialog')).toBeVisible()` timed out (15s).

Technical Diagnosis:
The core `NotificationLayer` or `EventBus` integration appears to be broken. UI feedback for errors and retries is likely being dispatched but not rendered, or rendered behind other layers (Z-index issue), or the listeners are detached.

## Requirements
1.  **Investigate**: Use `tests/e2e/error-recovery.spec.ts` as a reproduction harness.
2.  **Fix**: Ensure `NotificationLayer` is correctly mounted and subscribing to `ShowNotification` events. Verify `RecoveryPrompt` (dialog) mounting logic.
3.  **Verify**: Run `npx playwright test tests/e2e/error-recovery.spec.ts` and ensure all tests pass.

## Implementation Steps
1.  Uncomment `webServer` in `playwright.config.ts` (locally) or run dev server manually.
2.  Run `npx playwright test tests/e2e/error-recovery.spec.ts` to confirm failure.
3.  Debug `src/components/NotificationLayer.res` and `src/core/GlobalStateBridge.res` or relevant event dispatchers.
4.  Fix the issue (likely re-binding or Z-index adjustment).
5.  Verify fix with E2E test.
