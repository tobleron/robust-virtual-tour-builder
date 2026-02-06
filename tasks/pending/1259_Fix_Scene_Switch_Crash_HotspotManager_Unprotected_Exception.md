# 1259 - Fix Scene-Switch Crash: Unprotected Exception in HotspotManager.syncHotspots

## Problem

Switching between image-item scenes on the sidebar triggers the `AppErrorBoundary` crash dialog ("Application Error — An unexpected error occurred during rendering"). The app becomes unusable, requiring a full page reload.

## Root Cause

`HotspotManager.syncHotspots` (`src/components/HotspotManager.res:126–132`) performs **unsafe property access** on the Pannellum viewer config without null-safety:

```rescript
let config = Viewer.getConfig(v)        // Can return null during transitions
let hs = config["hotSpots"]             // Undefined if config is null
let currentIds = Belt.Array.map(hs, h => h["id"])  // Throws if hs is not an array
```

When the user switches scenes, the dual-viewer pool swaps instances. During the swap window (`isSwapping = true`), the old viewer may be destroyed while `syncHotspots` is called from a React effect. `Viewer.getConfig()` returns `null`/`undefined` on a destroyed or mid-init viewer, causing a JS exception that propagates uncaught through React's render cycle into `AppErrorBoundary`, displaying the crash dialog.

### Call chain

1. User clicks scene in sidebar → `SetActiveScene` dispatched
2. `useMainSceneLoading` effect fires (detects `activeIndex` changed)
3. Calls `handleMainSceneLoad()` → `HotspotManager.syncHotspots(viewer, ...)` at line 123
4. `syncHotspots` calls `Viewer.getConfig(v)` on a viewer that is mid-swap/destroyed → **JS exception**
5. Exception in React effect → `AppErrorBoundary.getDerivedStateFromError` → `ErrorFallbackUI` crash dialog

### Why the timing is bad

`SceneTransition.performSwap` sets `isSwapping = true` (line 136), then schedules `finalizeSwap` via `setTimeout(50ms)` which sets `isSwapping = false` (line 26). But the React effects in `ViewerManagerLogic` fire synchronously during the render triggered by the `SetActiveScene` dispatch — they don't check `isSwapping` before calling `syncHotspots`. The animation frame loop at line 250 **does** check `isSwapping`, which is why it doesn't crash.

### Unprotected call sites (crash sources)

1. **`ViewerManagerLogic.res:123–124`** — `useViewerStateSync`: calls `syncHotspots` + `updateLines` without readiness check
2. **`ViewerManagerLogic.res:172–173`** — `useHotspotSync`: calls `syncHotspots` + `updateLines` without readiness check
3. **`ViewerManagerLogic.res:237`** — `ForceHotspotSync` EventBus handler: calls `syncHotspots` without readiness check
4. **`ViewerManagerLifecycle.res:107`** — simulation sync: calls `syncHotspots` without readiness check

### Already-protected call sites (reference patterns)

- `SceneTransition.finalizeSwap` (line 12): gates on `ViewerSystem.isViewerReady(v)` before calling `ForceHotspotSync` + `updateLines`
- `ViewerManagerLogic.res:250–264`: animation loop checks `!isSwapping` before viewer calls, wraps `updateLines` in try/catch
- `NavigationRenderer.res:73,159`: gates on `ViewerSystem.isViewerReady(v)`
- `SimulationNavigation.res:56`: gates on `ViewerSystem.isViewerReady(viewer)`

## Proposed Solution

Three layers, each addressing a different concern:

### Layer 1: Guard `syncHotspots` at the source with `isViewerReady`

The function should refuse to operate on an unready viewer, using the same `ViewerSystem.isViewerReady` gate the rest of the codebase uses. This is the **primary fix** — it makes the function safe to call at any time.

In `src/components/HotspotManager.res`, change `syncHotspots` to:

```rescript
let syncHotspots = (v: Viewer.t, state: state, scene: scene, dispatch: Actions.action => unit) => {
  if !ViewerSystem.isViewerReady(v) {
    Logger.debug(
      ~module_="HotspotManager",
      ~message="SYNC_SKIPPED_VIEWER_NOT_READY",
      (),
    )
    return
  }

  let config = Viewer.getConfig(v)
  let hs = config["hotSpots"]
  // ... rest unchanged
```

**Why `isViewerReady` and not a null check on `getConfig`:**
- `isViewerReady` already validates `isLoaded`, `isActiveViewer`, and `hfov > 1.0` — a comprehensive lifecycle check
- It's the established pattern in `SceneTransition`, `NavigationRenderer`, and `SimulationNavigation`
- A null check on `getConfig` would only catch one failure mode; `isViewerReady` catches them all (destroyed viewer, mid-init viewer, stale inactive viewer)

### Layer 2: Gate call sites on `!isSwapping` (eliminate the race)

The four unprotected call sites should check `ViewerState.state.contents.isSwapping` before calling `syncHotspots`, matching what the animation frame loop already does at line 250.

In `ViewerManagerLogic.res`, lines 123–125:
```rescript
if !state.isLinking && !ViewerState.state.contents.isSwapping {
  HotspotManager.syncHotspots(viewer, state, scene, dispatch)
  HotspotLine.updateLines(viewer, state, ())
  Scene.Switcher.handleAutoForward(dispatch, state, scene)
}
```

Same pattern for lines 172–173, 237, and `ViewerManagerLifecycle.res:107`.

**Why this matters separately from Layer 1:** Even if `syncHotspots` is internally safe, calling `Viewer.getYaw`/`setPitch` (lines 112–120, same effect) on a mid-swap viewer is also unsafe. The `isSwapping` guard protects the entire block, not just `syncHotspots`.

### Layer 3: Structured error logging instead of silent swallow

For the `ForceHotspotSync` EventBus handler (line 237) which runs outside React's render cycle, wrap in try/catch but **log the error** instead of silently discarding it:

```rescript
| (Some(viewer), Some(scene)) =>
  try {
    HotspotManager.syncHotspots(viewer, currentState, scene, dispatch)
  } catch {
  | Exn.Error(e) =>
    Logger.warn(
      ~module_="ViewerManagerLogic",
      ~message="FORCE_SYNC_FAILED",
      ~data=Some({"error": Exn.message(e)}),
      (),
    )
  }
```

This is defense-in-depth for truly unexpected failures (not the normal race condition, which Layers 1+2 eliminate). It prevents the error boundary trigger while keeping observability.

## Files to Modify

| File | Change | Layer |
|------|--------|-------|
| `src/components/HotspotManager.res` | Add `isViewerReady` guard at top of `syncHotspots` | 1 |
| `src/components/ViewerManagerLogic.res` (lines 110, 155, 237) | Add `!isSwapping` guard to effect blocks; structured catch in EventBus handler | 2, 3 |
| `src/components/ViewerManager/ViewerManagerLifecycle.res` (line 107) | Add `!isSwapping` guard | 2 |

## What This Does NOT Do

- No new modules or abstractions
- No FSM changes — the NavigationFSM and AppFSM are not involved in this bug
- No silent exception swallowing as the primary fix — the race condition is eliminated, not masked
- No changes to the `ErrorBoundary` or `ErrorFallbackUI` — those are working correctly; they should fire on real crashes

## Verification

1. `npm run res:build` — zero warnings
2. `npm run build` — clean production build
3. `npm run test:frontend` — existing tests pass
4. Manual: rapidly click between scenes in sidebar — no crash dialog
