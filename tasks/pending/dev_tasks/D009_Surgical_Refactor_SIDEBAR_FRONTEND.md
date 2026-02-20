# Task D009: Surgical Refactor SIDEBAR FRONTEND

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

- [ ] - **../../src/components/Sidebar/SidebarLogic.res** (Metric: [Nesting: 4.20, Density: 0.11, Coupling: 0.09] | Drag: 5.33 | LOC: 379/300  🎯 Target: Function: `msg` (High Local Complexity (2.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D009/verification.json` (files at `_dev-system/tmp/D009/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D009/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/Sidebar/SidebarLogic.res`
- `src/components/Sidebar/SidebarLogic.res` (8 functions, fingerprint 1e010ccb9a80ad92e78d4cff5e4459e29a646bd574a07cbb55f24bc3cb9c1232)
    - Grouped summary:
        - getProjectData × 1 (lines: 277)
        - handleDeleteScene × 1 (lines: 281)
        - handleExport × 1 (lines: 293)
        - handleLoadProject × 1 (lines: 168)
        - handleUpload × 1 (lines: 124)
        - lastPct × 1 (lines: 29)
        - performUpload × 1 (lines: 66)
        - updateProgress × 1 (lines: 31)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
