# Task: Implement Unified ESC Abort Protocol via ActivitySupervisor

## Objective
Establish an enterprise-grade architectural solution for graceful interruption of all long-running asynchronous activities using a centralized `ActivitySupervisor` and the `AbortSignal` pattern. This moves away from hardcoded checks in the input layer towards a robust, registry-based supervisor.

## Implementation Steps

### Phase 1: Core Infrastructure (The Registry)
- [ ] **Create `src/systems/ActivitySupervisor.res`**:
    - Define `activityType = Navigation | Upload | Export | Save | Load | Simulation | Teaser | Linking`.
    - Implement a `registry` (ref) to track active `abort` callbacks.
    - Implement `register(activityType, abortFn) -> taskId`.
    - Implement `unregister(taskId)`.
    - Implement `interrupt() -> bool` (returns true if something was aborted).

### Phase 2: Input & FSM Alignment
- [ ] **Refactor `InputSystem.res`**: Update `handleKeyDown` for "Escape" to call `ActivitySupervisor.interrupt()`.
- [ ] **FSM Integration**: Ensure `AppFSM` is notified of cancellations to transition from `SystemBlocking` back to `Interactive` state.

### Phase 3: System-Wide Adoption (AbortSignal Plumbing)
- [ ] **Navigation**: Update `NavigationSupervisor.res` to register its existing `AbortController` with the new central supervisor.
- [ ] **Upload Pipeline (High Complexity)**:
    - [ ] Refactor `UploadProcessor.res` and `UploadProcessorLogic.res` to accept an `AbortSignal`.
    - [ ] Propagate signal to `Scanner`, `Resizer`, and `Api.MediaApi` calls.
    - [ ] Wrap the `SidebarLogic.performUpload` loop in a registration lifecycle.
- [ ] **Persistence & Export**:
    - [ ] Ensure `ProjectManager.saveProject` and `loadProject` correctly register/unregister.
    - [ ] Refactor `Exporter.res` to ensure the internal `XHR` abort is wired through the supervisor.
- [ ] **Cinematics**: Wire `TeaserLogic` and `Simulation` (AutoPilot) into the registry.

### Phase 4: UI Synchronization
- [ ] **Notification Refinement**: Standardize the "Operation Cancelled" notification message across all domains.
- [ ] **Progress Visibility**: Ensure `SidebarProcessing.res` and `ProgressBar.res` both subscribe to the supervisor's idle state to auto-hide on interruption.

## Technical Notes
- **Structural Concurrency**: Use `AbortController` as the standard mechanism. Avoid manual state flags for "isInterrupted".
- **Priority Logic**: `ActivitySupervisor.interrupt` should kill the most "active" or "blocking" task first if multiple are registered.
- **Observability**: Every `interrupt()` call must be logged via `Logger.info` with the `taskId` and `activityType` to ensure backend telemetry captures user friction/abandonment.
- **Reference Files**:
  - `src/systems/ActivitySupervisor.res` (New orchestrator)
  - `src/systems/InputSystem.res` (The listener)
  - `src/systems/Navigation/NavigationSupervisor.res` (Existing pattern to emulate)
  - `src/systems/UploadProcessor.res` (Primary target for hardening)
