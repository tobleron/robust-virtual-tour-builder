---
description: Enhance GlobalStateBridge Safety and Coupling
---

# Enhance GlobalStateBridge Safety

## 🚀 Objective
Review and harden the `GlobalStateBridge`. Currently, it exists to allow non-React code (like standard JS scripts or some listeners) to dispatch actions or read state. If not tightly coupled to the React lifecycle, it can lead to "Zombie dispatch" (dispatching to a dead component) or "Stale Reads".

## 🛠️ Implementation Steps

1.  **Review `GlobalStateBridge.res`**:
    *   Ensure it holds a `ref` to the current state.
    *   Ensure `setState` updates this `ref` immediately.

2.  **Review `AppContext.res` Provider**:
    *   Confirm `GlobalStateBridge.setState(state)` is called in a `useEffect` layout effect or immediate effect.
    *   **Critical**: React `setState` is asynchronous. If we rely on `GlobalStateBridge` for synchronous logic, ensure we understand the delay.

3.  **Synchronization**:
    *   If possible, move `GlobalStateBridge` updates to the *Reducer* itself (side effect) OR ensure components using it handle potential 1-frame lags.
    *   *Better Approach*: The `GlobalStateBridge` is updated in `AppContext`'s render loop. Verify this is robust.

4.  **Clean Up**:
    *   Ensure `GlobalStateBridge` listeners (if any) are cleaned up on unmount (though `AppContext` rarely unmounts).

## 🔍 Validation
*   Check console logs for any "Cannot update a component while rendering a different component" warnings.
*   Verify that `window.store.getState()` always returns the fresh state visible in the UI.
