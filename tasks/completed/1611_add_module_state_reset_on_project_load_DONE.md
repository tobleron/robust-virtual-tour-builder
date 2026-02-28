# 1611 - Add Module-Level State Reset on Project Load

## Priority: HIGH
## Category: State Stability Fix

## Objective
Ensure that all module-level (non-React) state refs are properly reset when a new project is loaded, preventing stale state from the previous project causing conflicts in the new one.

## Problem
When `LoadProject` is dispatched:
- React state is properly reset via `NavigationProjectReducer.Project.handleLoadProject`
- `navigationState` is reset to `NavigationState.initial()`
- `simulation` is reset to `State.initialState.simulation`

But module-level refs in these systems are NOT reset:

### NavigationSupervisor (Critical)
- `currentTask` ref may still hold an active task from the previous project
- `status` ref may still be `Loading`/`Swapping`/`Stabilizing`
- `taskCounter` and `runId` carry over
- A subsequent navigation in the new project may be rejected as "stale" because `isCurrentTaskId` returns false

### OperationLifecycle (Important)
- `operations` map keeps references to old project operations
- Active operations from the previous project are never completed/cancelled
- Listener callbacks may reference unmounted components from the old project

### ViewerState (Important)
- `resetState()` only clears `lastSceneId` and `loadSafetyTimeout`
- `lastHotspotCount`, `lastIsLinking`, `lastFloor`, `lastAppliedYaw/Pitch`, `linkingStartPoint`, mouse velocity state all carry over
- This can cause incorrect scene-change detection on new project load

## Solution
1. Add `NavigationSupervisor.reset()` function:
```rescript
let reset = () => {
  switch currentTask.contents {
  | Some(task) => 
    task.abort()
    task.opId->Option.forEach(id => OperationLifecycle.cancel(id))
  | None => ()  
  }
  currentTask := None
  status := Idle
  taskCounter := 0
  runId := 0
  notifyListeners()
}
```

2. Call `OperationLifecycle.reset()` (already exists, line 110-128)

3. Expand `ViewerState.resetState()` to clear ALL fields

4. Wire these resets into the project load flow. Best location: `NavigationProjectReducer.Project.reduce` for the `LoadProject` action, add an `EventBus.dispatch(ProjectReset)` or call reset functions directly via side-effect (or add a `useEffect` in AppContext that watches for project load).

## Files to Modify
- `src/systems/Navigation/NavigationSupervisor.res` — Add `reset()` function
- `src/core/ViewerState.res` — Expand `resetState()` to full reset
- `src/core/NavigationProjectReducer.res` or `src/core/AppContext.res` — Wire reset calls on project load
- Potentially `src/systems/EventBus.res` — Add `ProjectReset` event if using event-based approach

## Verification
- Load project A with 10 scenes, navigate to scene 5
- Load project B with 3 scenes → verify no "stale task" warnings
- Navigate in project B → verify normal navigation works immediately
- Run E2E: `desktop-import.spec.ts`, `chunked-import.spec.ts`
- Check that NavigationSupervisor logs show clean `Idle` state after project load
