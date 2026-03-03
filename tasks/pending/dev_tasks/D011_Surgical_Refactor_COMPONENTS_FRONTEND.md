# Task D011: Surgical Refactor COMPONENTS FRONTEND

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

- [ ] - **../../src/components/VisualPipelineLayout.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 88)) → Refactor in-place

- [ ] - **../../src/components/VisualPipelineRouter.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 92)) → Refactor in-place


### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/components/PreviewArrow.res** (Metric: [Nesting: 3.60, Density: 0.12, Coupling: 0.08] | Drag: 4.82 | LOC: 410/300  🎯 Target: Function: `handleMainClick` (High Local Complexity (7.1). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/components/VisualPipeline.res** (Metric: [Nesting: 4.20, Density: 0.09, Coupling: 0.04] | Drag: 5.29 | LOC: 883/300  🎯 Target: Function: `parentByScene` (High Local Complexity (12.4). Logic heavy.)) → 🏗️ Split into 3 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D011/verification.json` (files at `_dev-system/tmp/D011/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D011/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/PreviewArrow.res`
- `src/components/PreviewArrow.res` (2 functions, fingerprint a619e1ae65b82326ed53b44fc3e2fcc34a9a38f267ed19e494300ef96825c125)
    - Grouped summary:
        - calculateNavParams × 1 (lines: 4)
        - make × 1 (lines: 8)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/components/VisualPipeline.res`
- `src/components/VisualPipeline.res` (5 functions, fingerprint 7781637d4aa247c0673528ad54e0d04673fc52d1bea02b4edd480e4f51075b10)
    - Grouped summary:
        - branchRisePx × 1 (lines: 14)
        - branchYOffsetForRank × 1 (lines: 15)
        - injectStyles × 1 (lines: 20)
        - make × 1 (lines: 25)
        - nodePitchPx × 1 (lines: 13)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
