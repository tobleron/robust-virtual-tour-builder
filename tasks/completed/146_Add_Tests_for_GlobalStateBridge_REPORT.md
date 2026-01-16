# Task 146: Add Unit Tests for GlobalStateBridge - REPORT

## 🎯 Objective
Create a unit test file to verify the logic in `src/core/GlobalStateBridge.res`.

## 🛠 Technical Implementation
- Created `tests/unit/GlobalStateBridgeTest.res` with the following test cases:
    - **Initial State**: Verified `getState()` returns the expected initial state.
    - **setState/getState**: Verified that `setState()` correctly updates the global state and `getState()` retrieves it.
    - **Subscription/Notification**: Verified that `subscribe()` correctly registers a listener and that it is notified with the new state when `setState()` is called.
    - **Dispatch**: Verified that `setDispatch()` correctly sets the global dispatch function and `dispatch()` invokes it with the provided action.
- Registered the new test module in `tests/TestRunner.res`.
- Verified that all frontend tests pass using `npm run test:frontend`.

## ✅ Realization
- `tests/unit/GlobalStateBridgeTest.res` implemented.
- `tests/TestRunner.res` updated.
- All tests passed successfully.
