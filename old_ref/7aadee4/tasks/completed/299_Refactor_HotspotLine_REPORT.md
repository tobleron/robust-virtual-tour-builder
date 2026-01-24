# Task 299: Refactor HotspotLine.res (Oversized) - REPORT

## Objective
The objective was to decompose the oversized `src/systems/HotspotLine.res` file (748 lines) into smaller, more focused modules to improve maintainability and follow project standards (< 400 lines per module).

## Implementation Details
1.  **Module Decomposition**:
    -   **HotspotLineTypes.res**: Extracted shared types and record definitions (`screenCoords`, `customViewerProps`).
    -   **HotspotLineLogic.res**: Extracted core logic including viewer validation (`isViewerReady`), math helpers (`getScreenCoords`), and SVG drawing functions (`drawLine`, `drawPolyLine`, `drawSimulationArrow`).
    -   **HotspotLine.res**: Refactored into a facade that manages the `pathCache` and orchestrates the complex `updateLines` logic while exposing key functions to other modules.
2.  **Size Reduction**:
    -   `HotspotLine.res`: reduced from 748 lines to ~300 lines.
    -   `HotspotLineLogic.res`: ~300 lines.
    -   `HotspotLineTypes.res`: ~10 lines.
3.  **Facade Pattern**: Ensured that all previously exported functions used by other modules (e.g. `isViewerReady`, `getScreenCoords`) are still available via the `HotspotLine` module.

## Results
- **Code Quality**: Improved Separation of Concerns and significantly better readability for the coordinate projection and drawing logic.
- **Stability**: Unit tests for `HotspotLine` pass successfully.
- **Build**: Project build and all unit tests pass without regressions.
