# Task D012: Surgical Refactor SIDEBAR FRONTEND

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

- [ ] - **../../src/components/Sidebar/SidebarLogicHandler.res** (Metric: [Nesting: 4.20, Density: 0.09, Coupling: 0.09] | Drag: 5.31 | LOC: 376/300  🎯 Target: Function: `msg` (High Local Complexity (2.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D012/verification.json` (files at `_dev-system/tmp/D012/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D012/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/Sidebar/SidebarLogicHandler.res`
- `src/components/Sidebar/SidebarLogicHandler.res` (5 functions, fingerprint 7e869842e215a066722def803cb055f2d0ecde32b1ef51cd66e5975119b0d72c)
    - Grouped summary:
        - handleDeleteScene × 1 (lines: 274)
        - handleExport × 1 (lines: 286)
        - handleLoadProject × 1 (lines: 112)
        - handleUpload × 1 (lines: 67)
        - performUpload × 1 (lines: 9)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
