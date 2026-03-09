# Task D019: Surgical Refactor COMPONENTS SIDEBAR FRONTEND

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

- [ ] - **../../src/components/Sidebar/SidebarActions.res** (Metric: [Nesting: 7.80, Density: 0.19, Coupling: 0.06] | Drag: 9.01 | LOC: 377/300  🎯 Target: Function: `onCancel` (High Local Complexity (3.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/components/Sidebar/SidebarExportLogic.res** (Metric: [Nesting: 4.80, Density: 0.20, Coupling: 0.08] | Drag: 6.37 | LOC: 349/300  ⚠️ Trigger: Drag above target (1.80) with file already at 349 LOC.  🎯 Target: Function: `publishProjectData` (High Local Complexity (6.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/components/Sidebar/SidebarLogicHandler.res** (Metric: [Nesting: 4.80, Density: 0.15, Coupling: 0.11] | Drag: 5.99 | LOC: 393/300  🎯 Target: Function: `state` (High Local Complexity (9.5). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/components/Sidebar/SidebarUploadLogic.res** (Metric: [Nesting: 4.80, Density: 0.23, Coupling: 0.08] | Drag: 6.41 | LOC: 318/300  ⚠️ Trigger: Drag above target (1.80) with file already at 318 LOC.  🎯 Target: Function: `utilizationFactor` (High Local Complexity (4.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/components/Sidebar/UseSidebarProcessing.res** (Metric: [Nesting: 2.40, Density: 0.01, Coupling: 0.07] | Drag: 3.43 | LOC: 431/300  🎯 Target: Function: `expectedTourName` (High Local Complexity (1.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D019/verification.json` (files at `_dev-system/tmp/D019/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D019/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/Sidebar/SidebarActions.res`
- `src/components/Sidebar/SidebarActions.res` (1 functions, fingerprint 43879b63c2121d67cc9dc3853bd9f00fd8b6a7223065a530a1e77f9c0cbfd4a1)
    - Grouped summary:
        - make × 1 (lines: 9)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/components/Sidebar/SidebarExportLogic.res`
- `src/components/Sidebar/SidebarExportLogic.res` (2 functions, fingerprint 3f6be5471a03ecbd4aadec87df8a7a66a61e03dd1b1f7d549e68ac5dd9d56537)
    - Grouped summary:
        - handleExport × 1 (lines: 13)
        - profileToKey × 1 (lines: 5)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
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
### Pre-split snapshot for `src/components/Sidebar/SidebarUploadLogic.res`
- `src/components/Sidebar/SidebarUploadLogic.res` (3 functions, fingerprint 1528b1775c4ea538ea03c0fb3aa6932089aae9f3920c0c1d88487aced9b5a1c9)
    - Grouped summary:
        - parseExportMetrics × 1 (lines: 11)
        - parseProcessingMetrics × 1 (lines: 8)
        - performUpload × 1 (lines: 14)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/components/Sidebar/UseSidebarProcessing.res`
- `src/components/Sidebar/UseSidebarProcessing.res` (5 functions, fingerprint c6dc7c69ad526d25b44022da03494c811819af17f8eb47041bca9f6ae9d0685d)
    - Grouped summary:
        - handleSave × 1 (lines: 349)
        - localAssetCount × 1 (lines: 278)
        - saveToServer × 1 (lines: 295)
        - useProcessingState × 1 (lines: 40)
        - useTourNameSync × 1 (lines: 5)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
