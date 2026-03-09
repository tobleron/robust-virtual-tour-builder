# Task D018: Surgical Refactor SRC COMPONENTS FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 1.80 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../src/components/VisualPipelineHub.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 46)) → Refactor in-place

- [ ] - **../../src/components/VisualPipelineLayout.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 85)) → Refactor in-place

- [ ] - **../../src/components/VisualPipelineRouter.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 90)) → Refactor in-place


### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/components/HotspotManager.res** (Metric: [Nesting: 3.00, Density: 0.36, Coupling: 0.11] | Drag: 4.39 | LOC: 270/300  ⚠️ Trigger: Drag above target (1.80) with file already at 270 LOC.  🎯 Target: Function: `isReturnLink` (High Local Complexity (5.0). Logic heavy.)) → Refactor in-place

- [ ] - **../../src/components/LabelMenu.res** (Metric: [Nesting: 2.40, Density: 0.11, Coupling: 0.06] | Drag: 3.57 | LOC: 521/300  🎯 Target: Function: `bulkDeleteBlockReason` (High Local Complexity (18.5). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/components/PreviewArrow.res** (Metric: [Nesting: 3.60, Density: 0.14, Coupling: 0.08] | Drag: 4.83 | LOC: 419/300  🎯 Target: Function: `handleMainClick` (High Local Complexity (7.1). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/components/SceneList.res** (Metric: [Nesting: 3.60, Density: 0.11, Coupling: 0.08] | Drag: 4.78 | LOC: 352/300  ⚠️ Trigger: Drag above target (1.80) with file already at 352 LOC.  🎯 Target: Function: `make` (High Local Complexity (23.8). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/components/UploadReport.res** (Metric: [Nesting: 4.20, Density: 0.15, Coupling: 0.08] | Drag: 5.37 | LOC: 295/300  ⚠️ Trigger: Drag above target (1.80) with file already at 295 LOC.  🎯 Target: Function: `state` (High Local Complexity (5.0). Logic heavy.)) → Refactor in-place

- [ ] - **../../src/components/VisualPipeline.res** (Metric: [Nesting: 4.20, Density: 0.08, Coupling: 0.04] | Drag: 5.28 | LOC: 1011/300  🎯 Target: Function: `make` (High Local Complexity (12.7). Logic heavy.)) → 🏗️ Split into 4 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D018/verification.json` (files at `_dev-system/tmp/D018/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D018/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/HotspotManager.res`
- `src/components/HotspotManager.res` (9 functions, fingerprint 1304b413965e3d33141b7c2509e80d39e8e791948abd759a6894ea877288876e)
    - Grouped summary:
        - createHotspotConfig × 1 (lines: 18)
        - findIndicesByIds × 1 (lines: 235)
        - handleAddHotspot × 1 (lines: 180)
        - handleCommitHotspotMove × 1 (lines: 296)
        - handleDeleteHotspot × 1 (lines: 194)
        - handleUpdateHotspotMetadata × 1 (lines: 221)
        - handleUpdateHotspotTarget × 1 (lines: 252)
        - handleUpdateSceneMetadata × 1 (lines: 208)
        - syncHotspots × 1 (lines: 133)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/components/LabelMenu.res`
- `src/components/LabelMenu.res` (6 functions, fingerprint 2dad5c9f37f8f4ae2a73665da42dc7a089e3022e6eee051ffdd562322368a87f)
    - Grouped summary:
        - bulkDeleteBlockReason × 1 (lines: 14)
        - isUntaggedScene × 1 (lines: 9)
        - make × 1 (lines: 89)
        - notifyInfo × 1 (lines: 46)
        - notifySuccess × 1 (lines: 74)
        - notifyWarning × 1 (lines: 60)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/components/PreviewArrow.res`
- `src/components/PreviewArrow.res` (2 functions, fingerprint a619e1ae65b82326ed53b44fc3e2fcc34a9a38f267ed19e494300ef96825c125)
    - Grouped summary:
        - calculateNavParams × 1 (lines: 4)
        - make × 1 (lines: 8)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/components/SceneList.res`
- `src/components/SceneList.res` (2 functions, fingerprint 899e006811656a8f8722575921adc84f24f1d58909024f0210ba33dd1aa6be40)
    - Grouped summary:
        - make × 2 (lines: 9, 37)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/components/UploadReport.res`
- `src/components/UploadReport.res` (5 functions, fingerprint 6583ff76b2d3e8024d10024dedf47b2376fb0f316317d77d6f4d1b8501f7862c)
    - Grouped summary:
        - renderGroup × 1 (lines: 15)
        - show × 1 (lines: 23)
        - showFromProjectData × 1 (lines: 272)
        - showValidationSummary × 1 (lines: 189)
        - validationReportWrapperDecoder × 1 (lines: 11)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/components/VisualPipeline.res`
- `src/components/VisualPipeline.res` (5 functions, fingerprint 7781637d4aa247c0673528ad54e0d04673fc52d1bea02b4edd480e4f51075b10)
    - Grouped summary:
        - branchRisePx × 1 (lines: 14)
        - branchYOffsetForRank × 1 (lines: 15)
        - injectStyles × 1 (lines: 24)
        - make × 1 (lines: 29)
        - nodePitchPx × 1 (lines: 13)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
