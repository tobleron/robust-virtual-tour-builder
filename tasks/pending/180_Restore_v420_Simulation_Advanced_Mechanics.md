# Task: Restore v4.2.0 Simulation Advanced Mechanics

## Description
Restore the advanced visual and interaction mechanics of the Simulation (Auto-Pilot) system as it functioned in version 4.2.0.

## Key Features (v4.2.0 Points 74-79)
1. **Blinking Simulation Arrow**: Implement the specialized arrow that follows the spline path during transitions.
2. **Alternating Color Logic**: The arrow must blink between Yellow (`#fbbf24`) and Green (`#10b981`) every 200ms.
3. **Look-Ahead Rotation**: Apply rotation to the arrow based on a point `0.5` units ahead on the spline for smooth following.
4. **Non-Linear Speed (Ease-In-Out)**: Implement easing for the simulation progress so transitions aren't strictly linear.
5. **HUD Soft Dimming**: Automatically dim the Sidebar and Floor UI to `0.2` opacity when simulation is active.
6. **Interrupt Logic (ESC)**: Ensure pressing the ESC key immediately terminates the simulation and restores UI visibility.

## Implementation Details
- Target Files: `HotspotLine.res`, `SimulationSystem.res`, `ViewerUI.res`, `style.css`
- Reference Commit: `49f727a`
