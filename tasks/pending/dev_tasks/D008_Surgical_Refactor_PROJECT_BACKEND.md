# Task D008: Surgical Refactor PROJECT BACKEND

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

- [ ] - **../../backend/src/services/project/import_upload.rs** (Metric: [Nesting: 2.40, Density: 0.04, Coupling: 0.01] | Drag: 3.74 | LOC: 541/300) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../backend/src/services/project/validate.rs** (Metric: [Nesting: 3.60, Density: 0.09, Coupling: 0.01] | Drag: 5.20 | LOC: 382/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D008/verification.json` (files at `_dev-system/tmp/D008/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D008/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/services/project/import_upload.rs`
- `backend/src/services/project/import_upload.rs` (17 functions, fingerprint 2265bbd956c25d40c7c935fc43b7925c21fc474ecb4cfca1c66c7150b594e2d8)
    - Grouped summary:
        - abort_session × 1 (lines: 342)
        - assemble_chunks × 1 (lines: 414)
        - chunk_path × 1 (lines: 55)
        - cleanup_expired × 1 (lines: 367)
        - complete_session × 1 (lines: 276)
        - completes_chunked_payload_and_reassembles_in_order × 1 (lines: 452)
        - expected_chunk_size × 1 (lines: 59)
        - init_session × 1 (lines: 102)
        - new × 1 (lines: 84)
        - next_expected_chunk × 1 (lines: 69)
        - normalize_chunk_size × 1 (lines: 397)
        - rejects_invalid_chunk_byte_size × 1 (lines: 515)
        - remove_session × 1 (lines: 347)
        - save_chunk × 1 (lines: 167)
        - status × 1 (lines: 252)
        - to_epoch_ms × 1 (lines: 439)
        - with_ttl × 1 (lines: 88)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `backend/src/services/project/validate.rs`
- `backend/src/services/project/validate.rs` (7 functions, fingerprint 5ec0bdf274b5486108957898508585e198f4022a7a17796c4f3d0f58e93ca130)
    - Grouped summary:
        - archive_contains_file × 1 (lines: 67)
        - extract_sanitized_filename × 1 (lines: 28)
        - get_scene_filename × 1 (lines: 71)
        - normalize_scene_key × 1 (lines: 6)
        - resolve_hotspot_target_id × 1 (lines: 78)
        - scene_id_or_fallback × 1 (lines: 18)
        - validate_and_clean_project × 1 (lines: 124)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
