# Task 286: Refine Hotspot Chevron Click Range - REPORT

## Objective
Limit the click range of hotspot link chevrons (navigation and auto-forward) to only their visible SVG shapes. This prevents accidental scene switches when attempting to toggle auto-forward.

## Technical Fulfillment
1. **DOM Refactoring**:
    - Moved the navigation gold arrow from a pseudo-element (`::before`) on the hotspot container to a dedicated DOM element `.hotspot-nav-btn` inside the control container.
    - This allows for independent hit-testing and event handling.
2. **Precise Event Handling**:
    - Set `pointer-events: none` on the root hotspot `div` and the `.hotspot-controls` container.
    - Set `pointer-events: auto` only on the active elements: `.hotspot-nav-btn`, `.hotspot-forward-btn`, and `.hotspot-delete-btn`.
    - This ensures that clicking in the gaps (including the overlap area between the chevrons) does not trigger any action.
3. **SVG Shape Hit-Testing**:
    - Implemented `clip-path: polygon(...)` on both `.hotspot-nav-btn` and `.hotspot-forward-btn` using their exact chevron shapes.
    - Even if the bounding boxes of the chevrons overlap (due to the 3D perspective transformation), the `clip-path` ensures only the painted pixels are sensitive to clicks.
4. **Logic Robustness**:
    - Updated `HotspotManager.res` to explicitly check for `.hotspot-nav-btn` as the target for navigation, instead of falling through.

## Realized Results
- Clicking the auto-forward chevron (the third one) is now extremely precise.
- Clicking near the chevrons or in the transparent overlap area no longer accidentally triggers navigation.
- The UI feels significantly more robust and intentional.
