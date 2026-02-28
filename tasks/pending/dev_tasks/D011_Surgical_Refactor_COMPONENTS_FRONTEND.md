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

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/components/VisualPipeline.res** (Metric: [Nesting: 4.20, Density: 0.11, Coupling: 0.08] | Drag: 5.31 | LOC: 388/300  🎯 Target: Function: `make` (High Local Complexity (17.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D011/verification.json` (files at `_dev-system/tmp/D011/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D011/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/VisualPipeline.res`
- `src/components/VisualPipeline.res` (2 functions, fingerprint 3b5bf578976e0ae1d88321346e1ce3bcf990a1e6b5f27a9aac3d0fb6472b6537)
    - Grouped summary:
        - injectStyles × 1 (lines: 14)
        - make × 1 (lines: 19)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
