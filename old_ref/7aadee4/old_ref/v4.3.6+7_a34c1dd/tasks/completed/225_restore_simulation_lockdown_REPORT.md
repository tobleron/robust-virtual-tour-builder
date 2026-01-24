# Task 225: Restore v4.2.18 Simulation Visual Lockdown - REPORT

## Objective
Restore the "Auto-Pilot" immersion by re-implementing the visual lockdown and pulsing stop button, as seen in version 4.2.18.

## Implementation Details
1.  **Grayscale Filter & Opacity:**
    -   Verified `css/layout.css` correctly applies `filter: grayscale(100%); opacity: 0.85; pointer-events: none;` to `#sidebar` when `body.auto-pilot-active` is present.
    -   Ensured `ViewerManager.res` properly toggles the `auto-pilot-active` class on the `document.body`.

2.  **Selective Visibility (ViewerUI):**
    -   Modified `src/components/ViewerUI.res` to apply selective dimming.
    -   **Editing Buttons:** The "Add Link" button now dims to `opacity-40` and has `pointer-events-none` during simulation.
    -   **Information Labels:** Category and Label buttons remain at `opacity-100` but are set to `pointer-events-none` to prevent interaction during "lockdown" while remaining legible.
    -   **HUD Labels:** Persistent labels and quality indicators remain at `opacity-100`.

3.  **Pulsing Stop Button:**
    -   Added `.animate-pulse-stop` class to `css/animations.css` which utilizes the existing `@keyframes pulse-stop`.
    -   Applied `animate-pulse-stop` to the simulation toggle button in `ViewerUI.res` when `simActive` is true.

4.  **Interaction Lockdown:**
    -   Removed global `pointer-events: none` from `#viewer-utility-bar` in `css/components/floor-nav.css` to ensure the "Stop" button remains clickable.
    -   Applied `pointer-events-none` individually to all other utility buttons and the sidebar.

## Verification
-   `npm run build` executed successfully.
-   Visual logic verified in code:
    -   Sidebar dims and goes grayscale.
    -   "Add Link" dims to 0.4.
    -   "Stop" button pulses red.
    -   Information labels (Category, Label) stay bright but non-interactive.
