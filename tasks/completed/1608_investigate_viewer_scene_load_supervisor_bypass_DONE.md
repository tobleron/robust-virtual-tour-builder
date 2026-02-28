# 1608 - Investigate ViewerManagerSceneLoad Supervisor Bypass

## Priority: MEDIUM
## Category: State Stability Investigation

## Objective
Determine whether the direct `DispatchNavigationFsmEvent` dispatch in `ViewerManagerSceneLoad.handleMainSceneLoad` (bypassing `NavigationSupervisor`) can create orphaned FSM states, and if so, implement a safe guard.

## Problem
`ViewerManagerSceneLoad.res` lines 55-61:
```rescript
// NOTE: This is a recovery/initialization path, not user-initiated navigation.
// We dispatch FSM event directly to synchronize viewer state with Redux.
// This does NOT go through Supervisor to avoid circular dependencies during init.
dispatch(
  DispatchNavigationFsmEvent(UserClickedScene({targetSceneId: scene.id, previewOnly: false})),
)
```

This creates a scenario where:
1. NavigationFSM transitions to `Preloading` (via the `UserClickedScene` event)
2. NavigationSupervisor remains `Idle` (no task registered)
3. OperationLifecycle has no corresponding operation
4. The FSM is now stuck in `Preloading` with no task to complete it

The comment says "initialization/recovery path", but it fires on every `useMainSceneLoading` effect when `hasSceneChanged` is true, which includes React re-renders where `activeIndex` changes.

## Investigation Steps
1. Add diagnostic logging to capture when this code path fires vs when Supervisor-initiated navigation fires
2. Check if subsequent `TextureLoaded` events can resolve an orphaned `Preloading` state
3. Test scenario: Load project → first scene auto-loads → user clicks scene 2 → does Supervisor conflict with the init-path FSM state?
4. Check if `SceneLoader` or `SceneTransition` call `NavigationSupervisor.complete()` for this path

## Potential Solutions
- **Option A**: Gate the FSM dispatch: only fire if `NavigationSupervisor.isIdle()` is true AND no active task exists
- **Option B**: Instead of dispatching `UserClickedScene`, dispatch a new "InitScene" event that transitions to a special state that doesn't conflict with navigation
- **Option C**: Register a lightweight Supervisor task for this initialization path

## Files to Investigate
- `src/components/ViewerManager/ViewerManagerSceneLoad.res`
- `src/systems/Navigation/NavigationSupervisor.res`
- `src/systems/Scene/SceneLoader.res` (how does init load complete?)
- `src/systems/Scene/SceneTransition.res` (does `finalizeSwap` handle taskId=None?)

## Verification
- Load project, verify first scene displays without console warnings
- Rapidly click scenes after project load, verify no "stuck in Preloading" state
- Check NavigationFSM logs for orphaned transitions
