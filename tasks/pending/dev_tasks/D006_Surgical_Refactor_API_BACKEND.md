# Task D006: Surgical Refactor API BACKEND

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

- [ ] - **../../backend/src/api/project.rs** (Metric: [Nesting: 3.00, Density: 0.01, Coupling: 0.02] | Drag: 4.04 | LOC: 600/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D006/verification.json` (files at `_dev-system/tmp/D006/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D006/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/api/project.rs`
- `backend/src/api/project.rs` (19 functions, fingerprint 24cbe0bf56a3c04971e24a2f7c91b92a24d7329ed53820f14861894ec093716b)
    - Grouped summary:
        - calculate_path × 1 (lines: 482)
        - create_tour_package × 1 (lines: 530)
        - drop × 5 (lines: 98, 119, 285, 437, 556)
        - import_project × 1 (lines: 267)
        - import_project_abort × 1 (lines: 458)
        - import_project_chunk × 1 (lines: 352)
        - import_project_complete × 1 (lines: 410)
        - import_project_from_zip_path × 1 (lines: 213)
        - import_project_init × 1 (lines: 306)
        - import_project_status × 1 (lines: 384)
        - keep × 1 (lines: 114)
        - load_project × 1 (lines: 188)
        - new × 1 (lines: 110)
        - save_project × 1 (lines: 81)
        - validate_project × 1 (lines: 503)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
