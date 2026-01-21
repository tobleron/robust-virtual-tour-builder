# Task: Optimize Render Loop During AutoPilot

## Objective
Reduce the frequency of the continuous hotspot line render loop during AutoPilot simulation to minimize performance overhead and improve scene loading speed.

## Problem
- `ViewerManager.res:451-477` runs render loop every frame (~60fps)
- During AutoPilot, this may cause unnecessary performance overhead
- Hotspot lines don't need to update as frequently during automated navigation
- Could slow down scene loading

## Acceptance Criteria
- [ ] Implement frame skipping during AutoPilot (update every 3rd frame instead of every frame)
- [ ] Maintain smooth updates during manual navigation
- [ ] Add performance metrics logging (frame time, update frequency)
- [ ] Test with 20+ scene AutoPilot to measure performance improvement
- [ ] Verify hotspot lines still render correctly during AutoPilot
- [ ] Run `npm run build` to verify compilation

## Technical Notes
**File**: `src/components/ViewerManager.res`
**Lines**: 451-477

**Current Code**:
```rescript
let rec loop = () => {
  let v = ViewerState.getActiveViewer()
  switch Nullable.toOption(v) {
  | Some(viewer) =>
    // Always update lines to ensure they stick to the scene during ANY movement
    let currentState = GlobalStateBridge.getState()
    HotspotLine.updateLines(viewer, currentState, ())
  | None => ()
  }
  animationFrameId := Some(Window.requestAnimationFrame(loop))
}
```

**Optimized Code**:
```rescript
let frameCounter = ref(0)

let rec loop = () => {
  frameCounter := frameCounter.contents + 1
  
  let v = ViewerState.getActiveViewer()
  switch Nullable.toOption(v) {
  | Some(viewer) =>
    let currentState = GlobalStateBridge.getState()
    
    // During AutoPilot, update every 3rd frame (20fps)
    // During manual navigation, update every frame (60fps)
    let shouldUpdate = if currentState.simulation.status == Running {
      mod(frameCounter.contents, 3) == 0
    } else {
      true
    }
    
    if shouldUpdate {
      HotspotLine.updateLines(viewer, currentState, ())
    }
  | None => ()
  }
  animationFrameId := Some(Window.requestAnimationFrame(loop))
}
```

## Priority
**LOW** - Performance optimization, not critical

## Estimated Time
30 minutes

## Related Issues
Part of AutoPilot simulation timeout analysis (AUTOPILOT_SIMULATION_ANALYSIS.md)
