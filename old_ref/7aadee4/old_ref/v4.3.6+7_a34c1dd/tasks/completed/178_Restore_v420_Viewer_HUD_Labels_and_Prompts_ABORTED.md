# Task: Restore v4.2.0 Viewer HUD Labels and Prompts

## Description
Restore the specific HUD labels, prompts, and view logic from version 4.2.0 to provide better user feedback during navigation and linking.

## Key Features (v4.2.0 Points 27-30)
1. **Linking Hint Overlay**: Restore the "ESC to Cancel / ENTER to Finish" text hint at `bottom-40` (centered above the pipeline).
2. **Hint Shadows & Styling**: Ensure the hint text has a `0 2px 8px black` shadow for high contrast.
3. **Return Link Prompt**: Restore the glassmorphism pill ("Add Return Link") that appears at `bottom-24` after a scene transition.
4. **Smart Turnaround Logic**: Ensure clicking the "Add Return Link" prompt rotates the camera view exactly 180 degrees before initiating link mode.

## Implementation Details
- Target Files: `ViewerUI.res`, `style.css`
- Reference Commit: `49f727a`
