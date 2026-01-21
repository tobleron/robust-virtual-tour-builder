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

3.  **Hypothesis: Native Pannellum Hotspots (Premature Rendering)**
    *   *Theory:* Pannellum renders `div.pnlm-hotspot` elements at `top: 0; left: 0` before the 3D engine initializes dimensions (0x0 size -> 0,0 position).
    *   *Fix Applied:* Modified `ViewerLoader.res` to initialize with `hotSpots: []` and only inject them via `addHotSpot` after the `load` event fires.
    *   *Status:* **Implemented**, but user reports issue persists.

4.  **Hypothesis: Simulation Arrow / Flying Arrow**
    *   *Theory:* The "Simulated Travel" arrow (flying arrow) gets stuck at 0,0 during initialization.
    *   *Fix Applied:* Added `rect.width > 0` checks to `drawSimulationArrow`.

**Next Steps for Troubleshooting:**
*   **Isolate the Element:** Inspect the DOM to see if the ghost is an SVG `<path>` (our system) or a `<div>` (Pannellum native).
*   **Check CSS:** Verify if a default `transform: translate(0,0)` is applied to any hotspot container before dynamic updates kick in.
*   **Review `state.simulation.status`:** If the ghost is green, it's a Preview Arrow. Ensure `updateLines` is not being called with default (0,0,0) camera data despite `isViewerReady` checks.
*   **Verify Build:** Ensure `src/systems/HotspotLine.bs.js` actually contains the Artifact Filter logic (previous builds were locked).

---

## 1. Key Improvements (Implemented in Current State)

### Ghost Arrow / Top-Left Glitch Fixes
*   **Deferred Hotspot Injection:** `ViewerLoader.res` initializes with empty hotspots and injects them post-load.
*   **Scene Resolution:** `HotspotLine.updateLines` resolves scene via `_sceneId` to match viewer content.
*   **Guard Band & Filter:** `getScreenCoords` aggressively rejects `(0,0)` and off-screen values.
*   **Safety Checks:** `drawSimulationArrow` and `isViewerReady` have added null/zero checks.

### Race Condition Fixes
*   **Rendering Lock:** `isSwapping` flag prevents rendering during scene swaps.

### AutoPilot Robustness
*   **Retry Logic:** Exponential backoff for failed scene loads.
*   **Performance:** Throttled rendering (20fps) and faster transitions.

## 2. Code Quality Assessment
*   **Strengths:** Defensive programming (Guard Bands, Null Checks), explicit state management.
*   **Weaknesses:** Complex async state interactions between React, Redux, and Pannellum events continue to be a source of race conditions.