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

- [ ] - **../../src/components/Sidebar/SidebarLogicHandler.res** (Metric: [Nesting: 4.20, Density: 0.06, Coupling: 0.07] | Drag: 5.27 | LOC: 563/300  🎯 Target: Function: `fileArray` (High Local Complexity (3.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D012/verification.json` (files at `_dev-system/tmp/D012/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D012/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/Sidebar/SidebarLogicHandler.res`
- `src/components/Sidebar/SidebarLogicHandler.res` (9 functions, fingerprint af591ed5e8a5a1e6f038f51b28e440568d7342304fb7eaf3c98cbe1a83e1aa28)
    - Grouped summary:
        - handleClearLinksWithUndo × 1 (lines: 429)
        - handleDeleteScene × 1 (lines: 294)
        - handleDeleteSceneWithUndo × 1 (lines: 358)
        - handleExport × 1 (lines: 500)
        - handleLoadProject × 1 (lines: 132)
        - handleUpload × 1 (lines: 87)
        - isMissingPanoramaFile × 1 (lines: 306)
        - performUpload × 1 (lines: 9)
        - repairRestoredState × 1 (lines: 313)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
