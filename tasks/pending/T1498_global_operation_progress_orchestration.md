# 🌐 GLOBAL FIX TASK: Unified Operation Progress Orchestration (T1498)

## 📌 Context
Current progress reporting is fragmented and operation-specific. Upload/Project Load/Export emit progress through Sidebar pathways, but other long-running or post-load operations (e.g., thumbnail enhancement) are not represented in the same lifecycle, causing users to see "Done" while work is still running.

## 🎯 Goal
Implement a **single global operation-progress architecture** so any meaningful task (>250ms) is visible, cancellable when applicable, and state-consistent across frontend and backend boundaries.

## ❗ Problem Statement
- Progress UI is currently driven primarily by `EventBus.UpdateProcessing` emission from Sidebar logic.
- Background/ambient tasks can continue after a "complete" message with no visible progress context.
- Backend-coupled flows have progress callbacks, but there is no mandatory operation contract that all frontend subsystems follow.

## 🧱 Architecture Target
Create a unified operation model and registry that all systems use:

### 1. Global Operation Contract (Frontend)
- Introduce a shared operation state model (OperationId, Type, Status, Phase, Progress, Message, StartedAt, Blocking/Ambient, Cancellable).
- Add standardized actions/events for `OperationStart`, `OperationProgress`, `OperationComplete`, `OperationFail`, `OperationCancel`.
- Replace ad hoc direct progress signaling with this contract (internally can still bridge to existing sidebar progress UI).

### 2. Backend Communication Contract (Mandatory)
- Ensure every backend-backed long operation carries a stable `operationId` from request start to completion.
- Use existing `X-Operation-ID` plumbing as canonical trace ID when available.
- For operations without true backend streaming progress, define deterministic frontend phase mapping and explicit "awaiting backend"/"post-processing" states.
- Validate failure and timeout paths propagate operation state changes to UI (not just logs).

### 3. UI/UX Behavior (App-Wide)
- Global progress surface should appear for any operation expected to exceed threshold.
- Distinguish:
  - `Blocking` operations: lock-sensitive flows (project load/export critical phases).
  - `Ambient` operations: non-blocking flows (thumbnail enhancement) shown as background progress.
- Support concurrent operations with one primary display + queued/secondary indicators.

## 🧭 Implementation Scope
### Frontend Modules
- `src/core/Actions.res`
- `src/core/Types.res`
- `src/core/ReducerModules.res`
- `src/core/AppFSM.res` (if operation mode transitions are needed)
- `src/systems/EventBus.res`
- `src/components/Sidebar/SidebarLogic.res`
- `src/components/Sidebar/UseSidebarProcessing.res`
- `src/components/Sidebar/SidebarProcessing.res`
- `src/systems/ThumbnailProjectSystem.res`
- `src/systems/ProjectSystem.res`
- `src/systems/UploadProcessor.res`
- `src/systems/Exporter.res`

### Backend/Boundary Verification
- `src/systems/Api/AuthenticatedClient.res` (operation-id propagation)
- Relevant backend endpoints already used by upload/project/export flows must preserve request/operation correlation.
- Confirm telemetry/log pipeline receives coherent operation lifecycle for diagnostics.

## 🛠️ Execution Plan
1. Define canonical operation types and reducer handling.
2. Build a central operation coordinator/adapter (single entrypoint for lifecycle updates).
3. Refactor existing flows (Upload, Load, Export, Save, Teaser if applicable) to use coordinator.
4. Integrate `ThumbnailProjectSystem` as explicit ambient operation with count-based progress (`enhanced/total`).
5. Ensure `ProjectLoadComplete` UI semantics reflect completion of required phases; if thumbnail enhancement is post-load, explicitly surface it as a continuing background operation.
6. Add cancellation wiring where supported and explicit non-cancellable state where not.
7. Add deterministic log markers for each lifecycle edge.

## ✅ Acceptance Criteria
- [ ] No long-running operation (>250ms) runs without visible operation state.
- [ ] Project load cannot show misleading terminal state while required post-load work is still active.
- [ ] Thumbnail enhancement progress is visible and understandable (phase + count/percent).
- [ ] Upload/export/load progress uses unified operation lifecycle primitives.
- [ ] Frontend-backend operation correlation is traceable by operation id in logs.
- [ ] Failures/cancellations produce consistent UI and reducer state transitions.

## 🧪 Verification Matrix
- [ ] Normal load/upload/export flows.
- [ ] Slow network (e.g., 2s+ response delays).
- [ ] CPU-throttled environment (6x).
- [ ] Backend timeout / transient failure.
- [ ] Mid-operation cancel where supported.
- [ ] Concurrent ambient + blocking operation coexistence.

## ⚠️ Risks / Guards
- Avoid regressions in existing sidebar progress semantics during migration.
- Preserve zero-warning ReScript builds.
- Keep progress updates monotonic and debounce noisy high-frequency updates.

## 🔗 Relationship to T1495
T1495 remains valid and complementary. This task addresses **global progress determinism and operation observability**, while T1495 targets broader frontend race-condition hardening. T1498 should be executed in a way that provides reusable primitives useful for T1495 refactors.
