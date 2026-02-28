# 1607 - Fix Ui.reduce Direct AppFSM.transition Calls

## Priority: HIGH
## Category: State Stability Fix
## Depends On: 1606

## Objective
Eliminate the direct `AppFSM.transition()` calls inside `ReducerModules.Ui.reduce` that bypass the consolidated navigation FSM sync path, causing `appMode` to change without corresponding `navigationState` updates.

## Problem
`Ui.reduce` (ReducerModules.res:119-155) directly calls `AppFSM.transition()` for:
- `StartLinking` → `AppFSM.transition(state.appMode, StartAuthoring)` (line 128)
- `StopLinking` → `AppFSM.transition(state.appMode, StopAuthoring)` (line 142)
- `SetIsTeasing` → `AppFSM.transition(state.appMode, StartTeasing/StopTeasing)` (line 149)

The routing in `Reducer.applyRoutedPipeline`:
- `StartLinking` → `applyUiThenSimulation` (Ui + Simulation, but NOT AppFsm or Navigation)
- `StopLinking` → `applyUiOnly` (Ui only)
- `SetIsTeasing` → `applyUiOnly` (Ui only)

Since AppFsm.reduce and Navigation.reduce are skipped for these actions, the `navigationState.navigationFsm` is never synced with the modified `appMode`. If `appMode` transitions from `Interactive(Viewing)` to `Interactive(EditingHotspots)`, the navigation FSM in `appMode.Interactive.navigation` may change shape but `navigationState.navigationFsm` keeps the old value.

## Solution Approach
**Option A (Recommended — after 1606 is resolved):**
Remove the direct `AppFSM.transition` calls from `Ui.reduce`. Instead, have these actions dispatch a follow-up `DispatchAppFsmEvent` from the component layer before/after the direct action. This keeps the FSM transition path unified.

**Option B (Minimal change):**
Add NavSync calls to `Ui.reduce` in the `StartLinking`, `StopLinking`, and `SetIsTeasing` branches:
```rescript
| StartLinking(draft) =>
  let nextMode = AppFSM.transition(state.appMode, StartAuthoring)
  let nextState = {...state, isLinking: true, linkDraft: draft, appMode: nextMode}
  Some(NavSync.syncNavigationFsm(nextState))
```

**Option C:**
Change routing so these actions go through `applyFullPipeline` instead of specialized paths. This is the safest but may have performance implications.

## Files to Modify
- `src/core/ReducerModules.res` - Modify `Ui.reduce`
- `src/core/Reducer.res` - Potentially change routing for `StartLinking`, `StopLinking`, `SetIsTeasing`

## Verification
- Build passes (`npm run build`)
- Test linking mode toggle (enter link mode, exit, check viewer state)
- Test teaser mode toggle
- Verify navigation still works after entering/exiting link mode
- Run E2E: `robustness.spec.ts` "Mode Exclusivity" test
