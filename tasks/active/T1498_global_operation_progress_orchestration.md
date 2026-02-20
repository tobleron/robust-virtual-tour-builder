# 🌐 GLOBAL FIX TASK: Unified Operation Progress Orchestration (T1498)

## 📌 Why This Task Exists
Progress reporting is currently fragmented by feature. Upload/load/export use explicit progress callbacks, while ambient or post-load work (for example thumbnail enhancement) can continue after the UI appears "done." This creates misleading completion states and makes race troubleshooting harder.

## 🎯 Primary Outcome
Create a **single operation lifecycle contract** across frontend and backend boundaries so any meaningful operation (>250ms) is visible, traceable, and state-consistent.

## ✅ Architectural Decision
Use `src/systems/OperationLifecycle.res` as the canonical operation registry and extend it to become the app-wide source of truth.

## ❗ Current Gaps To Close
- Progress state is still routed through feature-specific pathways (`EventBus.UpdateProcessing`, Sidebar-local handling).
- Not all async systems publish lifecycle states (start/progress/complete/fail/cancel).
- Operation ID correlation is inconsistent between frontend task state and backend request traces.
- Blocking and ambient work are not consistently separated in user-facing progress semantics.

## 🧱 Target Contract (Required)

### 1. Canonical Operation Model (Frontend)
- Extend lifecycle metadata to include:
  - `operationId`, `operationType`, `status`
  - `phase` (structured string or variant)
  - `progress` (0..100)
  - `message`
  - `startedAt`, `updatedAt`
  - `scope` (`Blocking` | `Ambient`)
  - `cancellable` (bool)
  - `correlationId` (backend/request trace id)
- Standardize lifecycle edges:
  - `start`
  - `progress`
  - `complete`
  - `fail`
  - `cancel`

### 2. Frontend↔Backend Correlation Contract
- Long backend-bound operations must have stable operation identity from request start to terminal UI state.
- `src/systems/Api/AuthenticatedClient.res` must preserve/propagate correlation safely without coupling unrelated request IDs to lifecycle cancellation logic.
- For non-streaming backend operations, define deterministic phase mapping (`Preparing`, `Uploading`, `AwaitingBackend`, `Finalizing`, `Completed`).
- Failure/timeout/cancel paths must always emit terminal lifecycle state, not only logs.

### 3. App-Wide UX Behavior
- Any operation crossing threshold must appear in global progress UI.
- `Blocking` operations must drive lock-sensitive UX semantics.
- `Ambient` operations must remain visible as background progress and never silently disappear while active.
- Concurrent operations must be represented deterministically (primary + secondary list/queue).

## 🧭 Implementation Scope

### Core Frontend
- `src/systems/OperationLifecycle.res`
- `src/core/Types.res`
- `src/core/Actions.res`
- `src/core/ReducerModules.res`
- `src/core/AppFSM.res` (only if lock semantics need explicit updates)

### Integration Frontend
- `src/components/Sidebar/SidebarLogic.res`
- `src/components/Sidebar/UseSidebarProcessing.res`
- `src/components/Sidebar/SidebarProcessing.res`
- `src/systems/ProjectSystem.res`
- `src/systems/UploadProcessor.res`
- `src/systems/Exporter.res`
- `src/systems/ThumbnailProjectSystem.res`
- `src/systems/Navigation/NavigationSupervisor.res`
- `src/systems/Simulation.res`

### API/Boundary
- `src/systems/Api/AuthenticatedClient.res`
- Backend endpoints used by project load/upload/export must preserve traceability for operation correlation (header and/or response metadata).

## 🛠️ Execution Plan (Delegation-Ready)
1. Baseline audit
- Inventory all long-running operations and classify each as `Blocking` or `Ambient`.
- Document current entry/exit points and missing terminal-state edges.

2. Contract extension
- Expand `OperationLifecycle` data model + helper API for scope, phase, cancellable, correlation.
- Add stable selectors/hooks for global and type-scoped busy state.

3. Adapter layer
- Add a small coordinator wrapper (or lifecycle helper module) to enforce uniform start/progress/terminal calls.
- Migrate major operations through this adapter instead of ad hoc direct UI updates.

4. Migrate critical flows
- Project load, upload, export, navigation, simulation, thumbnail enhancement.
- Ensure each flow emits deterministic terminal state under success, error, timeout, and cancel.

5. UX synchronization
- Bind global progress surface to lifecycle state.
- Keep Sidebar progress as presentation layer, not source of truth.

6. Correlation hardening
- Validate operation ID continuity in logs for at least project load/upload/export.
- Ensure stale/cancelled operations cannot emit late success as active operation completion.

7. Tests and guardrails
- Add/update unit tests for lifecycle transitions and cancellation behavior.
- Add integration checks for concurrent ambient+blocking operations.

## ✅ Acceptance Criteria
- [ ] No operation longer than 250ms runs without lifecycle visibility.
- [ ] Project load completion semantics are not misleading when ambient post-load work is still active.
- [ ] Thumbnail enhancement is visible as ambient progress with count/percent and terminal state.
- [ ] Upload/load/export use the same lifecycle primitives (`start/progress/complete/fail/cancel`).
- [ ] Operation correlation is traceable end-to-end in frontend and backend diagnostics.
- [ ] Cancel/fail/timeout paths always produce deterministic terminal lifecycle state.
- [ ] ReScript build remains warning-free.

## 🧪 Verification Matrix
- [ ] Normal project load/upload/export flows.
- [ ] Slow network path (2s+ latency).
- [ ] CPU throttling (6x) during concurrent operations.
- [ ] Backend timeout/transient error path.
- [ ] Mid-operation cancel where supported.
- [ ] Concurrent `Blocking + Ambient` coexistence.
- [ ] Rapid navigation interaction while ambient work runs.

## 📦 Deliverables For Handoff
- [ ] Updated architecture notes inside this task file (checkboxes marked by implementer).
- [ ] Code changes for lifecycle contract + migrated integrations.
- [ ] Test updates and verification evidence summary.
- [ ] Short log evidence showing operation-id continuity on at least one load and one upload flow.

## 🚫 Non-Goals (Scope Guard)
- Full redesign of notification/toast systems.
- New backend streaming protocol for every endpoint.
- Refactoring unrelated viewer rendering logic outside operation lifecycle integration.

## 🔗 Relationship to T1495
`T1498` provides operation lifecycle determinism and visibility primitives. `T1495` consumes those primitives to harden race-prone async ordering and cancellation behavior across navigation/simulation/viewer workflows.

## ⚠️ Risks / Guardrails
- Preserve current Sidebar UX during migration by bridging from lifecycle state.
- Keep progress monotonic and debounce noisy high-frequency updates.
- Avoid operation-id channel mixing (request IDs vs lifecycle IDs).
- Prefer explicit state guards over timer-based assumptions.
