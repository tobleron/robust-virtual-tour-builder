# Task D001: Surgical Refactor SRC API BACKEND

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

- [ ] - **../../backend/src/api/project_snapshot.rs** (Metric: [Nesting: 2.40, Density: 0.01, Coupling: 0.02] | Drag: 3.45 | LOC: 403/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.) → Refactor in-place (keep near ~300 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D001_Surgical_Refactor_SRC_API_BACKEND/verification.json` (files at `_dev-system/tmp/D001_Surgical_Refactor_SRC_API_BACKEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D001_Surgical_Refactor_SRC_API_BACKEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/api/project_snapshot.rs`
- `backend/src/api/project_snapshot.rs` (19 functions, fingerprint 9b1922a2b48be8e1edfb0978dc497bb6fa63a44f3a1f23076002f2ac96e70552)
    - Grouped summary:
        - count_hotspots × 1 (lines: 67)
        - default_snapshot_origin × 1 (lines: 12)
        - list_project_snapshots × 1 (lines: 326)
        - load_project_snapshot × 1 (lines: 347)
        - load_snapshot_history × 1 (lines: 124)
        - load_snapshot_history_files × 1 (lines: 134)
        - persist_snapshot_history × 1 (lines: 169)
        - persist_snapshot_history_upgrades_auto_origin_for_identical_manual_save × 1 (lines: 225)
        - project_tour_name × 1 (lines: 94)
        - prune_snapshot_history × 1 (lines: 160)
        - read_snapshot × 1 (lines: 264)
        - restore_project_snapshot × 1 (lines: 376)
        - scene_count × 1 (lines: 86)
        - snapshot_content_hash × 1 (lines: 106)
        - snapshot_history_dir × 1 (lines: 102)
        - snapshot_item_from_envelope × 1 (lines: 250)
        - sync_snapshot × 1 (lines: 290)
        - validate_snapshot_project × 1 (lines: 271)
        - write_current_snapshot × 1 (lines: 114)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
