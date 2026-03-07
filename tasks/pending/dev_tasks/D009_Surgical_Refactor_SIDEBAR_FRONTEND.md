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

- [ ] - **../../src/components/Sidebar/SidebarLogicHandler.res** (Metric: [Nesting: 4.80, Density: 0.15, Coupling: 0.11] | Drag: 5.99 | LOC: 393/300  🎯 Target: Function: `state` (High Local Complexity (9.5). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D009/verification.json` (files at `_dev-system/tmp/D009/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D009/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/Sidebar/SidebarLogicHandler.res`
- `src/components/Sidebar/SidebarLogicHandler.res` (12 functions, fingerprint d345f455c16d05e39796fedb6f0b8d99991f54b509baeb97e2395959bd459872)
    - Grouped summary:
        - delayMs × 1 (lines: 50)
        - exportProgressToastId × 1 (lines: 12)
        - getActiveSceneId × 1 (lines: 18)
        - handleClearLinksWithUndo × 1 (lines: 398)
        - handleDeleteScene × 1 (lines: 396)
        - handleDeleteSceneWithUndo × 1 (lines: 397)
        - handleExport × 1 (lines: 400)
        - handleLoadProject × 1 (lines: 134)
        - handleUpload × 1 (lines: 89)
        - isProjectViewerReady × 1 (lines: 23)
        - uploadProgressToastId × 1 (lines: 11)
        - waitForProjectReady × 1 (lines: 55)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
