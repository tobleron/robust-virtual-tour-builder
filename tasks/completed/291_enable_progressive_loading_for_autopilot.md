# Task: Enable Progressive Loading for AutoPilot

## Objective
Enable progressive image loading (preview → full quality) during AutoPilot simulation to significantly reduce scene load times and improve user experience.

## Problem
- `ViewerLoader.res:299-303` disables progressive loading when `simulation.status == Running`
- This forces AutoPilot to load only full 4K images without preview
- Significantly increases load time for each scene
- No visual feedback during loading

## Acceptance Criteria
- [ ] Remove `currentGlobalState.simulation.status != Running` check from `useProgressive` condition
- [ ] Verify progressive loading works during AutoPilot (preview loads first, then full quality)
- [ ] Test with scenes that have `tinyFile` defined
- [ ] Measure and document load time improvement (should be 50%+ faster)
- [ ] Ensure smooth transitions during AutoPilot
- [ ] Run `npm run build` to verify compilation

## Technical Notes
**File**: `src/components/ViewerLoader.res`
**Lines**: 299-303

**Current Code**:
```rescript
let useProgressive =
  Belt.Option.isSome(targetScene.tinyFile) &&
  currentGlobalState.simulation.status != Running &&  // ❌ Disables during simulation
  !currentGlobalState.isTeasing &&
  !isAnticipatory
```

**Fixed Code**:
```rescript
let useProgressive =
  Belt.Option.isSome(targetScene.tinyFile) &&
  !currentGlobalState.isTeasing &&
  !isAnticipatory
  // Progressive loading now enabled during AutoPilot for faster scene transitions
```

## Priority
**HIGH** - Major performance improvement for AutoPilot

## Estimated Time
15 minutes

## Related Issues
Part of AutoPilot simulation timeout analysis (AUTOPILOT_SIMULATION_ANALYSIS.md)
