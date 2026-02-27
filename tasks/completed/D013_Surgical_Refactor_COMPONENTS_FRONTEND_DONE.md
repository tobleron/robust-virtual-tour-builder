# Task D013: Surgical Refactor COMPONENTS FRONTEND

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

- [ ] - **../../src/components/VisualPipeline.res** (Metric: [Nesting: 3.00, Density: 0.12, Coupling: 0.08] | Drag: 4.13 | LOC: 453/300  🎯 Target: Function: `isAutoForward` (High Local Complexity (8.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D013/verification.json` (files at `_dev-system/tmp/D013/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D013/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/VisualPipeline.res`
- `src/components/VisualPipeline.res` (3 functions, fingerprint a4fa5e13bb22904755df6cf1c0136e87b087ee6a27390f16123079f0c155d98a)
    - Grouped summary:
        - injectStyles × 1 (lines: 6)
        - make × 2 (lines: 23, 163)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
