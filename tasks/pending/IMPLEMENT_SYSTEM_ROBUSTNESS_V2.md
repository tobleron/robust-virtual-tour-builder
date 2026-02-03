# TASK: Implement System-Wide Robustness & UI-Sync Protocol

## 1. Problem Statement
The current `InteractionQueue.res` successfully manages logical action serialization but remains decoupled from the Physical UI (DOM) and the Component Lifecycle (React). This results in:
- **UI Interception**: Modals/Overlays blocking interactions without disabling the underlying UI buttons.
- **State Wipes**: Destructive state replacement during `LoadProject` while navigation is mid-flight.
- **Telemetry Loss**: Aborted fetch requests during rapid component unmounting.

## 2. Technical Requirements

### A. Physical UI Synchronization (Pointer-Lock)
- **Status:** Implement a global "System Lock" that reacts to `InteractionQueue.isProcessing`.
- **Implementation:**
    - In `App.res`, add a `pointer-events-none` overlay or class to the `#viewer-container` and `Sidebar` whenever the queue is busy.
    - Map the `isProcessing` ref from `InteractionQueue` to a global React context state.

### B. Modal-Aware Interaction Guard
- **Status:** Buttons must be "State-Aware" to prevent "Phantom Click" failures.
- **Implementation:**
    - Create a utility hook `useIsInteractionPermitted()` that returns `false` if (Queue.isProcessing || Modal.isOpen || Navigation.isTransitioning).
    - Apply this to all primary Sidebar actions (Add Link, Save, Export).

### C. The "Barrier Action" Protocol (Load/Reset)
- **Status:** `LoadProject` must act as a barrier, not a standard action.
- **Implementation:**
    - Modify `InteractionQueue.res` to support "Priority" or "Barrier" actions.
    - When a `LoadProject` action enters the queue, it must:
        1. Stop all incoming events.
        2. Wait for `NavigationFsm` to reach `Idle` or `Error`.
        3. Flush the `SessionStore`.
        4. Execute the state reset.

### D. Unified Telemetry (sendBeacon)
- **Status:** Ensure zero-loss logging during rapid unmounts.
- **Implementation:**
    - Update `Logger.res` and `ProjectApi.res` to prioritize `navigator.sendBeacon` for `/telemetry/batch` and `/telemetry/error`.
    - Fallback to `fetch` only if `sendBeacon` is unavailable.

## 3. Verification Criteria
- [ ] Playwright `robustness.spec.ts` passes 100% across all browsers.
- [ ] No `net::ERR_ABORTED` messages for telemetry in browser logs.
- [ ] Buttons are visually disabled/unclickable while the "Upload Summary" modal is visible.
- [ ] Rapid "Save + Navigate" sequence no longer causes the Sidebar to unmount.

## 4. References
- `src/core/InteractionQueue.res`
- `src/core/Reducer.res`
- `tests/e2e/robustness.spec.ts`
