# Task 1246: Handle Malformed Project Files Gracefully

## Objective
Improve error handling when importing malformed or invalid project ZIP files to prevent application instability.

## Problem Analysis
- `SceneHelpers.parseProject` logs an error and returns `State.initialState` when decoding fails. This results in the UI showing "0 scenes" without an error message, which is confusing for the user and fails the E2E test.
- The `SidebarLogic` doesn't check if the returned state is the initial (empty) state after a load.

## Proposed Solution
- Modify `SceneHelpers.parseProject` to return a `result<state, string>` instead of just `state`.
- Update `SidebarLogic.res` to handle the error case and show a Toast notification with the specific parsing error (e.g., "Missing tourName").

## Acceptance Criteria
- [ ] Malformed project imports show a clear error notification.
- [ ] The application remains responsive and stable after the error.
- [ ] Corresponding test in `error-recovery.spec.ts` passes.
