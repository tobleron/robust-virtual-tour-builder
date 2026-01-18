# Task 225: Restore v4.2.18 Simulation Visual Lockdown

## Objective
Restore the "Auto-Pilot" immersion by re-implementing the visual lockdown and pulsing stop button.

## Context
During simulation, v4.2.18 would dim non-essential UI to focus on the tour experience. This "lockdown" feel made the simulation feel like a distinct, high-quality mode.

## Requirements
1.  **Grayscale Filter:** Apply `filter: grayscale(100%); opacity: 0.85;` to the sidebar when `body.auto-pilot-active` is present.
2.  **Selective Visibility:** Ensure `ViewerUI.res` properly applies the logic where "Editing" buttons dim to `0.4` but "Information" labels stay at `1.0`.
3.  **Pulsing Stop Button:** Restore the red pulsing shadow animation (`@keyframes pulse-stop`) for the simulation toggle.
4.  **UI Interaction Lockdown:** Ensure `pointer-events: none` is applied to appropriate sidebar/utility areas during simulation.

## Verification
*   Starting simulation should turn the sidebar grey and dim it.
*   The "Stop" button should pulse with a red glow.
*   The "Add Link" button should be dimmed and non-interactive during simulation.
