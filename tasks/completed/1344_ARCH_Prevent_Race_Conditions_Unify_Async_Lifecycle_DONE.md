# [1344] Architecture Hardening — Prevent Race Conditions via Unified Async Lifecycle

## Priority: P1 (High)

## Context
Race-prone behavior remains in the navigation/simulation stack after migration to `NavigationSupervisor`.

Key findings from project-wide scan:
1. Mixed concurrency gates are still active:
   - `src/components/ViewerManager/ViewerManagerLifecycle.res:111` gates simulation hotspot sync with `TransitionLock.isSwapping()`, while navigation orchestration now uses `NavigationSupervisor`.
2. Scene transition completion uses split timers not tied to one cancellable lifecycle:
   - `src/systems/Scene/SceneTransition.res:114` (resource cleanup timer)
   - `src/systems/Scene/SceneTransition.res:125` (separate `NavigationSupervisor.complete` timer)
3. Scene loading has long-lived async callbacks that can outlive the initiating intent:
   - `src/systems/Scene/SceneLoader.res:232` safety timeout
   - `src/systems/Scene/SceneLoader.res:284` / `:289` / `:294` event callbacks
4. Simulation advancement loop depends on mutable refs and delayed state reads:
   - `src/systems/Simulation.res:70` (`advancingForIndex` guard)
   - `src/systems/Simulation.res:98` delayed async tick
5. Global mutable bridge access remains heavily used in async paths:
   - `src/core/GlobalStateBridge.res:15` (`stateRef`)
   - `src/core/GlobalStateBridge.res:43` (`getState`)

These patterns can produce stale callback execution, duplicated completion signals, and hidden ordering bugs under rapid navigation/simulation toggles.

## Objective
Establish a single architecture for async lifecycle ownership and stale-work rejection across Navigation, SceneLoader/SceneTransition, and Simulation.

## Implementation Plan

### 1) Introduce explicit lifecycle tokens (epoch/runId) for async flows
- Add a lightweight token model (e.g., `navigationRunId`, `simulationRunId`) to guard delayed callbacks and event handlers.
- Enforce token check before dispatching completion/error events from delayed work.

Likely files:
- `src/systems/Navigation/NavigationSupervisor.res`
- `src/systems/Scene/SceneLoader.res`
- `src/systems/Scene/SceneTransition.res`
- `src/systems/Simulation.res`

### 2) Remove remaining `TransitionLock` dependency from runtime navigation flow
- Replace `TransitionLock.isSwapping()` checks with Supervisor-aware or token-aware checks.
- Keep `TransitionLock` isolated for non-navigation usage only, or fully deprecate if no longer required.

Likely files:
- `src/components/ViewerManager/ViewerManagerLifecycle.res`
- `src/core/TransitionLock.res` (deprecation/cleanup decision)

### 3) Make scene transition completion idempotent and single-owner
- Replace split `setTimeout` completion logic with one lifecycle-owned completion path.
- Ensure cleanup/complete cannot run for stale `taskId`.

Likely files:
- `src/systems/Scene/SceneTransition.res`
- `src/systems/Navigation/NavigationSupervisor.res`

### 4) Harden Simulation tick progression against stale async waits
- Add runId/epoch check around delayed tick and `waitForViewerScene` continuation.
- Ensure simulation can re-arm correctly when navigation FSM transitions from busy to idle after arrival.

Likely files:
- `src/systems/Simulation.res`
- `src/systems/Simulation/SimulationNavigation.res`

### 5) Add targeted regression tests for race paths
- Rapid scene switching while simulation running.
- Abort + immediate re-request during scene load.
- Stale timer callback should not complete current task.

Likely tests:
- `tests/unit/NavigationReducer_v.test.res`
- `tests/unit/SceneSwitcher_v.test.res`
- `tests/unit/SimulationLogic_v.test.res`
- New supervisor/transition lifecycle tests if needed.

## Verification
1. `npm run res:build` passes with zero warnings.
2. Focused frontend tests pass for navigation/simulation reducers and lifecycle.
3. No stale `NavigationCompleted`/completion dispatches observed during rapid switching.
4. No remaining navigation-path dependency on `TransitionLock`.

## Expected Outcome
- Navigation and simulation flows become epoch-safe and idempotent.
- Stale async callbacks are rejected deterministically.
- Reduced probability of “stuck simulation”, double-completion, and ghost transition states.
