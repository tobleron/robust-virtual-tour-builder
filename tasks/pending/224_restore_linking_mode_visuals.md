# Task 224: Restore v4.2.18 Linking Mode Visual Feedback

## Objective
Re-implement the "perfect" visual feedback during path creation, including the marching ants and custom cursors.

## Context
Linking mode currently lacks the high-contrast feedback of v4.2.18. The "Marching Ants" animation and the "Yellow Rod" floor projection were key to the user's perception of "perfection".

## Requirements
1.  **Custom Cursor:** Restore the yellow crosshair SVG cursor for `.linking-mode` in `css/legacy.css` or `css/components/viewer.css`.
2.  **Marching Ants:** Implement the `@keyframes marching-ants` and `.line-marching-ants` CSS.
3.  **Draft Logic Sync:** Ensure `HotspotLine.res` correctly applies the `line-marching-ants` class to the red camera spline.
4.  **Blinking Cursor Dot:** Re-implement the `.cursor-dot-blinking` animation for the current placement point.

## Verification
*   Entering linking mode should change the cursor to a yellow crosshair.
*   The red draft path should "march" (animate dash offset).
*   The placement dot should pulse between Gold and White.
