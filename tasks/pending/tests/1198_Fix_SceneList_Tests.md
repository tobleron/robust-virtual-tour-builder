# Task 1198: Fix SceneList Tests

## Objective
Fix `should throttle scene switching clicks` failure in `tests/unit/SceneList_v.test.res`.

## Context
The test expects `SetActiveScene` to be dispatched but fails (likely dispatching nothing or timing out).
`ViewerState.state.contents.lastSwitchTime` mocking and `wait()` duration might be the cause, or interaction with `InteractionQueue` stability checks.

## Requirements
- Debug why `SetActiveScene` is not dispatched.
- Verify if `InteractionQueue` is blocking dispatch due to "unstable" state in test environment.
- Fix the test.
