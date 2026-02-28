# 1609 - Fix RAF-Batch SetNavigationStatus Ordering

## Priority: MEDIUM
## Category: State Stability Fix

## Objective
Remove `SetNavigationStatus` from the RAF-batchable action list in `AppContext.Provider` to prevent state ordering issues when FSM events interleave with deferred navigation status updates.

## Problem
`AppContext.res` lines 97-103:
```rescript
let isRafBatchableAction = (action: action): bool =>
  switch action {
  | UpdateLinkDraft(_)
  | SetPreloadingScene(_)
  | SetNavigationStatus(_) => true
  | _ => false
  }
```

`SetNavigationStatus` sets `navigationState.navigation` (Idle/Navigating/Previewing). When batched:
1. A `SetNavigationStatus(Navigating)` is queued in the RAF batch
2. Before the next frame, a `DispatchNavigationFsmEvent(TransitionComplete)` fires (non-batched, runs immediately)
3. The FSM transitions to `Stabilizing` or `Idle`
4. On the next frame, the batched `SetNavigationStatus(Navigating)` fires, overwriting the already-completed navigation back to `Navigating`

This creates a window where the system thinks navigation is still in progress after it has completed.

## Solution
Remove `SetNavigationStatus` from `isRafBatchableAction`. This action is dispatched infrequently enough (once per navigation phase change) that batching provides negligible performance benefit but introduces significant ordering risk.

```rescript
let isRafBatchableAction = (action: action): bool =>
  switch action {
  | UpdateLinkDraft(_)
  | SetPreloadingScene(_) => true
  | _ => false
  }
```

## Files to Modify
- `src/core/AppContext.res` - Remove `SetNavigationStatus` from batchable list

## Verification
- Build passes
- Rapid scene switching test (`rapid-scene-switching.spec.ts`) still passes
- Navigation doesn't "hang" in Navigating status after completion
- Check that `SetNavigationStatus` dispatches are processed synchronously in console logs
