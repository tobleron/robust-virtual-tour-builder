# Task 539: Performance Optimization - SVG Element Reuse (REBOOT)

## Previous Status: FAILED
The initial implementation of SVG element pooling caused visual regressions where hotspot lines would "randomly" disappear or flicker during simulations and manual navigation. This was likely due to race conditions between multiple systems (Renderer, Controller, Follower) all trying to manage the same element pool without sufficient synchronization.

## Objective
Re-implement SVG element reuse to improve performance without introducing visual glitches.

## Critical Requirements
1.  **Single Owner**: Ensure that only one system controls the SVG pooling at any given time.
2.  **Robust Synchronization**: Path data and element states must stay perfectly in sync.
3.  **State Safety**: When transitioning between scenes or complex states, the pool must be safely purged.
4.  **Performance**: Maintain the reduction in layout thrashing.

## Implementation Steps (To be reviewed)
1.  Verify current state of the codebase (user has manually reverted most changes).
2.  Audit all `requestAnimationFrame` loops and their interaction with `HotspotLine`.
3.  Design a more "Event-Driven" or "Singleton" approach to the SVG overlay management.
4.  Implement and test incrementally.

## Current Status: Completed

## Implementation Notes
- **SvgManager**: Created a dedicated `SvgManager` module to handle lightweight "Virtual DOM" style reconciliation. It creates elements on demand by ID and updates attributes, avoiding expensive `innerHTML` operations.
- **NavigationRenderer**: Removed the "scorched earth" `innerHTML = ""` clearing in the animation loop. Now uses `SvgManager.hide("sim_arrow")` and `updateSimulationArrow`.
- **HotspotLine**: Refactored to use `SvgManager`. Implemented intelligent garbage collection using `Belt.MutableSet.String` to track drawn lines and hide stale ones (Set subtraction), ensuring synchronization without race conditions.
- **Race Conditions**: Solved by ID-based addressing. `sim_arrow` is unique. Hotspot lines are unique by ID. They don't conflict.
- **Visibility Fix**: Updated `ViewerManager` to allow concurrent updates of HotspotLines during navigation and removed the aggressive SVG clearing on simulation start. This ensures waypoints/lines remain visible during auto-pilot as requested.
