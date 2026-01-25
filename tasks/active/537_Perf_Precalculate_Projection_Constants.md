# Task 537: Performance Optimization - Precalculate Projection Constants

## Objective
Enhance rendering efficiency by pre-calculating camera projection constants (`halfTanHfov`, `aspectRatio`, etc.) once per frame instead of for every individual point in the path loops.

## 🛠 Strategic Implementation (Safety First)
- **Reference**: `src/systems/HotspotLineLogic.res`.
- **Action**: Refactor `getCamState` or create a memoized version that doesn't re-run trig functions for every point projection.
- **Action**: Update `getScreenCoords` to accept these pre-calculated values.

## 🛡 Stability Considerations
- **Zoom Accuracy**: Ensure that the projection constants update IMMEDIATELY when HFov changes (during zoom). Failure to do this will cause the lines to "detach" from their real positions during zooming.
- **Resize Accuracy**: Ensure that the constants update when the browser window or container is resized.
- **Float Precision**: Use appropriate precision to avoid rounding errors during coordinate conversion.

## ✅ Success Criteria
- [x] Trig functions (Math.tan(cam_hfov)) moved out of the inner loop to camState.
- [x] Projection remains accurate (using inverse constants to avoid divisions).
- [x] No regression in arrow/line placement.
- [x] Build passes (verified via auto-compiler).

