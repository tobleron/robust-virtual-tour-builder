# Task 91: Implement Reducer Slicing Pattern (COMPLETED)

## Summary
Successfully refactored the monolithic `Reducer.res` into a sliced architecture with domain-specific reducers combined by a `RootReducer`. This reduces cognitive load, improves maintainability, and allows for isolated testing of state logic.

## Changes
- **New Directory**: Created `src/core/reducers/` to house all reducer logic.
- **Slice Reducers**:
  - `SceneReducer.res`: Handles scene addition, deletion, reordering, and metadata.
  - `HotspotReducer.res`: Handles hotspot creation, removal, and view updates.
  - `UiReducer.res`: Handles simple UI state (modal toggles, linking mode).
  - `NavigationReducer.res`: Handles simulation mode, journey tracking, and auto-forwarding.
  - `TimelineReducer.res`: Handles timeline editing and step updates.
  - `ProjectReducer.res`: Handles project loading, resetting, and tour naming.
- **Root Reducer**: Created `RootReducer.res` which delegates actions to the appropriate slice.
- **Legacy Compatibility**: Updated `Reducer.res` to simply re-export `RootReducer.reducer`, ensuring `AppContext.res` and other consumers remain unchanged.
- **Shared Utilities**: Moved `insertAt` helper to `ReducerHelpers.res` for sharing across slices.
- **Testing**:
  - Added `tests/unit/SceneReducerTest.res`.
  - Added `tests/unit/HotspotReducerTest.res`.
  - Registered new tests in `TestRunner.res`.

## Verification
- **Build**: `npm run res:build` completed successfully.
- **Tests**: `npm run test:frontend` passed all tests, including legacy regression tests (`ReducerTest.res`) and new unit tests.

## Notes
The original `Reducer.res` was ~262 lines and growing. Now, each domain logic is separated, with the largest slice being under 100 lines. This structure allows for cleaner git diffs and easier feature additions in specific domains.
