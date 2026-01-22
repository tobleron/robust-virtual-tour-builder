# Task 226: Restore v4.2.18 Premium Hotspot SVGs & Arc Controls - REPORT

## Objective
Restore the "Arc" hotspot system, including multi-layered SVG arrows and the pop-in control toggles, matching the high-fidelity visuals of v4.2.18.

## Technical Realization

### 1. Multi-Layer SVG Architecture
- Updated `HotspotManager.res` to render a complex SVG structure for hotspots.
- Added a **depth shadow path** (shifted by 3px with 40% opacity) to create a 3D effect.
- Added a **top highlight path** (30% opacity white sheen) to simulate light reflecting off the top edge.
- Maintained the `glow-top` and `glow-bottom` paths for the sequenced pulse animation.

### 2. Gradient Enhancement
- Implemented **3-stop linear gradients** for both standard and auto-forward modes:
    - **Premium Gold**: `#FFD700` (0%) -> `#FDB931` (50%) -> `#8B6508` (100%)
    - **Auto-Forward Teal**: `#10b981` (0%) -> `#059669` (50%) -> `#047857` (100%)
- This adds significant depth and "premium" feel compared to the previous 2-stop gradients.

### 3. Pop-in Control Toggles
- Refactored `css/components/viewer.css` to implement the "Arc" control layout.
- Added `cubic-bezier(0.175, 0.885, 0.32, 1.275)` transitions for a "tactile pop" feel.
- Controls (`Delete`, `Forward`, `Return`) now start at `scale(0.5)` with `opacity: 0` and pop to `scale(1.0)` on hotspot hover.
- Individual buttons scale further to `1.15` on direct hover.

### 4. Color & Style Synchronization
- Synchronized active toggle colors:
    - **Active Forward**: Teal (`#059669`) with Emerald border and glow.
    - **Active Return**: Orange (`#ea580c`) with brighter Orange border and glow.
- Cleaned up `css/tailwind.css` to remove legacy absolute positioning that conflicted with the new flex-based control container.

## Verification Results
- Hotspots now exhibit a rich, multi-layered appearance with 3D depth.
- Hovering triggers a smooth, bouncy "pop" animation for the controls.
- Building the project confirmed CSS integrity and ReScript type safety.