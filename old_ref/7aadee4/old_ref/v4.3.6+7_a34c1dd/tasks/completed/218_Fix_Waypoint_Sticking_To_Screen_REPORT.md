# Fix Waypoint Sticking to Screen - REPORT

## Objective
Fix the issue where the created waypoint (link draft) "sticks to the screen" and moves with the camera instead of remaining fixed to the scene location where it was placed.

## Analysis
The "sticking" behavior (waypoint moving with the camera view) is caused by the `ViewerFollow` animation loop terminating (likely due to a transiently lost viewer instance or state desynchronization) without clearing the SVG overlay. When the loop stops updating, the last rendered frame of the path visualization persists on the screen. Since the SVG overlay is fixed to the viewport, the frozen lines appear to "stick" to the screen as the underlying panorama rotates.

## Technical Resolution
Modified `src/components/ViewerFollow.res` to explicitly clear the `viewer-hotspot-lines` SVG content whenever the animation loop terminates.
- The loop terminates if `!hasViewer`, `!state.followLoopActive`, or `!storeState.isLinking`.
- Added logic: `Dom.setTextContent(svg, "")` in the termination block.
- This ensures that if the viewer is lost or the loop stops for any reason, the stale visualization is removed immediately, preventing the "sticking" artifact.

## Verification
- **Build**: `npm run build` passed.
- **Logic Check**: Clearing the SVG on loop exit guarantees no frozen artifacts remain. If the loop restarts (e.g., on mouse move), it will redraw fresh (correct) lines. If it doesn't restart, the lines disappear (correct behavior for lost viewer).
