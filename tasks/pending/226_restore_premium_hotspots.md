# Task 226: Restore v4.2.18 Premium Hotspot SVGs & Arc Controls

## Objective
Restore the "Arc" hotspot system, including multi-layered SVG arrows and the pop-in control toggles.

## Context
Current hotspots might be simpler or missing the specific gradient-based depth of v4.2.18. The "Arc" controls (Delete/Forward/Return) need their specific v4.2.18 layout and pop animations.

## Requirements
1.  **Multi-Layer SVGs:** Update `HotspotManager.res` to render the complex SVG with `glow-top` and `glow-bottom` paths.
2.  **Gradient Definitions:** Ensure the SVG `defs` for `#hsG_idx` and `#autoForwardGradient` are correctly injected.
3.  **Pop-in Controls:** Port the `.hotspot-delete-btn` and `.hotspot-controls` CSS with the specific `cubic-bezier` transitions.
4.  **Color Sync:** Ensure Forward/Return toggles use the specific v4.2.18 Teal and Orange active colors.

## Verification
*   Hotspots should have a gold/yellow gradient with a subtle glow.
*   Hovering/Interacting should reveal the Delete and Direction controls with a smooth "pop" animation.
