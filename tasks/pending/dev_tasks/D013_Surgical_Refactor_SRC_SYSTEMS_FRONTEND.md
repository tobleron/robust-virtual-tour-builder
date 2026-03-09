# Task D013: Surgical Refactor SRC SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/ExifParser.res** (Metric: [Nesting: 4.20, Density: 0.13, Coupling: 0.04] | Drag: 5.33 | LOC: 371/300  ⚠️ Trigger: Drag above target (1.80) with file already at 371 LOC.  🎯 Target: Function: `getValue` (High Local Complexity (4.9). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/Exporter.res** (Metric: [Nesting: 2.40, Density: 0.06, Coupling: 0.10] | Drag: 3.49 | LOC: 311/300  ⚠️ Trigger: Drag above target (1.80) with file already at 311 LOC.  🎯 Target: Function: `opId` (High Local Complexity (2.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/OperationLifecycle.res** (Metric: [Nesting: 3.60, Density: 0.21, Coupling: 0.03] | Drag: 4.93 | LOC: 404/300  🎯 Target: Function: `ttlMsForType` (High Local Complexity (7.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/ProjectSystem.res** (Metric: [Nesting: 1.80, Density: 0.05, Coupling: 0.10] | Drag: 2.85 | LOC: 437/300  🎯 Target: Function: `notifyProjectValidationWarnings` (High Local Complexity (3.5). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/Simulation.res** (Metric: [Nesting: 7.20, Density: 0.25, Coupling: 0.08] | Drag: 8.47 | LOC: 383/300  🎯 Target: Function: `make` (High Local Complexity (9.1). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/TeaserHeadlessLogic.res** (Metric: [Nesting: 7.80, Density: 0.21, Coupling: 0.09] | Drag: 9.26 | LOC: 348/300  ⚠️ Trigger: Drag above target (1.80) with file already at 348 LOC.  🎯 Target: Function: `etaSeconds` (High Local Complexity (5.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/TeaserManifest.res** (Metric: [Nesting: 3.00, Density: 0.15, Coupling: 0.05] | Drag: 4.15 | LOC: 352/300  ⚠️ Trigger: Drag above target (1.80) with file already at 352 LOC.  🎯 Target: Function: `pickWaypointHotspot` (High Local Complexity (6.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/TeaserOfflineCfrRenderer.res** (Metric: [Nesting: 2.40, Density: 0.09, Coupling: 0.12] | Drag: 3.49 | LOC: 298/300  ⚠️ Trigger: Drag above target (1.80) with file already at 298 LOC.  🎯 Target: Function: `floorLevelsInUse` (High Local Complexity (7.5). Logic heavy.)) → Refactor in-place

