# Task 319: Update Unit Tests for ReducerHelpers.res - REPORT

## Objective
Update `tests/unit/ReducerHelpersTest.res` to ensure it covers recent changes in `ReducerHelpers.res`.

## Fulfilment
- Reviewed `src/core/ReducerHelpers.res`.
- Updated `tests/unit/ReducerHelpersTest.res` to fix a mismatch in the expected default tour name ("Tour Name" instead of "Imported Tour").
- Added a new test case for `handleRemoveHotspot` logic, verifying that it correctly removes hotspots and resets the `isAutoForward` flag on target scenes when appropriate.
- Verified all tests pass by running `npm run test:frontend`.
