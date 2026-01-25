# Task 536: Performance Optimization - Adjust Pannellum Friction

## Objective
Improve the "perceived smoothness" of camera movement by increasing the Pannellum friction constant. This masks micro-stuttering and provides a more premium, cinematographic feel.

## 🛠 Strategic Implementation (Safety First)
- **Reference**: `src/components/ViewerLoader.res`.
- **Action**: Update the `friction` value in the `viewerConfig` JS object.
- **Current Value**: `0.05`.
- **Target Value**: Test between `0.1` and `0.2`.

## 🛡 Stability Considerations
- **Responsiveness Check**: Ensure that the camera doesn't feel "stuck" or too heavy when trying to start a movement.
- **Input Testing**: Test with a high-DPI mouse, trackpad, and touch (if possible) to ensure deceleration feels natural on all.
- **Simulation Sync**: Verify that the Autopilot/Simulation system isn't negatively impacted by the slower deceleration.

## ✅ Success Criteria
- [ ] Friction increased in `ViewerLoader.res`.
- [ ] Manual navigation feels smoother and more controlled.
- [ ] No negative impact on Autopilot arrival precision.
- [ ] Build passes (`npm run build`).
