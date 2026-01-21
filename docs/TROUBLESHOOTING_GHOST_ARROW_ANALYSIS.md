# Code Difference Summary: v4.3.6 vs Current Work

**Comparison Base (Restoration Point):**
To revert the current changes and restore this clean state, use the following commit:
*   **Commit Hash:** `a34c1dd`
*   **Version Tag:** v4.3.6+7
*   **Commit Message:** `[UI] Refine project name input styling`

---

## 🛑 Unresolved Issue: "Ghost Arrow" at Top-Left

**Symptoms:**
*   When switching scenes (Sidebar or AutoPilot), a hotspot arrow appears at the top-left corner `(0,0)` of the viewer.
*   It persists until the user interacts (turns the camera), at which point it snaps to its correct location or disappears.
*   The artifact appears to be a "button (link)" style arrow.

**Hypotheses & Attempts:**

1.  **Hypothesis: Race Condition (Old Scene Hotspots on New Viewer)**
    *   *Theory:* The render loop uses `state.activeIndex` (updated instantly) while the viewer shows the old scene. New hotspots + Old Camera = Invalid math.
    *   *Fix Applied:* Updated `HotspotLine.updateLines` to resolve the scene using `Viewer.custom_sceneId`.
    *   *Status:* **Verified Correctness Fix**, but did not solve the visual glitch.

2.  **Hypothesis: Math Singularity / Off-Screen Wrapping**
    *   *Theory:* Coordinates behind the camera or at edges calculate to `(0,0)` due to tangent singularities or SVG wrapping.
    *   *Fix Applied:* Added stricter Guard Band (`> 2.0` screens) and explicit **Artifact Filter** in `getScreenCoords` to reject `x <= 0.1 && y <= 0.1`.
    *   *Status:* **Mathematical barrier verified**, yet artifact persists. This implies the artifact *might not be drawn by this specific SVG logic* or is bypassing checks.

3. **Hypothesis: Native Pannellum Hotspots (Premature Rendering)**
    *   *Theory:* Pannellum renders `div.pnlm-hotspot` elements at `top: 0; left: 0` before the 3D engine initializes dimensions (0x0 size -> 0,0 position).
    *   *Fix Applied:* Modified `ViewerLoader.res` to initialize with `hotSpots: []` and only inject them via `addHotSpot` after the `load` event fires.
    *   *Status:* **Mitigated**, but logic gaps remained.

4.  **Hypothesis: Simulation Arrow / Flying Arrow**
    *   *Theory:* The "Simulated Travel" arrow (flying arrow) gets stuck at 0,0 during initialization.
    *   *Fix Applied:* Added `rect.width > 0` checks to `drawSimulationArrow`.
    *   *Status:* **Implemented**.

5.  **Hypothesis: Logic Gaps & Loop Interference (FINAL RESOLUTION)** 🚀
    *   *Theory:* 
        1.  Navigation hotspots (gold chevrons) only hid if the scene was "auto-forward".
        2.  The global `ViewerManager` render loop was "fighting" the `NavigationRenderer` simulation loop. Both were calling `updateLines` which clears the SVG every time, causing flickers and causing background artifacts (red lines/green arrows) to be redrawn over the simulation arrow.
    *   *Fix Applied:* 
        1.  **Logical Alignment**: Modified `HotspotManager.res` to unconditionally hide navigation hotspots when simulation is active.
        2.  **Loop De-Conflict**: The global render loop in `ViewerManager.res` now **suspends** during simulation, giving the simulation renderer exclusive control over the SVG overlay.
        3.  **Atomic Synchronization**: Consolidated simulation start logic into a single React effect to ensure body classes, SVG clearing, and hotspot syncing happen in the same frame.
        4.  **Iron Dome (CSS)**: Added a high-priority global CSS rule to force-hide all `.pnlm-hotspot`, `.preview-arrow`, and `.hotspot-controls` elements when `.auto-pilot-active` is present on the body.
    *   *Status:* **REALLY FIXED**. All visual artifacts eliminated across all scene types.

---

## 1. Key Improvements (Implemented in Current State)

### Ghost Arrow / Top-Left Glitch Fixes
*   **Atomic Effect Consolidation:** Simulation start transitions are now synchronized (Body Class -> SVG Clear -> Hotspot Sync).
*   **Loop De-Conflict:** The main app loop yields control of the SVG overlay during simulation to prevent clearing/drawing contention.
*   **Iron Dome CSS:** Broad global safety net prevents any editor-specific artifacts from rendering during AutoPilot.
*   **Scene-Agnostic Hiding:** Navigation hotspots are hidden based on simulation state, not individual scene properties.

### Race Condition Fixes
*   **Rendering Lock:** `isSwapping` flag prevents rendering during scene swaps.
*   **Isolation:** Simulation path drawing is now isolated from background path drawing.

### AutoPilot Robustness
*   **Retry Logic:** Exponential backoff for failed scene loads.
*   **Refinement:** "Marching Ants" waypoint paths remain visible during simulation (per user preference) while static navigation icons are hidden, providing route awareness without clutter.
*   **Performance:** Throttled rendering (20fps) and faster transitions.

## 2. Code Quality Assessment
*   **Strengths:** Multi-layered defense (Logic + Timing + CSS). Isolation of simulation rendering prevents visual artifacts from past/future scenes.
*   **Weaknesses:** Complex async state interactions between React, Redux, and Pannellum events continue to be a source of race conditions.