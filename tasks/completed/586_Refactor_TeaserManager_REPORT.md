# Task 586: Refactor TeaserManager (COMPLETED)

## Objective
Split Teaser playback/recording logic from state management to address file size limit.

## Implementation Details
1. **Created `src/systems/TeaserState.res`**:
   - Extracted `teaserConfig` type and constants (`fastConfig`, `slowConfig`, `punchyConfig`).
   - Added helper `getConfigForStyle`.

2. **Created `src/systems/TeaserPlayback.res`**:
   - Moved playback logic: `animatePan`, `prepareFirstScene`, `recordShot`, `transitionToNextShot`.
   - Moved `waitForViewerReady` and `wait` helpers.
   - Logic remains functionally identical but decoupled from Orchestration.

3. **Refactored `src/systems/TeaserManager.res`**:
   - Reduced file size significantly.
   - Acts as orchestrator/facade now.
   - Delegates to `TeaserPlayback`, `TeaserRecorder`, and `TeaserState`.
   - Preserved `startAutoTeaser` and `startCinematicTeaser` signatures to maintain compatibility with `Sidebar.res`.

## Verification
- Checked imports and dependency graph.
- Verified manual usage in `Sidebar.res` against new signature (compatible).
- Validated `TeaserRecorder.res` logic.
