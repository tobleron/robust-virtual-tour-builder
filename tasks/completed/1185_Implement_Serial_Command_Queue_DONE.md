# 🏗️ Task 1185: Implement Serial Interaction Queue (Anti-Race Architecture)

## 🎯 OBJECTIVE
Eliminate logical race conditions by implementing a strictly sequential **Command Queue** for all user interactions. This ensures that the application state fully "settles" (side effects concluded, FSMs idle) before the next user-initiated action is processed.

## 🧠 ARCHITECTURAL SPECIFICATION

### 1. `src/core/InteractionQueue.res`
Create a new core module to orchestrate the command pipeline:
- **Internal State**: 
  - A mutable queue (Array or specialized structure) for pending `Actions.action`.
  - A `isProcessing` flag to prevent concurrent execution loops.
- **The Execution Loop**:
  - `push(action: action)`: Adds to queue and triggers `process()`.
  - `process()`: 
    - If `isProcessing` is true, return.
    - Set `isProcessing = true`.
    - Pop `nextAction`.
    - **Dispatch**: Send `nextAction` to the root reducer via the standard `dispatch`.
    - **Await Settlement**: Wait for the application to signal it is "Stable".
    - Set `isProcessing = false`.
    - Recurse if queue is not empty.

### 2. Settlement Protocol
Define "Settled" status across systems. An interaction is finished only when:
- **Navigation**: `NavigationFSM` is in `Idle`.
- **Loading**: `SceneLoader` is not in a `Preloading` or `Loading` state.
- **Animations**: Any active `ViewPort` animations (arrows, pans) are complete.
- **Processing**: Global processing (resizing, uploads) is either finished or strictly backgrounded.

Mechanism: Use `EventBus` or a specialized `StabilityGuard` hook to track these states.

### 3. AppContext Integration
- Modify `src/core/AppContext.res` to provide an `enqueue` function alongside (or as a replacement for) `dispatch`.
- Technical standard: `enqueue` should return a `Promise<unit>` that resolves when the action AND its subsequent settlement are complete.

### 4. Safety & Recovery
- **Timeout**: Enforce a maximum "Lock" time (e.g., 2000ms). If the app doesn't signal stability within this window, force-release the lock and log a `STABILITY_TIMEOUT_ERROR` via `Logger.error`.
- **Priority**: System-internal actions (e.g., `DispatchNavigationFsmEvent(TransitionComplete)`) should bypass the queue to avoid deadlocks.

## 🛠️ IMPLEMENTATION STEPS
1. **Define Stability Interface**: Identify which states in `State.res` constitute "Busy".
2. **Implement `InteractionQueue`**: Robust ReScript v12 module with integrated `Logger` telemetry.
3. **Bridge to Reducer**: Ensure the queue has access to the app's `dispatch`.
4. **Refactor Entry Points**: Update high-traffic interaction components (Sidebar, SceneList, HotspotManager) to use `enqueue` instead of `dispatch`.
5. **Verification**: 
   - Stress test by spamming clicks on scene transitions and hotspots.
   - Verify zero "hanging" states or overlapping animations.

## 🚨 CODING STANDARDS
- **Logger Module**: REQUIRED for tracing every enqueue, start-process, and settlement event.
- **Explicit Handling**: Use `Result` for any asynchronous operations.
- **Zero Mutable Leakage**: Keep mutable state strictly encapsulated within the `InteractionQueue` module.
