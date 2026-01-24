# Task: Troubleshoot Yellow Rod Top-Left Displacement - REPORT

**Objective**: Resolve the issue where the yellow rod (cursor guide) appeared at the top-left (0,0) of the viewer during link addition and remove the blinking animation from the dot.

**Technical Realization**:
1.  **Fixed Stale Closure**: In `ViewerManager.res`, the `handleMouseMove` listener was capturing the initial `isLinking = false` state. Updated the logic to use `GlobalStateBridge.getState().isLinking` within the listener, ensuring it correctly detects when linking mode is active and updates the rod's position.
2.  **Removed Blinking Animation**: 
    - Removed `Dom.classList(g)->Dom.ClassList.add("cursor-dot-blinking")` from `ViewerManager.res`.
    - Updated `css/components/viewer.css` to remove the `cursor-dot-blink` animation and explicitly set the dot's background to `#ffcc00` instead of `inherit`.
3.  **Result**: The yellow rod now correctly follows the cursor at the tip (offset by `linkingRodHeight`) and appears as a solid yellow line and dot without animation.

**Verification**:
- [x] Rod follows cursor during Linking Mode.
- [x] Rod no longer appears at (0,0) on first move.
- [x] Dot at the bottom of the rod is solid yellow and does not blink.
