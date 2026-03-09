# Task D011: Surgical Refactor COMPONENTS SCENELIST FRONTEND

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

- [ ] - **../../src/components/SceneList/SceneItem.res** (Metric: [Nesting: 5.40, Density: 0.26, Coupling: 0.10] | Drag: 6.73 | LOC: 363/300  ⚠️ Trigger: Drag above target (1.80) with file already at 363 LOC.  🎯 Target: Function: `qualityScore` (High Local Complexity (5.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D011/verification.json` (files at `_dev-system/tmp/D011/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D011/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/SceneList/SceneItem.res`
- `src/components/SceneList/SceneItem.res` (2 functions, fingerprint 695a5200b1b4a3a6dc2dd91c1607835709cfb9734fb42c416c7491888f56bfb9)
    - Grouped summary:
        - getThumbUrl × 1 (lines: 6)
        - make × 1 (lines: 22)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
