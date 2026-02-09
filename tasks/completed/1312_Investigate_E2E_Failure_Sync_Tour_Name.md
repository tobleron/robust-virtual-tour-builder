---
title: Investigate E2E Failure: Sync Tour Name Property
status: pending
priority: medium
tags:
  - testing
  - e2e
  - investigation
  - bug
---

# 🕵️ Investigator: E2E Failure - Sync Tour Name Property

## 🚨 Incident Report
- **Test File**: `tests/e2e/editor.spec.ts`
- **Test Case**: `should sync tour name property`
- **Failure**: Timeout waiting for input value update.
- **Log**:
  ```
  ✘   9 …Interactions › should sync tour name property (47.1s)
  ```
- **Context**: The `input.sidebar-project-input` is expected to update its value after typing 'Renamed Tour' and pressing Enter. The failure indicates either:
  - The type/fill action didn't register.
  - The React state update was delayed or lost.
  - The UI re-rendered unexpectedly, losing focus.

## 🎯 Objective
Investigate why the tour name input field is failing to synchronize or maintain state in the E2E test environment.

## 🛠️ Investigation Steps
1.  **Reproduce Locally**: Run `npx playwright test tests/e2e/editor.spec.ts --project=chromium --debug`.
2.  **Check Sidebar Logic**: Inspect `src/components/Sidebar/SidebarProjectInfo.res` for debounce or state handling issues.
3.  **Verify Event Handlers**: Ensure `onChange` and `onBlur`/`onKeyDown` are correctly implemented.
4.  **Fix**:
    - Add waitFor logic if async updates are causing race conditions.
    - Check for re-renders wiping input state.

## ✅ Acceptance Criteria
- [ ] Test `should sync tour name property` in `tests/e2e/editor.spec.ts` passes consistently.
- [ ] Sidebar project name input is robust against rapid typing and updates.
