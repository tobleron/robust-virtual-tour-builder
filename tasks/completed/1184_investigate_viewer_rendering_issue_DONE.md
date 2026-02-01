# 🔍 INVESTIGATION TASK: Imported Images Not Showing in Window Viewer

## 🚩 PROBLEM STATEMENT
Images imported via ZIP (e.g., 'xyz.zip') load successfully in the backend and sidebar, but do not render in the main 360 window viewer. The viewer remains blank (black) or stuck in a loading state, even though the Navigation FSM reports `StabilizeComplete`.

## 🛠️ CONTEXT & RECENT FIXES (v4.8.14+391)
We have already implemented the following infrastructure fixes:
1.  **URL Reconstruction**: `ProjectManager` now correctly transforms relative paths (`images/1.jpg`) into full API URLs with `sessionId` and `?token=...`.
2.  **FSM Deadlock Fix**: Added `TransitionComplete` handler to `NavigationFSM` to prevent the UI from getting stuck in the `Transitioning` state during direct scene switches.
3.  **Native Load Bridge**: Updated `ViewerSystem.Adapter` to use Pannellum's native `isLoaded()` and hooked it into `SceneLoader` to ensure fast-loading/cached images trigger FSM progression.

## 🕵️ INVESTIGATION VECTORS

### 1. CSS / DOM Visibility
*   Verify that `panorama-a` or `panorama-b` containers have the `.active` class.
*   Check if `opacity: 0` or `display: none` is being incorrectly applied by the transition system (`SceneTransition.res`).
*   Inspect the z-index of the `viewer-ui-layer` to ensure it isn't masking the canvas.

### 2. Pannellum Rendering Lifecycle
*   Check browser console for "Pannellum: ... not found" or WebGL errors.
*   Verify if the canvas element is actually being created inside the layer containers.
*   Investigate if `ViewerSystem.Adapter.initialize` is receiving a valid URL (inspect the `config.panorama` value).

### 3. MIME Sniffing & Header Integrity
*   Check Network tab for the image request.
*   Ensure the response has `Content-Type: image/webp` (or jpeg/png). 
*   Legacy files in ZIPs might lack extensions; the backend (`serve.rs`) performs sniffing, but verify if the browser is rejecting the blob/stream.

### 4. Race Conditions in `SceneLoader`
*   The `onSceneLoad` event dispatches `TextureLoaded`. If this happens *before* the DOM swap completes or *before* Pannellum is fully ready to paint, the viewer might stay black.
*   Check `SceneTransition.res` -> `finalizeSwap` which handles `HotspotLine.updateLines`.

## 📝 ACTIONS REQUIRED
1.  **Reproduce**: Import a ZIP and click a scene.
2.  **Trace**: Use `Logger.debug` in `SceneLoader.res` and `SceneTransition.res` to see the exact timing of `TextureLoaded` vs `performSwap`.
3.  **Inspect**: Check the DOM state of `#panorama-a` and `#panorama-b` when the screen is black.
4.  **Fix**: Address the rendering bottleneck or visibility mismatch.

---
**Status**: Investigation Pending | **Build**: 391 | **Branch**: development
