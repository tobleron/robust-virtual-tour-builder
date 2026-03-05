# Task D007: Surgical Refactor SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/OperationLifecycle.res** (Metric: [Nesting: 3.60, Density: 0.21, Coupling: 0.03] | Drag: 4.93 | LOC: 404/300  🎯 Target: Function: `ttlMsForType` (High Local Complexity (7.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/ProjectSystem.res** (Metric: [Nesting: 1.80, Density: 0.05, Coupling: 0.10] | Drag: 2.85 | LOC: 420/300  🎯 Target: Function: `notifyProjectValidationWarnings` (High Local Complexity (3.5). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/Simulation.res** (Metric: [Nesting: 7.20, Density: 0.25, Coupling: 0.08] | Drag: 8.47 | LOC: 383/300  🎯 Target: Function: `make` (High Local Complexity (9.1). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/TeaserRecorderHud.res** (Metric: [Nesting: 5.40, Density: 0.27, Coupling: 0.03] | Drag: 6.71 | LOC: 457/300  🎯 Target: Function: `clampCorner` (High Local Complexity (4.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D007/verification.json` (files at `_dev-system/tmp/D007/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D007/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

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
- `src/systems/ProjectSystem.res` (11 functions, fingerprint d2a1a7bdd24a590d4b65025c69d448bbce92c387eb2abcdac20fc07e734a2569)
    - Grouped summary:
        - createSavePackage × 1 (lines: 303)
        - encodeProjectFromState × 1 (lines: 27)
        - encodeValidationReport × 1 (lines: 116)
        - loadProjectZip × 1 (lines: 218)
        - mergeValidationReport × 1 (lines: 113)
        - notifyProjectValidationWarnings × 1 (lines: 44)
        - processLoadedProjectData × 1 (lines: 127)
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
