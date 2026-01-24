# Task 318: Update Unit Tests for Actions.res - REPORT

## Objective
Update `tests/unit/ActionsTest.res` to ensure it covers recent changes in `Actions.res`.

## Fulfilment
- Reviewed `src/core/Actions.res` and identified missing tests for simulation actions and session management.
- Updated `tests/unit/ActionsTest.res` to include tests for:
    - `StartAutoPilot`
    - `StopAutoPilot`
    - `AddVisitedScene`
    - `ClearVisitedScenes`
    - `SetStoppingOnArrival`
    - `SetSkipAutoForward`
    - `UpdateAdvanceTime`
    - `SetPendingAdvance`
    - `SetSessionId`
- Verified all actions pass the `actionToString` test by running `npm run test:frontend` after a clean ReScript build.
