# TASK: Implement System-Wide Robustness & UI-Sync Protocol

**Priority**: 🔴 Critical
**Estimated Effort**: Large (4-6 hours)
**Dependencies**: None
**Related Tasks**: 1201, 1202, 1203, 1204, 1205

---

## 1. Problem Statement

The current `InteractionQueue.res` successfully manages logical action serialization but remains decoupled from the Physical UI (DOM) and the Component Lifecycle (React). This results in:

- **UI Interception**: Modals/Overlays blocking interactions without disabling the underlying UI buttons.
- **State Wipes**: Destructive state replacement during `LoadProject` while navigation is mid-flight.
- **Telemetry Loss**: Aborted fetch requests during rapid component unmounting.

---

## 2. Technical Requirements

### A. Physical UI Synchronization (Pointer-Lock)

**Status**: Not Implemented  
**Files**: `src/App.res`, `src/core/InteractionQueue.res`, `src/core/AppContext.res`

**Implementation**:
1. Create a React context value `isSystemLocked: bool` derived from `InteractionQueue.isProcessing`.
2. In `App.res`, conditionally render a `pointer-events-none` overlay (`<div className="interaction-lock-overlay">`) when locked.
3. The overlay should cover both `#viewer-container` and `Sidebar` components.
4. Add CSS:
   ```css
   .interaction-lock-overlay {
     position: fixed;
     inset: 0;
     z-index: 9999;
     pointer-events: auto;
     cursor: wait;
     background: transparent;
   }
   ```
5. Expose `useIsSystemLocked()` hook from `AppContext.res`.

### B. Modal-Aware Interaction Guard

**Status**: Not Implemented  
**Files**: `src/components/ModalContext.res`, `src/core/AppContext.res`, `src/hooks/useIsInteractionPermitted.res` (new)

**Implementation**:
1. Create `src/hooks/useIsInteractionPermitted.res`:
   ```rescript
   let make = () => {
     let isQueueProcessing = AppContext.useIsSystemLocked()
     let isModalOpen = ModalContext.useIsModalOpen()
     let navigationFsm = AppContext.useNavigationFsm()
     
     let isTransitioning = switch navigationFsm {
     | Idle | Error(_) => false
     | _ => true
     }
     
     !(isQueueProcessing || isModalOpen || isTransitioning)
   }
   ```
2. Apply this hook to all primary Sidebar action buttons:
   - Add Link (`SidebarActions.res`)
   - Save (`SidebarActions.res`)
   - Export (`SidebarActions.res`)
   - Import (`SidebarActions.res`)
3. Buttons should be `disabled={!isPermitted}` with visual feedback.

### C. The "Barrier Action" Protocol (Load/Reset)

**Status**: Not Implemented  
**Files**: `src/core/InteractionQueue.res`, `src/core/Reducer.res`

**Implementation**:
1. Add a new queue item type:
   ```rescript
   type queueItem =
     | Action(action)
     | Thunk(unit => Promise.t<unit>)
     | Barrier(action) // NEW: Priority action that blocks queue
   ```
2. When a `Barrier(LoadProject(_))` enters the queue:
   - Set `isBarrierPending: true` in internal state
   - Reject all new `Action` and `Thunk` items (log warning)
   - Wait for `NavigationFSM` to reach `Idle` or `Error` state
   - Flush `SessionStore` via `SessionStore.clear()`
   - Execute the barrier action
   - Set `isBarrierPending: false`
3. Update `Reducer.res` to dispatch `LoadProject` via `InteractionQueue.enqueueBarrier(Barrier(action))`.

### D. Unified Telemetry (sendBeacon)

**Status**: Not Implemented  
**Files**: `src/utils/LoggerTelemetry.res`, `src/bindings/WebApiBindings.res`

**Implementation**:
1. Add binding in `WebApiBindings.res`:
   ```rescript
   @val external sendBeacon: (string, string) => bool = "navigator.sendBeacon"
   @val external hasSendBeacon: unit => bool = %raw(`function() { return typeof navigator.sendBeacon === 'function' }`)
   ```
2. Update `LoggerTelemetry.flushTelemetry`:
   ```rescript
   let flushTelemetry = () => {
     let entries = getTelemetryBuffer()
     if Array.length(entries) > 0 {
       let payload = JSON.stringify(entries) // Use JsonCombinators encoder
       if hasSendBeacon() {
         let _ = sendBeacon(Constants.backendUrl ++ "/telemetry/batch", payload)
         clearTelemetryBuffer()
         Promise.resolve()
       } else {
         // Fallback to fetch
         Fetch.fetch(...)->(...)
       }
     } else {
       Promise.resolve()
     }
   }
   ```
3. **Critical**: Ensure all JSON serialization uses `rescript-json-combinators` encoders (NOT raw `JSON.stringify` with objects).

---

## 3. JSON Encoding Standard (Mandatory)

All JSON encoding in this task MUST use `rescript-json-combinators`:

```rescript
// ❌ FORBIDDEN
let payload = JSON.stringify({"key": value})

// ✅ REQUIRED
open JsonCombinators.Json.Encode
let encoder = object([
  ("key", string(value))
])
let payload = encoder->JsonCombinators.Json.encode
```

Reference: `src/core/JsonParsers.res` for existing encoder patterns.

---

## 4. Verification Criteria

- [ ] Playwright `robustness.spec.ts` passes 100% across all browsers.
- [ ] No `net::ERR_ABORTED` messages for telemetry in browser logs.
- [ ] Buttons are visually disabled/unclickable while the "Upload Summary" modal is visible.
- [ ] Rapid "Save + Navigate" sequence no longer causes the Sidebar to unmount.
- [ ] `npm run build` completes with zero warnings.
- [ ] All new JSON encoding uses `rescript-json-combinators`.

---

## 5. File Checklist

- [ ] `src/core/InteractionQueue.res` - Barrier action support
- [ ] `src/core/AppContext.res` - `useIsSystemLocked` hook
- [ ] `src/App.res` - Pointer-lock overlay
- [ ] `src/hooks/useIsInteractionPermitted.res` - New file
- [ ] `src/components/Sidebar/SidebarActions.res` - Apply guard hook
- [ ] `src/utils/LoggerTelemetry.res` - sendBeacon implementation
- [ ] `src/bindings/WebApiBindings.res` - sendBeacon binding
- [ ] `index.css` - `.interaction-lock-overlay` styles

---

## 6. References

- `src/core/InteractionQueue.res`
- `src/core/Reducer.res`
- `src/systems/Navigation/NavigationFSM.res`
- `tests/e2e/robustness.spec.ts`
- `.agent/workflows/rescript-standards.md`
