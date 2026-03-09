# Task D022: Surgical Refactor SYSTEMS SCENE FRONTEND

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

- [ ] - **../../src/systems/Scene/SceneLoader.res** (Metric: [Nesting: 2.40, Density: 0.11, Coupling: 0.09] | Drag: 3.57 | LOC: 266/300  ⚠️ Trigger: Drag above target (1.80) with file already at 266 LOC.  🎯 Target: Function: `cleanupLoadTimeout` (High Local Complexity (3.0). Logic heavy.)) → Refactor in-place

- [ ] - **../../src/systems/Scene/SceneTransition.res** (Metric: [Nesting: 2.40, Density: 0.07, Coupling: 0.08] | Drag: 3.47 | LOC: 305/300  ⚠️ Trigger: Drag above target (1.80) with file already at 305 LOC.) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D022/verification.json` (files at `_dev-system/tmp/D022/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D022/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Scene/SceneLoader.res`
- `src/systems/Scene/SceneLoader.res` (12 functions, fingerprint 17ded3eae51d0476e77c66578aab57a0b45471fc828991c06278acaaa2a98476)
    - Grouped summary:
        - backgroundViewerConfig × 1 (lines: 19)
        - blankPanorama × 1 (lines: 18)
        - cleanupLoadTimeout × 1 (lines: 61)
        - currentLoadTimeout × 1 (lines: 59)
        - ensureBackgroundViewer × 1 (lines: 21)
        - findReusableInstance × 1 (lines: 47)
        - isStaleTask × 1 (lines: 54)
        - loadNewScene × 1 (lines: 70)
        - loadStartTime × 1 (lines: 14)
        - onSceneError × 1 (lines: 53)
        - onSceneLoad × 1 (lines: 52)
        - toPathRequest × 1 (lines: 37)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/Scene/SceneTransition.res`
- `src/systems/Scene/SceneTransition.res` (18 functions, fingerprint 88dcc48992bebf51dbf4cbfbaa97be63a958726039afa3dd9ba22366dab467db)
    - Grouped summary:
        - assignGlobalViewer × 1 (lines: 145)
        - cleanupSnapshotOverlay × 1 (lines: 248)
        - cleanupViewerInstance × 1 (lines: 221)
        - clearHotspotLines × 1 (lines: 147)
        - completeSupervisorTask × 1 (lines: 90)
        - completeSwapTransition × 1 (lines: 56)
        - finalizeSwap × 1 (lines: 97)
        - lastNoInactiveViewerWarnAt × 1 (lines: 272)
        - logNoInactiveViewerFallback × 1 (lines: 274)
        - maxSwapFinalizeAttempts × 1 (lines: 12)
        - maxSwapRetries × 1 (lines: 270)
        - noInactiveViewerWarnCooldownMs × 1 (lines: 271)
        - performSwap × 1 (lines: 284)
        - scheduleCleanup × 1 (lines: 261)
        - swapFinalizeRetryMs × 1 (lines: 11)
        - syncSceneCoupledState × 1 (lines: 14)
        - updateDomTransitions × 1 (lines: 169)
        - updateGlobalStateAndViewer × 1 (lines: 153)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
