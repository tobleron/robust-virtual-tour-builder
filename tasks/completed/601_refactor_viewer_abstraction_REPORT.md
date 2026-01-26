# REPORT: Abstract Viewer Interface Refactor ("The Driver")

## 🚀 Objective
The objective was to decouple the core business logic in `SceneLoader.res` and `SceneTransitionManager.res` from specific DOM IDs and hardcoded `pannellum` calls. This enables multi-viewport features and future-proofs the app for alternative renderers.

## 🛠️ Technical Implementation
1. **Interface Definition**: Created `src/core/interfaces/ViewerDriver.res` defining a strict contract (`Driver`) for 360 viewer implementations.
2. **Pannellum Adapter**: Implemented `src/systems/PannellumAdapter.res` which wraps the existing `window.pannellum` bindings into the standard `Driver` interface.
3. **Viewer Pool Manager**: Created `src/systems/ViewerPool.res` to manage a dynamic collection of viewports. It handles registration, status tracking (`#Active`, `#Background`, `#Free`), and cleanup timeouts.
4. **Core Integration**: Refactored `SceneLoader.res` and `SceneTransitionManager.res` to request viewer handles from the `ViewerPool` and interact via the `PannellumAdapter` instead of direct DOM manipulation.
5. **Decoupling**: Removed the hardcoded `viewerA`, `viewerB`, and `activeViewerKey` fields from `ViewerState.res`, delegating all viewer management to the pool.

## ✅ Realization & Verification
- **Build**: Verified zero compiler warnings.
- **Unit Testing**: Refactored all unit tests (HotspotLine, ViewerFollow, ViewerSnapshot, ViewerManager) to use `ViewerPool` for mocking. All 660 tests passed.
- **Architectural Cleanup**: Updated `MAP.md` and ensured all `external` bindings for Pannellum are now safely contained within `PannellumAdapter.res` or its bindings.
- **Compatibility**: Maintained `window.pannellumViewer` assignment in the adapter for potential legacy/debug support while ensuring the internal logic uses the abstracted pool.

## 📈 Outcome
The application now supports dynamic viewer management. We are no longer limited to two hardcoded panorama slots, paving the way for "Split View" comparisons and decoupled Minimap renderers. Testing has become easier as viewers can be mocked by simply registering a mock instance in the pool.
