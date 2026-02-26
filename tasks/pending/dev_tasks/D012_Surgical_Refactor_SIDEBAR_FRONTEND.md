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

- [ ] - **../../src/components/Sidebar/SidebarLogicHandler.res** (Metric: [Nesting: 4.80, Density: 0.15, Coupling: 0.04] | Drag: 6.06 | LOC: 1037/300  🎯 Target: Function: `parseExportMetrics` (High Local Complexity (16.5). Logic heavy.)) → 🏗️ Split into 4 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D012/verification.json` (files at `_dev-system/tmp/D012/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D012/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/Sidebar/SidebarLogicHandler.res`
- `src/components/Sidebar/SidebarLogicHandler.res` (13 functions, fingerprint 735dad7fd2cf7ec2bc53d5c218af7eeb324908ad4e072ee52b55e82799e6dced)
    - Grouped summary:
        - exportProgressToastId × 1 (lines: 10)
        - handleClearLinksWithUndo × 1 (lines: 738)
        - handleDeleteScene × 1 (lines: 602)
        - handleDeleteSceneWithUndo × 1 (lines: 667)
        - handleExport × 1 (lines: 809)
        - handleLoadProject × 1 (lines: 440)
        - handleUpload × 1 (lines: 400)
        - isMissingPanoramaFile × 1 (lines: 614)
        - parseExportMetrics × 1 (lines: 68)
        - parseProcessingMetrics × 1 (lines: 23)
        - performUpload × 1 (lines: 123)
        - repairRestoredState × 1 (lines: 621)
        - uploadProgressToastId × 1 (lines: 9)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
