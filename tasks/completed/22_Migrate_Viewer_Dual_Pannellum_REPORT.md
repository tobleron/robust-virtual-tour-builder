# Report: Migrate Viewer Dual-Pannellum Swapping

## Objective (Completed)
Port the core "swap" and "fade" logic that manages the two Pannellum viewers from `Viewer.js` to ReScript.

## Context
This is the heart of the "Robust" transitions. Managing the visibility and z-index of the two stage layers.

## Implementation Details

1. **Create `ViewerStageManager.res`**:
   - Manage two `domElement` references (`stageA`, `stageB`).
   - Implement `performSwap(targetIdx)` logic:
     - Load target into "off-stage" viewer.
     - Wait for 'load' event.
     - Animate opacity fade.
     - Bring "on-stage".

2. **Handle Z-Index and Opacity**:
   - Centralize state of which viewer is "Active".
   - Use `Webapi.Dom` for direct style manipulations.

3. **Coordinate with Navigation**:
   - Ensure `Navigation.res` calls this new ReScript module instead of `Viewer.js` directly.

## Testing Checklist
- [x] Navigation between scenes remains smooth.
- [x] No "black flashes" during high-speed transitions.
- [x] Verify viewer instance cleanup happens on swap to prevent memory leaks.

## Definition of Done
- Swapping and layer management logic is 100% ReScript.
- `Viewer.js` is reduced by another ~400 lines.
