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

- [ ] - **../../src/systems/TeaserLogic.res** (Metric: [Nesting: 2.40, Density: 0.12, Coupling: 0.09] | Drag: 3.52 | LOC: 441/300  🎯 Target: Function: `signalIsAborted` (High Local Complexity (2.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


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
- `src/systems/TeaserLogic.res` (11 functions, fingerprint 65ecde93610e50a33b1394a6e4b31ca5d2f76c42046b30d3bf99d48be0b65f19)
    - Grouped summary:
        - canvasHeight × 1 (lines: 8)
        - canvasWidth × 1 (lines: 7)
        - centerViewerAtWaypointStart × 1 (lines: 69)
        - check × 1 (lines: 145)
        - finalizeTeaser × 1 (lines: 106)
        - logoState × 1 (lines: 141)
        - readHeadlessMotionProfile × 1 (lines: 30)
        - resolveTeaserStartView × 1 (lines: 42)
        - safeName × 1 (lines: 154)
        - signalIsAborted × 1 (lines: 93)
        - throwIfCancelled × 1 (lines: 99)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
