# Task 199 Report: Enhance GlobalStateBridge Safety

## 🚀 Objective
Review and harden the `GlobalStateBridge` to prevent "Zombie dispatch" and "Stale Reads" by ensuring it stays in sync with React state immediately and allows for proper cleanup.

## 🛠️ Implementation Details
1.  **GlobalStateBridge Encapsulation**:
    -   Updated `subscribe` to return an unsubscribe function (cleanup).
    -   Replaced deprecated `Js.Array2` methods with standard `Array` module methods.

2.  **AppContext Synchronization**:
    -   Switched `GlobalStateBridge` synchronization to `React.useLayoutEffect`. This ensures the bridge is updated synchronously after DOM mutations but before paint, preventing stale state reads in layout effects or immediate subsequent operations.
    -   Kept `SessionStore` persistence in `React.useEffect` (with debounce) to avoid blocking the main thread/paint.

3.  **Consumer Updates**:
    -   Updated `VisualPipeline.res` to handle the new subscription signature (ignoring the unsubscribe function as the pipeline is long-lived).
    -   Updated `GlobalStateBridgeTest.res` to verify that unsubscription actually works.

## 🔍 Verification
-   **Tests**: `GlobalStateBridgeTest` verifies subscription and unsubscription.
-   **Integration**: Full frontend test suite passed, confirming no regressions in `VisualPipeline` or other components.
-   **Safety**: Synchronous updates via `useLayoutEffect` reduce the risk of race conditions between React state and the imperative Bridge state.
