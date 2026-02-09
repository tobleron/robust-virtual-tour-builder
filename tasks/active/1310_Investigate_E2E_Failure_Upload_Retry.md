---
title: Investigate E2E Failure: Network Failure Upload Retry
status: pending
priority: high
tags:
  - testing
  - e2e
  - investigation
  - bug
---

# 🕵️ Investigator: E2E Failure - Upload Retry

## 🚨 Incident Report
- **Test File**: `tests/e2e/error-recovery.spec.ts`
- **Test Case**: `4.1: Network failure during upload should trigger retry`
- **Failure**: Timeout waiting for "Retrying" notification.
- **Log**:
  ```
  ✘   4 …rk failure during upload should trigger retry (31.0s)
  Simulating network failure for upload...
  Success on retry!
  ```
- **Observation**: The console log says "Success on retry!", implying the network mock logic worked, but the UI notification expectation `expect(page.locator('text=/Retrying/i')).toBeVisible()` failed (timed out). This means the user is not being feedbacked correctly about the retry attempt.

## 🎯 Objective
Investigate why the "Retrying..." notification is not appearing or not being detected by the test, and fix the underlying issue (either in the application code or the test assertion).

## 🛠️ Investigation Steps
1.  **Reproduce Locally**: Run `npx playwright test tests/e2e/error-recovery.spec.ts --project=chromium --debug` to watch the behavior.
2.  **Verify Notification Logic**: Check `src/utils/Retry.res` or where the retry logic emits notifications.
3.  **Check Notification Manager**: Ensure `NotificationManager` is receiving the dispatch.
4.  **Fix**:
    - If the notification is missing: Add it to the retry logic.
    - If the notification is too fast: Adjust test wait or persistence.
    - If the text is different: Update the test locator.

## ✅ Acceptance Criteria
- [ ] Test `4.1` in `tests/e2e/error-recovery.spec.ts` passes consistently.
- [ ] "Retrying..." notification is visible to the user during transient failures.
