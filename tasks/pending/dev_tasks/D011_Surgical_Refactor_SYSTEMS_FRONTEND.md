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

- [ ] - **../../src/systems/OperationLifecycle.res** (Metric: [Nesting: 3.00, Density: 0.22, Coupling: 0.03] | Drag: 4.28 | LOC: 379/300  🎯 Target: Function: `updateLoggerContext` (High Local Complexity (14.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D011/verification.json` (files at `_dev-system/tmp/D011/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D011/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/OperationLifecycle.res`
- `src/systems/OperationLifecycle.res` (19 functions, fingerprint be040c29c53ce43d2e200948a53503deca8e0ea78decd4fba4d36d8457f46a04)
    - Grouped summary:
        - cancel × 1 (lines: 341)
        - cancelCallbacks × 1 (lines: 53)
        - complete × 1 (lines: 253)
        - fail × 1 (lines: 297)
        - getOperation × 1 (lines: 116)
        - getOperations × 1 (lines: 120)
        - isActive × 1 (lines: 124)
        - isBusy × 1 (lines: 135)
        - listeners × 1 (lines: 52)
        - notifyListeners × 1 (lines: 57)
        - operations × 1 (lines: 51)
        - progress × 1 (lines: 218)
        - registerCancel × 1 (lines: 112)
        - reset × 1 (lines: 95)
        - start × 1 (lines: 156)
        - subscribe × 1 (lines: 102)
        - updateLoggerContext × 1 (lines: 62)
        - useIsBusy × 1 (lines: 422)
        - useOperations × 1 (lines: 409)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
