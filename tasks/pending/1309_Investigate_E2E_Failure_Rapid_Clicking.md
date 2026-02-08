---
title: Investigate E2E Failure: Rapid Scene Clicking
status: pending
priority: high
tags:
  - testing
  - e2e
  - investigation
  - bug
  - fsm
---

# 🕵️ Investigator: E2E Failure - Rapid Scene Clicking

## 🚨 Incident Report
- **Test File**: `tests/e2e/rapid-scene-switching.spec.ts`
- **Test Case**: `rapid scene clicking should not hang`
- **Failure**: Timeout (1m). Test did not complete execution or verification.
- **Log**:
  ```
  ✘   1 [chromium] › tests/e2e/rapid-scene-switching.spec.ts:50:3 › FSM Interaction Logic › rapid scene clicking should not hang (1.0m)
  ```
- **Context**: The test simulates rapid user clicks on scene thumbnails to stress-test the `TransitionLock` and `SceneLoader` logic. A timeout suggests the app entered a deadlock state or the lock never released, preventing further interaction.

## 🎯 Objective
Investigate why rapid clicking causes the application or test to hang/timeout despite recent `TransitionLock` hardening.

## 🛠️ Investigation Steps
1.  **Reproduce Locally**: Run `npx playwright test tests/e2e/rapid-scene-switching.spec.ts --project=chromium --debug`.
2.  **Analyze TransitionLock**: Check console logs for `LOCK_REJECTED` loops or `LOCK_ACQUIRED` without release.
3.  **Check FSM State**: Verify if `NavigationFSM` gets stuck in `Preloading` or `Transitioning`.
4.  **Fix**:
    - Adjust `TransitionLock` timeouts or retry logic.
    - Ensure `SceneLoader` handles cancellation correctly.

## ✅ Acceptance Criteria
- [ ] Test `rapid-scene-switching.spec.ts` passes consistently.
- [ ] Application recovers gracefully from rapid scene clicks.
