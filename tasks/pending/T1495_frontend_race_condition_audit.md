# 🔍 AUDIT: Frontend Race Condition & Determinism Hardening (T1495)

## 📌 Context
Despite several surgical fixes, the application still exhibits subtle race conditions (e.g., Intro Pan skipping, simulation/navigation timing overlaps). The objective is to move from "re-active patching" to a "pro-active deterministic architecture."

## 🎯 Objectives
1.  **Audit All Async Flows**: Identify every path where global state changes occur asynchronously (Promise, useEffect, setTimeout).
2.  **Enforce Strict Serialization**: Every async operation must be cancellable and "stale-checked" against the current application state.
3.  **100% Reliability Target**: Eliminate "timing-dependent" bugs where a slow network or heavy CPU load changes behavior.

## 🛠️ Audit Scope (High Priority)

### 1. Simulation & Navigation Synchronization
- **File**: `src/systems/Simulation.res`, `src/systems/Scene/SceneLoader.res`
- **Current Issue**: Simulation ticks often race against the Navigation FSM's `Transitioning` or `Stabilizing` states.
- **Fix Pattern**: The Simulation system must "lock" until the Navigation FSM emits a `StabilizeComplete` AND the Viewer reports `isViewerReady`.
- **Constraint**: No "arbitrary" timeouts. All waits must be event-driven or state-guarded.

### 2. Thumbnail & Background Systems
- **File**: `src/systems/ThumbnailProjectSystem.res`
- **Current Issue**: Background tasks continue during critical UI transitions, starving the main thread.
- **Fix Pattern**: Centralized `BackgroundJobManager` that utilizes `requestIdleCallback` or pauses automatically during any `NavigationFSM != IdleFsm`.

### 3. Rapid Interaction Processing (Debouncing vs. Queuing)
- **Files**: `src/components/UtilityBar.res`, `src/components/Sidebar.res`
- **Pattern Audit**: Detect occurrences of separate `dispatch()` calls in a single handler. 
- **Fix Pattern**: Force `Actions.Batch()` for all multi-step state updates to ensure Reducer atomicity. 

### 4. React `useEffect` Consistency
- **Audit**: Find effects that depend on `activeIndex` or `simulationStatus` but don't check if the "Current Scene ID" matches what they think they are processing (the "Stale Closure" problem).
- **Fix Pattern**: Use `Ref` trackers (like `lastProcessedId`) and immediate return guards if the ID has changed since the effect was triggered.

## ⚖️ Proposed Structural Solutions
- **RunID Pattern**: Increment a global `currentRunId` on every major transition. Async tasks must verify `taskRunId == currentRunId` before dispatching.
- **Wait-For-Idle Guard**: Create a reusable `waitFor(condition, timeout)` utility that simulation and automation systems must use before every step.
- **Z-Index/Interaction Layer Hardening**: Ensure that "Interaction Blockers" (invisible overlays) are strictly tied to FSM `SystemBlocking` states.

## 📝 Success Criteria
- [ ] No race conditions detected even when simulating a 2000ms "Slow 3G" network and high CPU throttling.
- [ ] "Tour Preview" starts and finishes with 100% identical timing/animation sequences across multiple runs.
- [ ] Zero `LONG_TASK_DETECTED` logs during active navigation transitions.

## 🚀 Execution Instructions for Next Session
1. **Instrument**: Run the app with "CPU Throttling: 6x slow" in Chrome.
2. **Stress Test**: Hammer the "Tour Preview" and "Next Scene" buttons simultaneously.
3. **Trace**: Use the established `Logger` to find where FSM transitions overlap or "skip" states.
4. **Refactor**: Apply the "RunID Pattern" to `ThumbnailProjectSystem` and `Simulation`.
