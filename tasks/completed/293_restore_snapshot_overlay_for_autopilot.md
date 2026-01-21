# Task: Restore Snapshot Overlay for AutoPilot

## Objective
Enable snapshot overlay transitions during AutoPilot to provide visual continuity between scenes and prevent "black screen" appearance that makes the app seem stuck.

## Problem
- `ViewerLoader.res:123-138` instantly removes snapshot overlay during simulation
- No visual continuity between scenes during AutoPilot
- User sees black screen during each transition
- May appear "stuck" even when loading is progressing normally

## Acceptance Criteria
- [ ] Modify snapshot overlay logic to allow smooth transitions during AutoPilot
- [ ] Keep fade animation during simulation (remove instant removal)
- [ ] Ensure snapshot is captured before each scene transition
- [ ] Test with 10+ scene AutoPilot to verify smooth visual flow
- [ ] Verify no performance degradation
- [ ] Run `npm run build` to verify compilation

## Technical Notes
**File**: `src/components/ViewerLoader.res`
**Lines**: 123-138

**Current Code**:
```rescript
let isSim = GlobalStateBridge.getState().simulation.status == Running

switch Nullable.toOption(snapshot) {
| Some(s) =>
  if !isSim {
    Dom.remove(s, "snapshot-visible")
    // Smooth fade transition
  } else {
    Dom.remove(s, "snapshot-visible")
    Dom.setBackgroundImage(s, "none")  // ❌ Instant removal
  }
| None => ()
}
```

**Fixed Code**:
```rescript
// Remove simulation check - use smooth transitions for all modes
switch Nullable.toOption(snapshot) {
| Some(s) =>
  Dom.remove(s, "snapshot-visible")
  let _ = Window.setTimeout(() => {
    if !(Dom.classList(s)->Dom.ClassList.contains("snapshot-visible")) {
      Dom.setBackgroundImage(s, "none")
    }
  }, 450)
| None => ()
}
```

## Priority
**MEDIUM** - UX improvement, prevents "stuck" appearance

## Estimated Time
20 minutes

## Related Issues
Part of AutoPilot simulation timeout analysis (AUTOPILOT_SIMULATION_ANALYSIS.md)
