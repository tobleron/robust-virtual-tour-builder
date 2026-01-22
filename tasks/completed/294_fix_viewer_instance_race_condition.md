# Task: Fix Viewer Instance Race Condition in AutoPilot

## Objective
Improve viewer instance detection in SimulationNavigation to eliminate race condition where AutoPilot checks global `Viewer.instance` before it's assigned during the dual viewer A/B swap.

## Problem
- `SimulationNavigation.res:53-68` polls `Viewer.instance` every 100ms
- ViewerLoader creates viewer and assigns to `state.viewerA` or `state.viewerB` first
- Global `Viewer.instance` is only assigned in `performSwap` (ViewerLoader.res:64)
- Timing gap between viewer creation and global visibility can cause false timeouts

## Acceptance Criteria
- [ ] Create helper function to check viewer readiness across all sources (global + state)
- [ ] Check `Viewer.instance`, `ViewerState.state.viewerA`, and `ViewerState.state.viewerB`
- [ ] Match by scene ID to find the correct viewer
- [ ] Reduce polling interval from 100ms to 50ms for faster detection
- [ ] Add comprehensive logging for debugging
- [ ] Test with rapid scene transitions during AutoPilot
- [ ] Run `npm run build` to verify compilation

## Technical Notes
**File**: `src/systems/SimulationNavigation.res`
**Lines**: 53-68

**Current Code**:
```rescript
let v = Nullable.toOption(Viewer.instance)
switch v {
| Some(viewer) =>
  let sceneId = LocalViewerBindings.sceneId(viewer)
  if sceneId == expectedScene.id && LocalViewerBindings.isLoaded(viewer) {
    loop := false
  } else {
    let _ = await Promise.make((resolve, _reject) => {
      let _ = setTimeout(() => resolve(), 100)  // ❌ May miss viewer
    })
  }
| None =>  // ❌ Viewer not yet assigned to global
  let _ = await Promise.make((resolve, _reject) => {
    let _ = setTimeout(() => resolve(), 100)
  })
}
```

**Proposed Fix**:
```rescript
// Helper function to find viewer by scene ID
let findViewerForScene = (sceneId: string): option<Viewer.t> => {
  // Check global instance first
  let globalViewer = Nullable.toOption(Viewer.instance)
  switch globalViewer {
  | Some(v) if LocalViewerBindings.sceneId(v) == sceneId => Some(v)
  | _ =>
    // Check state viewers
    let state = ViewerState.state
    let viewerA = Nullable.toOption(state.viewerA)
    let viewerB = Nullable.toOption(state.viewerB)
    
    switch viewerA {
    | Some(v) if LocalViewerBindings.sceneId(v) == sceneId => Some(v)
    | _ =>
      switch viewerB {
      | Some(v) if LocalViewerBindings.sceneId(v) == sceneId => Some(v)
      | _ => None
      }
    }
  }
}

// Use in wait loop
let v = findViewerForScene(expectedScene.id)
switch v {
| Some(viewer) =>
  if LocalViewerBindings.isLoaded(viewer) {
    loop := false
  } else {
    let _ = await Promise.make((resolve, _reject) => {
      let _ = setTimeout(() => resolve(), 50)  // Faster polling
    })
  }
| None =>
  let _ = await Promise.make((resolve, _reject) => {
    let _ = setTimeout(() => resolve(), 50)
  })
}
```

## Priority
**HIGH** - Directly addresses timeout race condition

## Estimated Time
45 minutes

## Related Issues
Part of AutoPilot simulation timeout analysis (AUTOPILOT_SIMULATION_ANALYSIS.md)
