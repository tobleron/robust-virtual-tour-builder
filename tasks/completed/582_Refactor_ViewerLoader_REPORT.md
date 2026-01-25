# Task 582: Refactor ViewerLoader (Lifecycle Management)

## 🚨 Trigger
Project "Surgical Edit" Initiative.
File `src/components/ViewerLoader.res` handles Pannellum Lifecycle, Scene Swapping, Crossfades, and Error Recovery in one giant file.

## Objective
Split the lifecycle phases into distinct managers.

## Required Refactoring
1. **SceneTransitionManager.res**: Handle the DOM-level crossfade and visibility toggles.
2. **PannellumLifecycle.res**: Isolate the `viewer.init()` and `viewer.destroy()` calls.
3. **SceneLoader.res**: Handle the async pre-fetching and validation logic.

## Safety & Constraints
- **Visual Smoothness**: The scene swap must NOT flicker.
- **Race Conditions**: Verify rapid scene switching doesn't break state.

## Implementation Report
The refactoring was successfully completed. `ViewerLoader.res` has been decomposed into three distinct system modules:

1.  **src/systems/PannellumLifecycle.res**:
    -   Encapsulates strict bindings for `Pannellum.viewer()` initialization and `Viewer.destroy()`.
    -   Manages `customViewerProps` type definition.

2.  **src/systems/SceneTransitionManager.res**:
    -   Handles the critical `performSwap` logic.
    -   Manages DOM class toggling, crossfade transitions (`cut` vs `fade`), and cleanup of the inactive viewer.
    -   Ensures correct timing for HotspotLine updates to prevent "ghost arrows" during swap.

3.  **src/systems/SceneLoader.res**:
    -   Handles the high-level `loadNewScene` orchestration.
    -   Implements progressive loading (tinyFile -> fullFile).
    -   Manages timeouts and safety checks.
    -   Calls `SceneTransitionManager.performSwap` and performs the subsequent "Recovery Check" to handle race conditions during rapid navigation.

**Resolution of Circular Dependencies:**
-   Previously, `performSwap` called `loadNewScene` recursively for recovery.
-   Now, `SceneTransitionManager.performSwap` is a pure mechanism. `SceneLoader` calls `performSwap` and *then* performs the recovery check itself, re-triggering `loadNewScene` if necessary. This decoupling enables clean separation of concerns.

**Result:**
-   `src/components/ViewerLoader.res` is now a lightweight facade delegating to these systems, ensuring backward compatibility.
-   Build verified with 0 warnings.