- [ ] - **../../src/systems/TeaserRecorder.res** (Metric: [Nesting: 6.00, Density: 0.28, Coupling: 0.06] | Drag: 7.31 | LOC: 356/300  ⚠️ Trigger: Drag above target (1.80) with file already at 356 LOC.  🎯 Target: Function: `_` (High Local Complexity (6.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/TeaserRecorderHud.res** (Metric: [Nesting: 5.40, Density: 0.27, Coupling: 0.03] | Drag: 6.71 | LOC: 457/300  🎯 Target: Function: `clampCorner` (High Local Complexity (4.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/TourTemplates.res** (Metric: [Nesting: 3.00, Density: 0.03, Coupling: 0.02] | Drag: 4.03 | LOC: 337/300  ⚠️ Trigger: Drag above target (1.80) with file already at 337 LOC.) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D013/verification.json` (files at `_dev-system/tmp/D013/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D013/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/ExifParser.res`
- `src/systems/ExifParser.res` (8 functions, fingerprint 1f11916999bc0d3527ad90faa605f938bd27c357100001329d77a5675fe2679c)
    - Grouped summary:
        - _ × 1 (lines: 48)
        - _tags × 1 (lines: 38)
        - backendResult × 1 (lines: 409)
        - backendUrl × 1 (lines: 18)
        - emptyPano × 1 (lines: 20)
        - json × 1 (lines: 391)
        - osmDecoder × 1 (lines: 393)
        - res × 1 (lines: 390)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/Exporter.res`
- `src/systems/Exporter.res` (9 functions, fingerprint a937271445e7fae816914e2480d20fdf89d59202e58d67e8ff860d17c72ad4fa)
    - Grouped summary:
        - currentPhase × 1 (lines: 34)
        - exportScenes × 1 (lines: 17)
        - finalMsg × 1 (lines: 315)
        - msg × 1 (lines: 301)
        - normalizedStack × 1 (lines: 302)
        - opId × 1 (lines: 19)
        - payload × 1 (lines: 314)
        - progress × 1 (lines: 36)
        - tourName × 1 (lines: 49)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/OperationLifecycle.res`
- `src/systems/OperationLifecycle.res` (30 functions, fingerprint 880f85b7aa4348a6bf7de207fbf48640013017efa496058736f409353bb93dbe)
    - Grouped summary:
        - activeCount × 1 (lines: 52)
        - cancel × 1 (lines: 365)
        - cancelCallbacks × 1 (lines: 14)
        - cleanupTerminalOperation × 1 (lines: 58)
        - complete × 1 (lines: 280)
        - completedTotal × 1 (lines: 15)
        - ensureSweepInterval × 1 (lines: 103)
        - fail × 1 (lines: 323)
        - getOperation × 1 (lines: 146)
        - getOperations × 1 (lines: 150)
        - getStats × 1 (lines: 429)
        - isActive × 1 (lines: 154)
        - isBusy × 1 (lines: 165)
        - leakedTotal × 1 (lines: 16)
        - listeners × 1 (lines: 13)
        - notifyListeners × 1 (lines: 35)
        - operations × 1 (lines: 12)
        - progress × 1 (lines: 245)
        - registerCancel × 1 (lines: 142)
        - reset × 1 (lines: 114)
        - start × 1 (lines: 183)
        - subscribe × 1 (lines: 132)
        - sweepExpiredOperations × 1 (lines: 65)
        - sweepIntervalId × 1 (lines: 17)
        - timeoutTtlExceeded × 1 (lines: 20)
        - ttlMsForType × 1 (lines: 22)
        - ttlSweepMs × 1 (lines: 19)
        - updateLoggerContext × 1 (lines: 40)
        - useIsBusy × 1 (lines: 452)
        - useOperations × 1 (lines: 439)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/ProjectSystem.res`
- `src/systems/ProjectSystem.res` (11 functions, fingerprint 211523d2e8905cc7bccbc80ce4962419eb906fedabaf9a1f7232acfc72cec5c7)
    - Grouped summary:
        - createSavePackage × 1 (lines: 319)
        - encodeProjectFromState × 1 (lines: 27)
        - encodeValidationReport × 1 (lines: 121)
        - loadProjectZip × 1 (lines: 234)
        - mergeValidationReport × 1 (lines: 116)
        - notifyProjectValidationWarnings × 1 (lines: 44)
        - processLoadedProjectData × 1 (lines: 144)
        - projectFromState × 1 (lines: 8)
        - validateProjectStructure × 1 (lines: 37)
        - validationReportWrapperDecoder × 1 (lines: 33)
        - verifyProjectLoadPolicy × 1 (lines: 88)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/Simulation.res`
- `src/systems/Simulation.res` (1 functions, fingerprint f640637d426e584650a35e3691a72a356b7a670ecdef934c9fac9763d9533353)
    - Grouped summary:
        - make × 1 (lines: 13)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TeaserHeadlessLogic.res`
- `src/systems/TeaserHeadlessLogic.res` (4 functions, fingerprint 2c46f29ede0ad0575fccc611f74ebd4b4ea0bb875dffe2cc3e590f8073c9c822)
    - Grouped summary:
        - parseTeaserProgressMetrics × 1 (lines: 11)
        - signalIsAborted × 1 (lines: 15)
        - startHeadlessTeaserWithStyle × 1 (lines: 17)
        - teaserEtaToastId × 1 (lines: 7)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TeaserManifest.res`
- `src/systems/TeaserManifest.res` (14 functions, fingerprint 3f180ed128eaf6732226eb80d2761653b4996cc26e62df4978fbd1713feba177)
    - Grouped summary:
        - addVisited × 1 (lines: 57)
        - applyVisitedActions × 1 (lines: 65)
        - calculateShotDuration × 1 (lines: 369)
        - calculateSimulationWaitDuration × 1 (lines: 76)
        - calculateTotalManifestDuration × 1 (lines: 386)
        - generateManifest × 1 (lines: 272)
        - generateSimulationParityManifest × 1 (lines: 116)
        - getInitialPose × 1 (lines: 37)
        - getSceneWaypointPose × 1 (lines: 21)
        - init × 1 (lines: 390)
        - moduleName × 1 (lines: 4)
        - pickWaypointHotspot × 1 (lines: 9)
        - simulationCrossfadeMs × 1 (lines: 6)
        - simulationIntroPanMs × 1 (lines: 7)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TeaserOfflineCfrRenderer.res`
- `src/systems/TeaserOfflineCfrRenderer.res` (9 functions, fingerprint 05c78bc8bf221b9e6f80557c9fc23ea7682f96299715f1548ffeefb4d5921fc7)
    - Grouped summary:
        - floorLevelsInUse × 1 (lines: 18)
        - forceLoadSceneAndWait × 1 (lines: 79)
        - marketingOverlayFromState × 1 (lines: 137)
        - normalizeSceneFloor × 1 (lines: 9)
        - renderWebMDeterministic × 1 (lines: 156)
        - sceneOverlayFor × 1 (lines: 101)
        - signalIsAborted × 1 (lines: 31)
        - throwIfCancelled × 1 (lines: 37)
        - waitForViewerReadyOrAbort × 1 (lines: 44)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TeaserRecorder.res`
- `src/systems/TeaserRecorder.res` (43 functions, fingerprint 85e3f1acd9145df1a90d2d95f2a7d6a81b2351bbdd34595901fd388aa9e39845)
    - Grouped summary:
        - canvasHeight × 1 (lines: 5)
        - canvasWidth × 1 (lines: 4)
        - checkRoundRect × 1 (lines: 145)
        - clear × 1 (lines: 107)
        - drawRoundedRect × 1 (lines: 147)
        - getGhostCanvas × 2 (lines: 357, 385)
        - getHudScale × 1 (lines: 154)
        - getOrCreate × 1 (lines: 78)
        - getRecordedBlobs × 2 (lines: 358, 386)
        - hdReferenceHeight × 1 (lines: 152)
        - hdReferenceWidth × 1 (lines: 151)
        - initGhost × 1 (lines: 132)
        - internalState × 2 (lines: 57, 394)
        - loadLogo × 2 (lines: 120, 389)
        - pause × 1 (lines: 383)
        - pauseRecording × 1 (lines: 343)
        - renderFloorNav × 1 (lines: 166)
        - renderFrame × 2 (lines: 179, 392)
        - renderMarketingBanner × 1 (lines: 175)
        - renderRoomLabel × 1 (lines: 162)
        - renderWatermark × 1 (lines: 158)
        - requestDeterministicFrame × 2 (lines: 70, 391)
        - resolveSourceCanvas × 2 (lines: 231, 393)
        - resume × 1 (lines: 384)
        - resumeRecording × 1 (lines: 350)
        - setFadeOpacity × 2 (lines: 375, 388)
        - setOpacity × 1 (lines: 94)
        - setSnapshot × 2 (lines: 360, 387)
        - startAnimationLoop × 2 (lines: 243, 390)
        - startRecording × 2 (lines: 255, 381)
        - stopRecording × 2 (lines: 315, 382)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TeaserRecorderHud.res`
- `src/systems/TeaserRecorderHud.res` (10 functions, fingerprint 181dd904bb826ca4d127c667db47d44e90e67b625104425cd9b50e075329fad9)
    - Grouped summary:
        - checkRoundRect × 1 (lines: 23)
        - drawRoundedRect × 1 (lines: 25)
        - drawRoundedRectCorners × 1 (lines: 234)
        - getHudScale × 1 (lines: 37)
        - hdReferenceHeight × 1 (lines: 21)
        - hdReferenceWidth × 1 (lines: 20)
        - renderFloorNav × 1 (lines: 154)
        - renderMarketingBanner × 1 (lines: 298)
        - renderRoomLabel × 1 (lines: 82)
        - renderWatermark × 1 (lines: 54)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TourTemplates.res`
- `src/systems/TourTemplates.res` (3 functions, fingerprint 987b79631cc8badba9b7dff1b00c386bf2c3aa5dd9e91d8f559fa51eb2903da0)
    - Grouped summary:
        - escapeHtml × 1 (lines: 10)
        - generateEmbedCodes × 1 (lines: 352)
        - generateExportIndex × 1 (lines: 353)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
