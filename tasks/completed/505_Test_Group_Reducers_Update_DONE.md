# Task 505: Update Unit Tests for Reducers (DONE)

## 🚨 Trigger
Multiple reducer implementation files are newer than their tests.

## Objective
Update the corresponding unit tests for the following reducers to ensuring they cover recent changes and maintain 100% code coverage.

## Sub-Tasks
- [x] **TimelineReducer** (`src/core/reducers/TimelineReducer.res`) - Verified tests.
- [x] **HotspotReducer** (`src/core/reducers/HotspotReducer.res`) - Verified tests.
- [x] **NavigationReducer** (`src/core/reducers/NavigationReducer.res`) - Added missing test cases.
- [x] **Actions** (`src/core/Actions.res`) - Verified tests.
- [x] **ReducerHelpers** (`src/core/reducers/ReducerHelpers.res`) - Verified tests.
- [x] **ProjectReducer** (`src/core/reducers/ProjectReducer.res`) - Verified tests.
- [x] **SimulationReducer** (`src/core/reducers/SimulationReducer.res`) - Verified tests.
- [x] **ViewerState** (`src/components/ViewerState.res`) - Added missing test for `getInactiveContainerId`.

## Implementation Details
- Updated `tests/unit/NavigationReducer_v.test.res` to cover `SetIncomingLink`, `ResetAutoForwardChain`, `SetPendingReturnSceneName`, `IncrementJourneyId`, `SetCurrentJourneyId`.
- Updated `tests/unit/ViewerState_v.test.res` to cover `getInactiveContainerId`.
- Verified all reducer tests pass.
- Verified build passes.

## Verification
- `npm run test:frontend` passed (subset of tests related to reducers).
- `npm run build` passed.
