# Task D011: Surgical Refactor SYSTEMS FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 1.80 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/systems/OperationLifecycle.res** (Metric: [Nesting: 3.00, Density: 0.22, Coupling: 0.03] | Drag: 4.28 | LOC: 381/300  🎯 Target: Function: `updateLoggerContext` (High Local Complexity (14.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/TeaserLogic.res** (Metric: [Nesting: 2.40, Density: 0.02, Coupling: 0.11] | Drag: 3.42 | LOC: 385/300  🎯 Target: Function: `readMotionManifest` (High Local Complexity (1.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/TeaserPlayback.res** (Metric: [Nesting: 2.40, Density: 0.02, Coupling: 0.07] | Drag: 3.42 | LOC: 385/300  🎯 Target: Function: `start` (High Local Complexity (1.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/TeaserRecorder.res** (Metric: [Nesting: 6.00, Density: 0.23, Coupling: 0.05] | Drag: 7.24 | LOC: 478/300  🎯 Target: Function: `_` (High Local Complexity (6.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D011/verification.json` (files at `_dev-system/tmp/D011/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D011/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/OperationLifecycle.res`
- `src/systems/OperationLifecycle.res` (19 functions, fingerprint be040c29c53ce43d2e200948a53503deca8e0ea78decd4fba4d36d8457f46a04)
    - Grouped summary:
        - cancel × 1 (lines: 343)
        - cancelCallbacks × 1 (lines: 54)
        - complete × 1 (lines: 255)
        - fail × 1 (lines: 299)
        - getOperation × 1 (lines: 117)
        - getOperations × 1 (lines: 121)
        - isActive × 1 (lines: 125)
        - isBusy × 1 (lines: 136)
        - listeners × 1 (lines: 53)
        - notifyListeners × 1 (lines: 58)
        - operations × 1 (lines: 52)
        - progress × 1 (lines: 220)
        - registerCancel × 1 (lines: 113)
        - reset × 1 (lines: 96)
        - start × 1 (lines: 157)
        - subscribe × 1 (lines: 103)
        - updateLoggerContext × 1 (lines: 63)
        - useIsBusy × 1 (lines: 424)
        - useOperations × 1 (lines: 411)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TeaserLogic.res`
- `src/systems/TeaserLogic.res` (9 functions, fingerprint b2fa6a257ea8bc8f16d7df2ff3c40b4021578e4343a4af6911b58e4c8941ac17)
    - Grouped summary:
        - centerViewerAtWaypointStart × 1 (lines: 81)
        - check × 1 (lines: 151)
        - finalizeTeaser × 1 (lines: 112)
        - logoState × 1 (lines: 147)
        - readHeadlessMotionProfile × 1 (lines: 24)
        - readMotionManifest × 1 (lines: 36)
        - resolveTeaserStartView × 1 (lines: 55)
        - safeName × 1 (lines: 160)
        - signalIsAborted × 1 (lines: 105)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TeaserPlayback.res`
- `src/systems/TeaserPlayback.res` (16 functions, fingerprint d7ef418ef3fe601e5093142b072094210f40a67fb5d8103408bc57348c5a2b2b)
    - Grouped summary:
        - animatePan × 1 (lines: 74)
        - animatePose × 1 (lines: 47)
        - clamp01 × 1 (lines: 191)
        - getLastSegmentPose × 1 (lines: 223)
        - getManifestStateAt × 1 (lines: 289)
        - getShotMotionDuration × 1 (lines: 200)
        - getShotTargetPose × 1 (lines: 230)
        - getShotTiming × 1 (lines: 209)
        - interpolateSegments × 1 (lines: 241)
        - playManifest × 1 (lines: 352)
        - prepareFirstScene × 1 (lines: 82)
        - recordShot × 1 (lines: 113)
        - resolveShotPoseAt × 1 (lines: 270)
        - transitionToNextShot × 1 (lines: 125)
        - wait × 1 (lines: 11)
        - waitForViewerReady × 1 (lines: 16)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TeaserRecorder.res`
- `src/systems/TeaserRecorder.res` (39 functions, fingerprint 4053465960cf994bad833424f273eb8868bc7f07786553018bfce6627f2b2886)
    - Grouped summary:
        - canvasHeight × 1 (lines: 5)
        - canvasWidth × 1 (lines: 4)
        - checkRoundRect × 1 (lines: 131)
        - drawRoundedRect × 1 (lines: 133)
        - getGhostCanvas × 2 (lines: 482, 510)
        - getHudScale × 1 (lines: 148)
        - getOrCreate × 1 (lines: 80)
        - getRecordedBlobs × 2 (lines: 483, 511)
        - hdReferenceHeight × 1 (lines: 146)
        - hdReferenceWidth × 1 (lines: 145)
        - initGhost × 1 (lines: 118)
        - internalState × 2 (lines: 59, 518)
        - loadLogo × 2 (lines: 110, 514)
        - pause × 1 (lines: 508)
        - pauseRecording × 1 (lines: 468)
        - renderFloorNav × 1 (lines: 250)
        - renderFrame × 2 (lines: 322, 517)
        - renderRoomLabel × 1 (lines: 186)
        - renderWatermark × 1 (lines: 161)
        - requestDeterministicFrame × 2 (lines: 72, 516)
        - resume × 1 (lines: 509)
        - resumeRecording × 1 (lines: 475)
        - setFadeOpacity × 2 (lines: 500, 513)
        - setOpacity × 1 (lines: 96)
        - setSnapshot × 2 (lines: 485, 512)
        - startAnimationLoop × 2 (lines: 373, 515)
        - startRecording × 2 (lines: 385, 506)
        - stopRecording × 2 (lines: 445, 507)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
