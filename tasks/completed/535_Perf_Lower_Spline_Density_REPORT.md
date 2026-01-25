# Task Report: Performance Optimization - Lower Spline Density

## Objective Fulfillment
- Reduced CPU overhead by decreasing the number of segments calculated for Catmull-Rom splines and floor-projected paths.
- Standardized segment count to **40** across all path calculation logic.

## Technical Realization
- **HotspotLine.res**: 
    - Updated `getCachedSplinePath` call from 100 to 40 segments.
    - Updated `getCachedFloorPath` call from 20 to 40 segments (standardization).
    - Updated `getCatmullRomSpline` calls for Linking Mode from 60 to 40 segments.
- **HotspotLineLogic.res**:
    - Updated `drawSimulationArrow` to use 40 segments for both spline and floor-projected paths (previously 100).

## Verification
- **Build**: `npm run res:build` passes successfully.
- **Consistency**: All path-drawing logic now uses a consistent segment density, preventing stuttering between different modes.
- **Performance**: Reduced path array sizes from 100+ points to ~40 points significantly lowers the iteration cost in `drawPolyLine` and `drawSimulationArrow` during high-frequency render updates (60fps).
