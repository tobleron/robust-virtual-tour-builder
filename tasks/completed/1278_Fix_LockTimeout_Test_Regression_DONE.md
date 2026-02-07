# Task 1278: Fix LockTimeout Unit Test Regression

## Objective
Fix the failing unit test in `tests/unit/LockTimeout_v.test.res` to ensure the test suite returns to a passing state (Green).

## Context
During a full test run, the following failure was observed:
```
FAIL tests/unit/LockTimeout_v.test.bs.js > TransitionLock Time Tracking > getTotalTimeoutMs returns 15000
AssertionError: expected +0 to be 15000
```

**Analysis**:
The test `getTotalTimeoutMs returns 15000` attempts to verify the timeout duration for a `Loading` phase but fails to set the state to `Loading` before the assertion. Since `beforeEach` resets the lock to `Idle`, `getTotalTimeoutMs()` correctly returns `0.0`.

## Requirements
1.  **Modify Test**: Update `tests/unit/LockTimeout_v.test.res` to acquire a lock with `Loading("test")` phase before asserting the total timeout.
2.  **Verify**: Run `npm run test:frontend` to confirm the fix.
3.  **No Side Effects**: Ensure this change doesn't introduce flakiness.

## Implementation Details
```rescript
// tests/unit/LockTimeout_v.test.res

test("getTotalTimeoutMs returns 15000 when loading", t => {
  // 1. Acquire lock to enter Loading phase
  let _ = TransitionLock.acquire("test", Loading("scene1"))
  
  // 2. Assert
  let total = TransitionLock.getTotalTimeoutMs()
  t->expect(total)->Expect.toBe(15000)
})
```
