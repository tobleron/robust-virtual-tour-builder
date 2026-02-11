# 1328: [NAV-SUP 1/6] Create NavigationSupervisor Module

## Parent Task
[1306_ARCH_Navigation_Supervisor_Pattern](./1306_ARCH_Navigation_Supervisor_Pattern.md)

## Objective
Create a new `NavigationSupervisor.res` module that serves as the **single centralized coordinator** for scene transitions, replacing the distributed `TransitionLock` acquire/release pattern with an intent-based auto-cancel model.

## Why This Matters
The current `TransitionLock.res` is a distributed lock prone to deadlocks when error paths fail to release. The Supervisor pattern eliminates this entire class of bugs by design: there is no lock to "get stuck" — a task either finishes or is replaced.

## Implementation

### [CREATE] `src/systems/Navigation/NavigationSupervisor.res`

**Types:**
```rescript
type taskId = string

type status =
  | Idle
  | Loading(taskId, string)    // (taskId, sceneId)
  | Swapping(taskId, string)
  | Stabilizing(taskId, string)

type task = {
  id: taskId,
  targetSceneId: string,
  abort: unit => unit,          // Calls AbortController.abort()
  startedAt: float,
}
```

**Core State (module-level refs):**
```rescript
let currentTask: ref<option<task>> = ref(None)
let status: ref<status> = ref(Idle)
let listeners: ref<array<status => unit>> = ref([])
```

**Core Functions:**

1. `let requestNavigation = (targetSceneId: string): unit`
   - If a current task exists → call `currentTask.abort()` (auto-cancel previous)
   - Create new `AbortController` via browser binding
   - Generate unique `taskId` (timestamp-based is fine)
   - Set `currentTask` to the new task
   - Update `status` to `Loading(taskId, targetSceneId)`
   - Notify listeners
   - Log via `Logger.info` with `~module_="NavigationSupervisor"`

2. `let transitionTo = (taskId: taskId, newStatus: status): unit`
   - Only process if `taskId` matches the current task's ID (stale-task guard)
   - Update `status`
   - Notify listeners
   - Log transition

3. `let complete = (taskId: taskId): unit`
   - Only process if `taskId` matches current task
   - Set `status` to `Idle`, `currentTask` to `None`
   - Notify listeners

4. `let abort = (taskId: taskId): unit`
   - Only process if `taskId` matches current task
   - Set `status` to `Idle`, `currentTask` to `None`
   - Log as `TASK_ABORTED`
   - Notify listeners

5. `let addStatusListener = (cb: status => unit): (unit => unit)`
   - Standard subscribe/unsubscribe pattern (same as `TransitionLock.addChangeListener`)

6. `let isIdle = (): bool`

7. `let isBusy = (): bool`

8. `let getStatus = (): status`

### [CREATE] `src/systems/Navigation/NavigationSupervisor.resi` (Optional)
Public interface exposing only `requestNavigation`, `transitionTo`, `complete`, `abort`, `isIdle`, `isBusy`, `getStatus`, `addStatusListener`, and the `status` type.

### Logging Standard
- Module name: `"NavigationSupervisor"`
- Key events: `NAVIGATION_REQUESTED`, `PREVIOUS_TASK_CANCELLED`, `STATUS_TRANSITION`, `TASK_COMPLETED`, `TASK_ABORTED`, `STALE_TASK_IGNORED`

## Verification
- [ ] File compiles cleanly (`npm run build` or dev server)
- [ ] No `TransitionLock` imports in the new file
- [ ] Logger used for all state transitions (no `console.log`)
- [ ] Types use explicit `Option`/`Result` (no `unwrap` patterns)

## Does NOT include
- Wiring to `SceneLoader` or `SceneTransition` (Task 1330)
- Removing `TransitionLock` calls (Task 1331)
- Updating consumers like `LockFeedback` (Task 1332)
