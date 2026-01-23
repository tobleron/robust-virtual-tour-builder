# Task 321: Update Unit Tests for UiReducer.res - REPORT

## Objective
Update `tests/unit/UiReducerTest.res` to ensure it covers recent changes in `UiReducer.res`.

## Fulfilment
- Reviewed `src/core/reducers/UiReducer.res` and `tests/unit/UiReducerTest.res`.
- Confirmed that all actions handled by the reducer (`SetPreloadingScene`, `StartLinking`, `StopLinking`, `UpdateLinkDraft`, `SetIsTeasing`) are already covered by existing tests.
- Verified all tests pass by running `npx vitest run tests/unit/UiReducerTest.bs.js`.
