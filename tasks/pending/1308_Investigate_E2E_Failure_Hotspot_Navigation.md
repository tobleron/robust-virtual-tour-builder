---
title: Investigate E2E Failure: Hotspot Navigation
status: pending
priority: critical
tags:
  - testing
  - e2e
  - investigation
  - bug
---

# 🕵️ Investigator: E2E Failure - Hotspot Navigation

## 🚨 Incident Report
- **Test File**: `tests/e2e/navigation.spec.ts`
- **Test Case**: `should navigate between scenes via hotspot`
- **Failure**: Timeout waiting for hotspot click action or effect. 
- **Log**:
  ```
  ✘  1 [chromium] › tests/e2e/navigation.spec.ts:24:3 › Navigation Engine › should navigate between scenes via hotspot (31.7s)
  ```
- **Context**: The test attempts to click a `.pnlm-hotspot` element in the Pannellum viewer. This often fails if the hotspot is occluded, not interactive, or if the click doesn't trigger the expected `Actions.UserClickedScene` dispatch.

## 🎯 Objective
Investigate why hotspot navigation is failing in the E2E test.

## 🛠️ Investigation Steps
1.  **Reproduce Locally**: Run `npx playwright test tests/e2e/navigation.spec.ts --project=chromium --debug`.
2.  **Verify Hotspot Visibility**: Ensure the hotspot is actually rendered and clickable within the viewport.
3.  **Check Click Handling**: Verify that the click event is propagating to `SceneItem` or `HotspotManager`.
4.  **Fix**:
    - Adjust camera angle (`yaw`/`pitch`) in test setup to ensure hotspot is centered.
    - Use `force: true` for click if needed (though discouraged).
    - Check for overlay blocking (e.g., toast notifications).

## ✅ Acceptance Criteria
- [ ] Test `should navigate between scenes via hotspot` in `tests/e2e/navigation.spec.ts` passes consistently.
- [ ] Hotspot navigation is robust in automated tests.
