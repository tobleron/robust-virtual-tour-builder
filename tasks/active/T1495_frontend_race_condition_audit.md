# 🔍 AUDIT + HARDENING: Frontend Race Conditions & Determinism (T1495)

## 📌 Context
Recent fixes (`T1494`, `T1496`, `T1497`) resolved specific regressions, but they also confirmed deeper systemic issues: asynchronous flows are still coordinated by local patterns instead of a single deterministic contract. This task moves from isolated fixes to architecture-level hardening.

## 🔗 Dependency Alignment
- `T1498` defines the global operation-progress orchestration contract.
- `T1495` should consume that foundation and focus on **race elimination + deterministic ordering** across navigation/simulation/viewer/UI flows.

## 🎯 Objectives
1. **Map all async state edges**: promises, effects, timers, callbacks, EventBus emissions, and backend response handlers.
2. **Enforce deterministic ordering**: no stale async callback may mutate state after ownership changed (scene/run/task mismatch).
3. **Standardize cancellation and staleness checks**: each long async chain must have run identity + cancellation guard.
4. **Guarantee frontend↔backend coherence**: backend-bound flows must preserve operation identity and completion semantics in UI state.

## 🛠️ Priority Workstreams

### 1. Simulation ↔ Navigation FSM Serialization
- **Files**: `src/systems/Simulation.res`, `src/systems/Navigation/NavigationController.res`, `src/systems/Scene/SceneLoader.res`
- **Risk**: simulation advancing while navigation is not stabilized.
- **Required Pattern**:
  - Gate move execution on `NavigationFSM == IdleFsm` + viewer readiness.
  - Validate scene/run identity immediately before dispatch side effects.
  - Remove implicit timing assumptions where feasible.

### 2. Viewer Intro / Scene-Scoped Effects
- **Files**: `src/components/ViewerManager/ViewerManagerIntro.res`, related viewer hooks.
- **Risk**: effects fire against stale scene or stale viewer metadata.
- **Required Pattern**:
  - Scene ID equality guard before camera actions.
  - effect-level stale closure checks via refs/run tokens.

### 3. Background Jobs During Critical Transitions
- **Files**: `src/systems/ThumbnailProjectSystem.res` + operation coordinator from `T1498`.
- **Risk**: ambient work competes with transition-critical workloads.
- **Required Pattern**:
  - Explicit background job arbitration (pause/idle/yield policy).
  - Ambient operations visible in shared operation lifecycle, not hidden side effects.

### 4. Dispatch Atomicity & Ordering
- **Files**: `src/components/UtilityBar.res`, `src/components/Sidebar.res`, other multi-dispatch handlers.
- **Risk**: split dispatches can interleave with unrelated events.
- **Required Pattern**:
  - `Actions.Batch()` for logically atomic multi-step updates.
  - documented ordering invariants for coupled actions (e.g., scene/timeline selection).

### 5. React Effect Consistency Audit
- **Scope**: `useEffect`/`useLayoutEffect` chains keyed by `activeIndex`, `simulation.status`, `navigationState`.
- **Risk**: stale closures dispatch updates for old scene/run.
- **Required Pattern**:
  - explicit `currentId`/`runId` guard in async continuations.
  - immediate return when state ownership changed.

### 6. Frontend ↔ Backend Async Boundary Integrity
- **Files**: `src/systems/Api/AuthenticatedClient.res`, `src/systems/ProjectSystem.res`, `src/systems/UploadProcessor.res`, `src/systems/Exporter.res`.
- **Risk**: UI marks completion while backend-correlated work is still active, or responses are applied to stale frontend context.
- **Required Pattern**:
  - operation id continuity from request start to completion.
  - stale response rejection when run/session context changed.
  - consistent terminal-state signaling to global operation lifecycle (from `T1498`).

## ⚖️ Structural Hardening Patterns
- **Run Context Pattern**: `{runId, sceneId, abortSignal}` ownership for async chains.
- **Wait-For-State Pattern**: reusable event/state-guarded wait primitives.
- **Operation Lifecycle Contract**: unified start/progress/complete/fail/cancel semantics.
- **Event Ordering Invariants**: document and enforce key cross-domain ordering assumptions.

## 📦 Deliverables
- [ ] Async audit matrix covering critical modules and ownership rules.
- [ ] Refactors for top race hotspots with run/stale guards.
- [ ] Integration with `T1498` operation lifecycle for backend-bound and ambient flows.
- [ ] Determinism-focused unit/e2e coverage for previously flaky scenarios.

## ✅ Success Criteria
- [ ] No reproducible race-induced navigation/simulation desync under CPU throttle (6x) + network delay.
- [ ] 100-run stress loop shows deterministic scene/highlight/pan sequencing.
- [ ] No stale async callback mutates state after ownership change (instrumented checks).
- [ ] Backend-bound operations preserve operation identity and do not emit premature completion UI states.
- [ ] No `LONG_TASK_DETECTED` bursts during active navigation caused by uncontrolled ambient jobs.

## 🧪 Verification Matrix
1. **Stress Interaction**: rapid Tour Preview toggles + manual scene navigation spam.
2. **Slow Path**: simulated slow backend responses during load/upload/export.
3. **Ambient Contention**: thumbnail enhancement active during scene transitions.
4. **Cancellation**: mid-operation cancel and restart with no stale completion callbacks.
5. **Replayability**: repeat identical scenario sequences and compare telemetry ordering.

## 🚀 Execution Order
1. Implement `T1498` primitives (global operation lifecycle + correlation).
2. Apply `T1495` serialization/stale-guard refactors using those primitives.
3. Run verification matrix and close with deterministic telemetry evidence.

## 📝 Notes
- No arbitrary sleeps as a primary synchronization method.
- Prefer event/state guards over timeout-based coordination.
- Keep ReScript build warning-free throughout.
