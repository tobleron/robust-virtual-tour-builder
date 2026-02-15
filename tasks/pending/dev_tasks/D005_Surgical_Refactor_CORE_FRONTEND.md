# Task D005: Surgical Refactor CORE FRONTEND

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
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions. 🏗️ ARCHITECTURAL TARGET: Split into exactly 2 cohesive modules to respect the Read Tax (avg 300 LOC/module).

- [ ] - **../../src/core/ReducerModules.res** (Metric: [Nesting: 5.40, Density: 0.31, Coupling: 0.08] | Drag: 6.71 | LOC: 378/300  🎯 Target: Function: `finalState` (High Local Complexity (2.0). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D005/verification.json` (files at `_dev-system/tmp/D005/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D005/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/core/ReducerModules.res`
- `src/core/ReducerModules.res` (19 functions, fingerprint 3754ee13e6cb99ee7b3bd930493e64da3945d934077ac074aafd06e2f3813c85)
    - Grouped summary:
        - handleAddScenes × 1 (lines: 28)
        - handleApplyLazyRename × 1 (lines: 58)
        - handleDeleteScene × 1 (lines: 32)
        - handleReorderScenes × 1 (lines: 36)
        - handleSetActiveScene × 1 (lines: 40)
        - handleSyncSceneNames × 1 (lines: 54)
        - handleUpdateSceneMetadata × 1 (lines: 50)
        - reduce × 8 (lines: 62, 79, 122, 159, 189, 259, 312, 346)
        - updateBackgroundTask × 1 (lines: 22)
        - updateInteractive × 1 (lines: 7)
        - updateNavigation × 1 (lines: 18)
        - updateUiMode × 1 (lines: 14)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
