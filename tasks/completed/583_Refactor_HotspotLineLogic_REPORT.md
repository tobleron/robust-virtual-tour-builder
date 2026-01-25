# Task 583 Report: Refactor HotspotLineLogic (Math vs Rendering)

## Status: Completed

## Core Actions Taken
1.  **Created `src/utils/ProjectionMath.res`**:
    -   Extracted `projState` and `camState` types.
    -   Moved `makeCamState` (previously `getCamState` + `getProjState` logic) to this pure module.
    -   Moved `getScreenCoords` projection logic here.
    -   Ensured strict functional purity (no side effects).

2.  **Created `src/systems/SvgRenderer.res`**:
    -   Extracted all DOM manipulation logic (`updateLine`, `drawPolyLine`, `drawArrow`, `hide`).
    -   Implemented a "dumb" renderer that blindly accepts coordinates and updates attributes.

3.  **Refactored `src/systems/HotspotLineLogic.res`**:
    -   Now acts as a **Coordinator/Facade**.
    -   Delegates Math to `ProjectionMath`.
    -   Delegates Rendering to `SvgRenderer`.
    -   Maintained the "Business Logic" (Spline interpolation, Simulation progress calculation).
    -   Maintained backward compatibility by exporting `getScreenCoords` (proxied to `ProjectionMath`).

## Verification
-   **Build Status**: Passed (`npm run build`).
-   **No Type Errors**: ReScript compilation clean.
-   **Backward Compatibility**: Verified consumers (`HotspotLine.res`, `NavigationRenderer.res`) work without changes or with minor type inference updates.

## Next Steps
-   None. Refactor is complete.
