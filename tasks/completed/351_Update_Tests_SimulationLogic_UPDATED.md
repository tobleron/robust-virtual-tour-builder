# Task 351: Update Unit Tests for SimulationLogic.res - REPORT

## Objective
Update `tests/unit/SimulationLogic_v.test.res` to ensure it covers recent changes in `SimulationLogic.res`, specifically including `viewFrame` handling, chain skipping logic, and timeline synchronization.

## Fulfillment
- **Comprehensive Test Suite**: Added tests for `viewFrame` and `returnViewFrame` handling to verify correct coordinate extraction.
- **Chain Skipping Verification**: Implemented tests for `skipAutoForwardGlobal` to ensure bridge scenes are correctly skipped and added to `visitedScenes`.
- **Timeline Synchronization**: Added testing for `SetActiveTimelineStep` action generation based on the state's timeline.
- **Edge Case Coverage**: Covered completion logic (return to start) and invalid active index cases.
- **Standards Adherence**: Used `toContainEqual` for deep equality checks of variant actions and followed `/testing-standards.md`.

## Result
9 tests passing in `tests/unit/SimulationLogic_v.test.res`.
