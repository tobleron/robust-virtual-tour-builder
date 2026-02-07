# Task 1262: Implement Transition Lock Timeout and User Feedback

## Issue
When switching scenes rapidly, the `TransitionLock` can enter an infinite locked state if an operation fails or hangs without releasing the lock. The user receives no feedback about this stuck state, leading to a "frozen" application experience.

## Goal
Implement a robust timeout mechanism for the `TransitionLock` and provide clear user feedback when a lock persists longer than expected, allowing for recovery.

## Context
- **Locking Mechanism**: `src/core/TransitionLock.res` manages the viewer's async state.
- **Current Behavior**: The lock is acquired during `Preloading` or `Transitioning`. If the async operation managing the lock doesn't call `release()`, the system stays locked forever.
- **Missing Safety**: There is no automatic timeout to forcibly release the lock if an operation stalls.
- **Missing UX**: The UI does not differentiate between "working" (normal load) and "stuck" (timed out).

## Plan
1.  **Analyze `TransitionLock.res`**:
    - Add a `timeout` mechanism to `acquire()`.
    - If the lock is held for > X seconds (e.g., 5s or 10s), automatically release it or trigger a "recovery" state.
    - Log an error when a forced release occurs.

2.  **Update `ViewerUI` / Notification System**:
    - If the lock is held for > 3s, show a "Loading..." spinner or toast.
    - If the lock times out, show an error notification ("Transition took too long, retrying...") and reset the state.

3.  **Refine `SceneLoader`**:
    - Ensure all paths (success and failure) in `SceneLoader` explicitly release the lock.
    - The new timeout will act as a safety net for edge cases.

4.  **Verification**:
    - Create a test case that simulates a "hung" transition and verifies the timeout releases the lock.
