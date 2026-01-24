# Task: 285 - Auto Pilot UI Fixes - REPORT

## Objective
Minor UI fixes for the Auto Pilot (Simulation) button and utility bar to match the project's red-centric design and improve state feedback.

## Fulfillment
The task was fulfilled by updating the CSS and ReScript component logic.

### Technical Steps:
1.  **Auto Pilot Button Styling**:
    - Modified `css/components/viewer.css` to change `.v-util-btn-autopilot.state-idle` background color from green to red (`var(--danger)`).
    - Added `.animate-pulse-stop` class to `css/animations.css` for a consistent pulsing effect when active.
    - Verified icon transform to `stop` (square) in `src/components/ViewerUI.res`.
2.  **Utility Bar Behavior during Auto-Pilot**:
    - Updated `.v-util-btn.state-disabled` in `css/components/viewer.css` to use **100% grayscale** and **0.6 opacity**, matching the floor navigation's visual style.
    - Fixed a bug where the "Add Link" button would become transparent during Auto-Pilot. This was caused by the `className` logic in `src/components/ViewerUI.res` replacing the primary state class with `state-disabled`. It now correctly appends `state-disabled` while retaining the underlying background state (e.g., `state-idle`), allowing the grayscale filter to work correctly on the intended color.
3.  **Build Verification**:
    - Build passed successfully with `rsbuild`.
