# Task 270: Auto-select First Scene on Start Building - REPORT

## Objective
The objective was to ensure that when a tour is empty and images are uploaded, the system automatically selects the first scene and loads it into the viewer, specifically ensuring the camera orientation is reset to prevent "stale" or "glitchy" transitions from previous session states.

## Technical Realization

### Core Reducer Improvements
- **Robust Auto-Selection**: Updated `ReducerHelpers.handleAddScenes` to track if the state was previously empty (`wasEmpty`). When adding the first batch of scenes, the `activeIndex` is now explicitly set to `0`.
- **Camera Orientation Reset**: Added logic to `handleAddScenes` to force `activeYaw: 0.0` and `activePitch: 0.0` when the first scene is loaded. This prevents the viewer from inheriting rotation coordinates from a previously deleted tour or a "ghost" state.
- **Cleanup Persistence**: Updated `ReducerHelpers.handleDeleteScene` to reset camera coordinates when the last remaining scene is deleted. This ensures a "clean slate" for subsequent uploads.

### Build & Verification
- **New Unit Tests**: Implemented two additional test cases in `tests/unit/ReducerHelpersTest.res`:
    - `handleAddScenes first load robustness`: Verifies that adding scenes to an empty project correctly selects index 0 and resets camera angles.
    - `handleDeleteScene last scene robustness`: Verifies that deleting the last scene clears the camera state.
- **Verification**: Ran `npm test` and `npm run build` to confirm all systems are stable and that the new logic integrates correctly with the ReScript/Pannellum pipeline.
