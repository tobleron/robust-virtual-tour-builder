# Task D018: Surgical Refactor API BACKEND

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

- [ ] - **../../backend/src/api/project.rs** (Metric: [Nesting: 3.00, Density: 0.03, Coupling: 0.03] | Drag: 4.06 | LOC: 496/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D018/verification.json` (files at `_dev-system/tmp/D018/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D018/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/api/project.rs`
- `backend/src/api/project.rs` (18 functions, fingerprint 81b5df6bf84fd6514ebefa10e987e646d4909917e56fad7f095c583c02c8a140)
    - Grouped summary:
        - calculate_path × 1 (lines: 378)
        - cleanup_backend_cache × 1 (lines: 343)
        - count_hotspots × 1 (lines: 46)
        - create_tour_package × 1 (lines: 426)
        - drop × 3 (lines: 118, 139, 452)
        - keep × 1 (lines: 134)
        - list_dashboard_projects × 1 (lines: 271)
        - load_dashboard_project × 1 (lines: 324)
        - load_project × 1 (lines: 208)
        - new × 1 (lines: 130)
        - read_snapshot × 1 (lines: 73)
        - save_project × 1 (lines: 101)
        - scene_count × 1 (lines: 65)
        - sync_snapshot × 1 (lines: 236)
        - validate_project × 1 (lines: 399)
        - validate_snapshot_project × 1 (lines: 80)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
