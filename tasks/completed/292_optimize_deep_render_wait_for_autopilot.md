# Task: Optimize Deep Render Wait for AutoPilot

## Objective
Reduce or eliminate the 3-frame delay (waitForDeepRender) that only occurs during AutoPilot simulation, which adds ~50ms per scene transition.

## Problem
- `ViewerLoader.res:475-488` adds 3 animation frames delay only during simulation
- This is on top of already slower loading (when progressive is disabled)
- Cumulative delay across many scenes becomes significant
- May not be necessary with progressive loading enabled

## Acceptance Criteria
- [ ] Investigate if `waitForDeepRender` is still necessary with progressive loading enabled
- [ ] If necessary, reduce frame count from 3 to 1
- [ ] If not necessary, remove the conditional and use `checkReadyAndSwap()` directly
- [ ] Test AutoPilot with 20+ scenes to ensure no visual glitches
- [ ] Document decision in code comments
- [ ] Run `npm run build` to verify compilation

## Technical Notes
**File**: `src/components/ViewerLoader.res`
**Lines**: 475-488

**Current Code**:
```rescript
if GlobalStateBridge.getState().simulation.status == Running {
  let frameCount = ref(0)
  let rec waitForDeepRender = () => {
    frameCount := frameCount.contents + 1
    if frameCount.contents < 3 {
      let _ = Window.requestAnimationFrame(waitForDeepRender)
    } else {
      checkReadyAndSwap()
    }
  }
  let _ = Window.requestAnimationFrame(waitForDeepRender)
} else {
  checkReadyAndSwap()
}
```

**Potential Fix** (after testing):
```rescript
// Option 1: Reduce frames
if GlobalStateBridge.getState().simulation.status == Running {
  let _ = Window.requestAnimationFrame(() => checkReadyAndSwap())
} else {
  checkReadyAndSwap()
}

// Option 2: Remove entirely if progressive loading makes it unnecessary
checkReadyAndSwap()
```

## Priority
**MEDIUM** - Performance optimization, not a blocker

## Estimated Time
30 minutes (includes testing)

## Related Issues
- Part of AutoPilot simulation timeout analysis (AUTOPILOT_SIMULATION_ANALYSIS.md)
- Should be done AFTER task #291 (progressive loading)
