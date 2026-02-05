# Deep Analysis: InteractionQueue

## Executive Summary

The `InteractionQueue` module in `src/core/InteractionQueue.res` attempts to manage application stability by serializing actions and enforcing "stability checks" (polling the DOM and Navigation FSM) before execution.

**Conclusion:** The module is **largely redundant** and relies on **anti-patterns** (DOM polling) that are fragile and inconsistent with modern React architecture. The claim that "DOM will not respect it" is accurate: the browser's event loop operates independently of this logical queue, leading to disconnected states where user inputs are either silently dropped or delayed without feedback.

## Implementation Analysis

### Core Mechanism
The `InteractionQueue` functions as a serial command processor:
1.  **Queue**: Holds `Action`, `Thunk`, or `Barrier` items.
2.  **Processing**: Items are processed one-by-one.
3.  **Stability Wait**: Before executing an item, the processor enters a polling loop (`waitForStability`) that checks:
    *   **Navigation Stability**: Is the `NavigationFSM` in an `Idle` or `Error` state?
    *   **UI Stability**: Does the DOM element `#processing-ui` contain the class `hidden`?

### The Barrier Flaw
The `Barrier` mechanism (used for `LoadProject`) sets a flag `isBarrierPending`.
*   **Behavior**: When a barrier is active, `waitForStability` blocks execution.
*   **Rejection**: Crucially, any *new* actions dispatched via `enqueue` during this time are **rejected immediately** with a warning log (`ENQUEUE_REJECTED_BARRIER_ACTIVE`).
*   **Result**: The user can click buttons, but the actions are silently swallowed. The queue does not buffer them; it discards them.

## "DOM Will Not Respect It" - Validated

The user's claim is correct for several reasons:

1.  **Independent Event Loops**: The browser's main thread handles UI events (clicks, scrolls) independently of the `InteractionQueue`'s async processing loop. The queue cannot stop the user from physically interacting with the page.
2.  **Silent Rejection**: Because the DOM elements (buttons) remain enabled during "unstable" states (unless manually disabled by the component), the user *expects* interaction. The queue, however, might silently drop the interaction (during Barrier) or delay it unpredictably (during Stability Wait).
3.  **Bypassed Logic**: In `src/components/SceneList.res`, the component performs its *own* check of `InteractionQueue.isAppStable()` and rejects the user interaction with a toast notification ("Switching too fast"). This renders the Queue's internal "wait until stable" logic redundant for this interaction path. The UI isn't using the queue to buffer; it's using the stability check to block.

## Enterprise Standards Comparison

| Feature | `InteractionQueue` Implementation | Enterprise Standard |
| :--- | :--- | :--- |
| **Race Condition Handling** | Serializes actions via a global queue + polling. | State Machines (e.g., XState) or strictly defined transition states in Redux/Context. |
| **Stability Checks** | **Anti-Pattern**: Polls the DOM (`document.getElementById`) to infer state. | **Source of Truth**: Checks the Store/State directly. The View reflects the State; Logic never reads the View. |
| **User Feedback** | Silently drops actions (Barrier) or delays them. | **Optimistic UI** or **Explicit Loading States** (disabled buttons, spinners, skeleton loaders). |
| **Concurrency** | Custom async loop with `setTimeout`. | React `useTransition`, `AbortController` for network requests, or RxJS for complex event streams. |

## Conclusion on Utility

**Is it useful?**
It acts as a rudimentary safety net for "leaky" UI components that fail to properly disable interactions during async operations. It prevents some crashes by forcing sequential execution (e.g., ensuring a transition finishes before a delete occurs).

**Is it redundant?**
**Yes.** In a robust, commercial-grade application:
1.  **Stability** should be enforced by the component state (e.g., `isNavigating` prop disables the "Delete" button).
2.  **DOM Polling** is unnecessary and brittle. Logic should never depend on CSS classes.
3.  **Serialization** should happen via proper async state management (Promises/Sagas), not a global event loop patch.

**Recommendation:**
The `InteractionQueue` creates a false sense of security while introducing fragility (DOM coupling). It should eventually be replaced by:
1.  **Strict State Machines** for Navigation and Project Loading.
2.  **UI Component States** that accurately reflect `isLoading` / `isProcessing` to physically disable interactions in the DOM.
