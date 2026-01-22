# Task 009: Add Unit Tests for UiReducer

## 🎯 Objective
Create a unit test file to verify the logic in `src/core/reducers/UiReducer.res` using the Vitest framework.

## 🛠 Technical Implementation
- Updated `tests/unit/UiReducerTest.res` with comprehensive tests for:
  - `SetPreloadingScene`
  - `StartLinking`
  - `StopLinking`
  - `UpdateLinkDraft`
  - `SetIsTeasing`
- Updated `vitest.config.mjs` to include `tests/unit/UiReducerTest.bs.js`.
- Verified tests pass with `npx vitest run`.
- Confirmed `npm run test:frontend` and `npm run build` pass.

## 📝 Notes
- Implemented tests covering all action handlers in `UiReducer`.
- Ensured state immutability checks via the reducer return pattern.