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

- [ ] - **../../src/systems/OperationLifecycle.res** (Metric: [Nesting: 3.60, Density: 0.21, Coupling: 0.03] | Drag: 4.93 | LOC: 401/300  🎯 Target: Function: `ttlMsForType` (High Local Complexity (7.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D007/verification.json` (files at `_dev-system/tmp/D007/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D007/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/OperationLifecycle.res`
- `src/systems/OperationLifecycle.res` (30 functions, fingerprint 880f85b7aa4348a6bf7de207fbf48640013017efa496058736f409353bb93dbe)
    - Grouped summary:
        - activeCount × 1 (lines: 50)
        - cancel × 1 (lines: 361)
        - cancelCallbacks × 1 (lines: 14)
        - cleanupTerminalOperation × 1 (lines: 55)
        - complete × 1 (lines: 276)
        - completedTotal × 1 (lines: 15)
        - ensureSweepInterval × 1 (lines: 99)
        - fail × 1 (lines: 319)
        - getOperation × 1 (lines: 142)
        - getOperations × 1 (lines: 146)
        - getStats × 1 (lines: 425)
        - isActive × 1 (lines: 150)
        - isBusy × 1 (lines: 161)
        - leakedTotal × 1 (lines: 16)
        - listeners × 1 (lines: 13)
        - notifyListeners × 1 (lines: 35)
        - operations × 1 (lines: 12)
        - progress × 1 (lines: 241)
        - registerCancel × 1 (lines: 138)
        - reset × 1 (lines: 110)
        - start × 1 (lines: 179)
        - subscribe × 1 (lines: 128)
        - sweepExpiredOperations × 1 (lines: 62)
        - sweepIntervalId × 1 (lines: 17)
        - timeoutTtlExceeded × 1 (lines: 20)
        - ttlMsForType × 1 (lines: 22)
        - ttlSweepMs × 1 (lines: 19)
        - updateLoggerContext × 1 (lines: 40)
        - useIsBusy × 1 (lines: 448)
        - useOperations × 1 (lines: 435)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
