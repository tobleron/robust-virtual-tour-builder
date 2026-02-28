# 1606 - Fix Dual Navigation FSM State Desynchronization

## Priority: CRITICAL
## Category: State Stability Fix

## Objective
Eliminate the duplicate `AppFSM.transition` call that occurs when `DispatchAppFsmEvent` is processed, and consolidate the three competing navigation FSM sync mechanisms into one canonical path.

## Problem
The navigation FSM state is stored simultaneously in:
1. `state.appMode → Interactive(s) → s.navigation` (AppFSM's `interactiveState`)  
2. `state.navigationState.navigationFsm` (NavigationState domain slice)

When `DispatchAppFsmEvent` is dispatched:
- `Reducer.applyRoutedPipeline` routes it to `applyAppFsmThenNavigation` (Reducer.res:101)
- `AppFsm.reduce` (ReducerModules.res:158-186) calls `AppFSM.transition` once, updates `appMode`, syncs to `navigationState`
- THEN `Navigation.reduce` (NavigationProjectReducer.res:77) calls `handleAppFsmEvent` which calls `AppFSM.transition` AGAIN on the already-transitioned state

This double-transition can produce divergent FSM states depending on the idempotency of the transition function.

Three separate sync mechanisms exist:
- `ReducerModules.AppFsm.reduce` (lines 174-179)
- `NavigationProjectReducer.NavSync.syncNavigationFsm` (lines 7-14)
- `NavigationProjectReducer.NavSync.syncNavigationFsmInAppMode` (lines 17-25)

## Solution Approach
1. Choose ONE canonical location for processing `DispatchAppFsmEvent`:
   - **Option A (Recommended)**: Keep it in `NavigationProjectReducer.Navigation.reduce` only. Remove from `ReducerModules.AppFsm` entirely. Change routing in `Reducer.applyRoutedPipeline` from `applyAppFsmThenNavigation` to `applyNavigationOnly` for `DispatchAppFsmEvent`.
   - **Option B**: Keep it in `ReducerModules.AppFsm` only. Remove the `DispatchAppFsmEvent` case from `NavigationProjectReducer.Navigation.reduce`. Keep routing as `applyAppFsmThenNavigation` but remove the AppFsm event handling from Navigation path.
2. Consolidate to TWO sync functions max (one per direction) and ensure they are only called from the canonical handler.
3. Add a Logger assertion that catches if both handlers fire for the same event.

## Files to Modify
- `src/core/Reducer.res` - Update routing for `DispatchAppFsmEvent`
- `src/core/ReducerModules.res` - Potentially remove `AppFsm.reduce`
- `src/core/NavigationProjectReducer.res` - Consolidate sync logic

## Verification
- Run `npm test` to verify unit tests pass
- Run `npm run build` to verify compilation
- Manually test navigation between scenes (rapid clicking, simulation start/stop)
- Verify `AppFSM TRANSITION_MODE` log entries don't show duplicate transitions
