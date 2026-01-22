# Task 299: Sync Hotspot Visibility on Simulation Start - FINAL REPORT

## Objective
The primary goal was to eliminate the "ghost arrow" artifact where navigation hotspots (gold chevrons) or editor lines remained visible in the starting scene when AutoPilot (Simulation) began.

## Root Cause Analysis
1. **Logic Hole**: `HotspotManager.res` only hid hotspots if the scene was explicitly set to "auto-forward". This left chevrons visible in non-auto-forward starting scenes.
2. **Race Condition**: Two separate render loops (in `ViewerManager` and `NavigationRenderer`) were fighting over the same SVG container. The global loop was clearing/redrawing background hotspots while the simulation driver was trying to draw the "flying" arrow.
3. **State Desync**: Hotspot synchronization was split across multiple `useEffect` hooks, leading to frames where the body class was added but the hotspots hadn't been re-synced yet.

## Technical Implementation

### 1. Unified Simulation Guard
**File**: `src/components/HotspotManager.res`, `src/systems/HotspotLine.res`, `src/components/ViewerManager.res`

Updated all simulation checks to use `status != Idle` instead of just `status == Running`. This ensures artifacts stay hidden during `Paused` and `Stopping` states as well.

### 2. Atomic Effect Consolidation
**File**: `src/components/ViewerManager.res`

Consolidated simulation start logic into a single atomic `useEffect`:
- Adds `.auto-pilot-active` to body.
- Clears SVG overlay immediately.
- Calls `HotspotManager.syncHotspots` to update native hotspots.

### 3. Render Loop De-Conflict
**File**: `src/components/ViewerManager.res`

Modified the global render loop to **suspend** while simulation is active. This gives `NavigationRenderer` exclusive ownership of the SVG overlay, preventing "flicker" caused by competing clear/redraw cycles.

### 4. Code Logic Fixes
- **HotspotManager**: Removed the `isCurrentSceneAutoForward` requirement. If `isSimulationMode` is true, navigation hotspots are ALWAYS hidden.
- **HotspotLine**: Added guards to skip drawing "Persistent Red Dashed Lines" and "Preview Arrows" during simulation.

### 5. Global 'Iron Dome' Safety Net
**File**: `css/components/viewer.css`

Added a broad CSS rule using the body class to force-hide all potential artifacts:
```css
.auto-pilot-active .pnlm-hotspot,
.auto-pilot-active .line-marching-ants,
.auto-pilot-active .preview-arrow {
    display: none !important;
    visibility: hidden !important;
}
```

## Refinement: Waypoint Path Visibility
Based on user feedback, the "Persistent Red Dashed Lines" (waypoint paths) have been re-enabled during simulation.

### Implementation Details
- **Selective Visibility**: While navigation hotspots and interactive arrows remain hidden to ensure a clean view, the "marching ants" path indicators are now permitted.
- **Ghosting Prevention**: Ghosting is prevented by the Loop De-Conflict mechanism. Since only the `NavigationRenderer` handles SVG updates during simulation, it ensures that only the path for the active target scene is drawn, even during complex crossfade transitions.
- **CSS Iron Dome Update**: The `.line-marching-ants` class was removed from the global simulation hide rule to allow ReScript logic to control its visibility.

## Final Verification
- Verified that red dashed lines follow the AutoPilot route.
- Verified that transitions between scenes are clean and don't leave lingering "ghost" paths from the previous scene.
- Confirmed that the build is clean and all 32 modules compile successfully.
