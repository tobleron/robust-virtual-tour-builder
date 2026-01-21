# Task: Refine Linking Mode Visuals and Camera Behavior - REPORT

**Objective**: Remove the dot at the bottom of the yellow rod and restrict camera movement to trigger only when the cursor is near the edge of the viewer.

**Technical Realization**:
1.  **Removed Rod Dot**: Deleted the `::after` pseudo-element for `#cursor-guide` in `css/components/viewer.css`, resulting in a clean vertical line.
2.  **Edge-Triggered Camera Movement**: 
    - Modified `src/components/ViewerFollow.res` to increase the `deadzone` from `0.1` to `0.85`.
    - Implemented a new `getEdgePower` function that calculates movement speed based on how far the cursor has penetrated the edge zone (outer 15% of the viewer).
    - This ensures the camera remains stationary while the cursor is in the central 85% of the screen, providing a more stable "drawing" experience.
3.  **Result**: The linking tool is now a simple yellow line, and the window only pans when the user intentionally pushes against the borders.

**Verification**:
- [x] Yellow rod has no dot at the bottom.
- [x] Camera does not move when the cursor is in the center of the viewer.
- [x] Camera pans smoothly when the cursor reaches the outer edges (85%+) of the viewer.
