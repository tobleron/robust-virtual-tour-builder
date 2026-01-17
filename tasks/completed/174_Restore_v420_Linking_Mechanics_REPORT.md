# Task Report: Restore v4.2.0 Linking Mechanics

## Objective
Restore the sophisticated linking mechanics and visual aids from version 4.2.0, including the "Rod" (Yellow Line) and "Director Curve" (Red Spline).

## Technical Implementation

### 1. Visual Aesthetics & Cursor
- Updated `style.css` to include a custom SVG crosshair cursor for `.linking-mode`.
- Applied `.linking-mode` class to the document body in `ViewerManager.res` when linking is active.
- Refined dash patterns:
    - **Director Curve (Red)**: Uses `4,4` dash array via `.line-marching-ants`.
    - **The Rod (Yellow)**: Uses `3,3` dash array via `.line-rod-yellow`.

### 2. Sophisticated Line Drawing (`HotspotLine.res`)
- Refactored `updateLines` to separate the **Director Curve** (Camera Start to current camera orientation) and **The Rod** (Last Floor Joint to mouse cursor).
- Implemented **Catmull-Rom Spline** logic for both confirmed Red and Yellow paths to ensure smooth curves in equirectangular space.
- Added **Floor Projection** logic:
    - If camera pitch is below -20 degrees, the pending yellow segment is projected onto the floor plane.
    - Added `PathInterpolation.getFloorProjectedPath` to handle the linear interpolation in 3D floor coordinates (X, Z) and unproject back to (Yaw, Pitch).

### 3. Performance & Support
- Added support for multiple joints (intermediate points) in the linking draft.
- Maintained the optimization to skip rendering segments with less than 1px screen distance.
- Integrated the new logic into the `ViewerFollow` loop for real-time updates during viewer rotation.

## Realization
The linking mode now feels significantly more professional and provides better spatial feedback. The yellow rod follows the ground plane when looking down, and the red director curve clearly shows the path the camera will take.
