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

- [ ] - **../../src/systems/TeaserLogic.res** (Metric: [Nesting: 2.40, Density: 0.01, Coupling: 0.08] | Drag: 3.41 | LOC: 591/300  🎯 Target: Function: `readMotionManifest` (High Local Complexity (1.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/TeaserPlayback.res** (Metric: [Nesting: 2.40, Density: 0.02, Coupling: 0.07] | Drag: 3.42 | LOC: 399/300  🎯 Target: Function: `start` (High Local Complexity (1.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/TeaserRecorder.res** (Metric: [Nesting: 6.00, Density: 0.23, Coupling: 0.05] | Drag: 7.25 | LOC: 485/300  🎯 Target: Function: `_` (High Local Complexity (6.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


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
- `src/systems/TeaserLogic.res` (12 functions, fingerprint 12c3c58202903d58537b32470f5e4c2d48cd6b186dff01baf5d0474437d9a970)
    - Grouped summary:
        - centerViewerAtWaypointStart × 1 (lines: 76)
        - check × 1 (lines: 189)
        - finalizeTeaser × 1 (lines: 149)
        - logoState × 1 (lines: 185)
        - parseTeaserProgressMetrics × 1 (lines: 106)
        - readHeadlessMotionProfile × 1 (lines: 24)
        - readMotionManifest × 1 (lines: 36)
        - resolveTeaserStartView × 1 (lines: 55)
        - safeName × 1 (lines: 198)
        - signalIsAborted × 1 (lines: 143)
        - state × 1 (lines: 184)
        - teaserEtaToastId × 1 (lines: 98)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TeaserPlayback.res`
- `src/systems/TeaserPlayback.res` (16 functions, fingerprint 6c25b749e95af9c1e40defba88ac49d597cc6431d387dc1ae788dad012c277eb)
    - Grouped summary:
        - animatePan × 1 (lines: 78)
        - animatePose × 1 (lines: 47)
        - clamp01 × 1 (lines: 197)
        - getLastSegmentPose × 1 (lines: 231)
        - getManifestStateAt × 1 (lines: 297)
        - getShotMotionDuration × 1 (lines: 206)
        - getShotTargetPose × 1 (lines: 238)
        - getShotTiming × 1 (lines: 216)
        - interpolateSegments × 1 (lines: 249)
        - playManifest × 1 (lines: 362)
        - prepareFirstScene × 1 (lines: 86)
        - recordShot × 1 (lines: 118)
        - resolveShotPoseAt × 1 (lines: 278)
        - transitionToNextShot × 1 (lines: 130)
        - wait × 1 (lines: 11)
        - waitForViewerReady × 1 (lines: 16)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TeaserRecorder.res`
- `src/systems/TeaserRecorder.res` (39 functions, fingerprint 4b476d015fdd65e36e6021b1d17fa9a16e2587cab224be759e84a418515dc0ed)
    - Grouped summary:
        - canvasHeight × 1 (lines: 5)
        - canvasWidth × 1 (lines: 4)
        - checkRoundRect × 1 (lines: 135)
        - drawRoundedRect × 1 (lines: 137)
        - getGhostCanvas × 2 (lines: 489, 517)
        - getHudScale × 1 (lines: 152)
        - getOrCreate × 1 (lines: 80)
        - getRecordedBlobs × 2 (lines: 490, 518)
        - hdReferenceHeight × 1 (lines: 150)
        - hdReferenceWidth × 1 (lines: 149)
        - initGhost × 1 (lines: 122)
        - internalState × 2 (lines: 59, 525)
        - loadLogo × 2 (lines: 110, 521)
        - pause × 1 (lines: 515)
        - pauseRecording × 1 (lines: 475)
        - renderFloorNav × 1 (lines: 258)
        - renderFrame × 2 (lines: 329, 524)
        - renderRoomLabel × 1 (lines: 191)
        - renderWatermark × 1 (lines: 169)
        - requestDeterministicFrame × 2 (lines: 72, 523)
        - resume × 1 (lines: 516)
        - resumeRecording × 1 (lines: 482)
        - setFadeOpacity × 2 (lines: 507, 520)
        - setOpacity × 1 (lines: 96)
        - setSnapshot × 2 (lines: 492, 519)
        - startAnimationLoop × 2 (lines: 380, 522)
        - startRecording × 2 (lines: 392, 513)
        - stopRecording × 2 (lines: 452, 514)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
