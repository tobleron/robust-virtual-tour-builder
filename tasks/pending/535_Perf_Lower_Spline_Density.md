# Task 535: Performance Optimization - Lower Spline Density

## Objective
Reduce CPU overhead during active navigation and camera rotation by decreasing the number of segments calculated for Catmull-Rom splines and floor-projected paths.

## 🛠 Strategic Implementation (Safety First)
- **Reference**: `src/systems/HotspotLine.res` and `src/systems/HotspotLineLogic.res`.
- **Action**: Change the `segments` parameter in `getCachedSplinePath` and `getCachedFloorPath` from 100 to ~40.
- **Action**: Verify `drawSimulationArrow` path calculation also uses lower density.

## 🛡 Stability Considerations
- **Visual Verification**: Check if curves appear "jagged" on high-resolution displays. If so, find a middle ground (e.g., 60 segments).
- **Consistency**: Ensure the lower density is applied consistently across all path-drawing logic to avoid stuttering when switching between different path types.
- **Math Safety**: Verify that loops correctly handle the reduced array sizes and that indexing remains valid.

## ✅ Success Criteria
- [ ] Path segment count reduced in `HotspotLine.res`.
- [ ] Visual smoothness remains acceptable during camera movement.
- [ ] No regression in path calculation accuracy.
- [ ] Build passes (`npm run build`).
