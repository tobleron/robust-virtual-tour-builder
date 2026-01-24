# Task: 267 Update camera movement behavior - REPORT

## Objective
Update the camera movement behavior so that edge panning is only active during linking mode. In normal mode, the camera should only move via click-and-drag (Pannellum's default behavior).

## Fulfillment
- Modified `src/components/ViewerFollow.res` to add a `storeState.isLinking` check to the edge panning logic.
- Verified that edge panning is now skipped when not in linking mode, even if the follow loop is running (e.g., to draw hotspots).
- Verified that Pannellum's default click-and-drag behavior remains active in normal mode.
- All frontend tests passed.

## Technical Details
In `src/components/ViewerFollow.res`, the `updateFollowLoop` function was updated:
```rescript
if storeState.isLinking && (Math.abs(state.mouseXNorm) > deadzone || Math.abs(state.mouseYNorm) > deadzone) {
  // ... edge panning logic
}
```
This ensures that `appliedYawDelta` and `appliedPitchDelta` remain 0.0 unless `isLinking` is true, effectively disabling edge-triggered camera movement in normal mode.
