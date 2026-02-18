# Task D005: Surgical Refactor API BACKEND

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

- [ ] - **../../backend/src/api/project_logic.rs** (Metric: [Nesting: 3.60, Density: 0.07, Coupling: 0.03] | Drag: 4.72 | LOC: 495/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D005/verification.json` (files at `_dev-system/tmp/D005/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D005/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/api/project_logic.rs`
- `backend/src/api/project_logic.rs` (13 functions, fingerprint 3ade8537449931c38700d825f76779b33158d675ba88a35f894311bdef96913d)
    - Grouped summary:
        - collect_referenced_project_files × 1 (lines: 75)
        - collect_scene_file_references × 1 (lines: 59)
        - create_project_zip_sync × 1 (lines: 268)
        - extract_project_metadata_from_zip × 1 (lines: 100)
        - extract_sanitized_filename × 1 (lines: 14)
        - extract_zip_to_project_dir × 1 (lines: 147)
        - generate_project_summary × 1 (lines: 188)
        - is_active_inventory_entry × 1 (lines: 47)
        - list_available_files × 1 (lines: 126)
        - test_create_project_zip_sync_includes_inventory_active_scene_files × 1 (lines: 426)
        - test_extract_zip_path_traversal × 1 (lines: 364)
        - test_extract_zip_sanitizes_components × 1 (lines: 391)
        - validate_project_full_sync × 1 (lines: 328)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
