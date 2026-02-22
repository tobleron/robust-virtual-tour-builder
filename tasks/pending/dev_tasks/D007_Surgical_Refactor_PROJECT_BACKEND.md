# Task D007: Surgical Refactor PROJECT BACKEND

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

- [ ] - **../../backend/src/services/project/import_upload.rs** (Metric: [Nesting: 2.40, Density: 0.05, Coupling: 0.02] | Drag: 3.75 | LOC: 459/300) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../backend/src/services/project/package.rs** (Metric: [Nesting: 3.00, Density: 0.03, Coupling: 0.01] | Drag: 4.42 | LOC: 481/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D007/verification.json` (files at `_dev-system/tmp/D007/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D007/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/services/project/import_upload.rs`
- `backend/src/services/project/import_upload.rs` (11 functions, fingerprint 668216651389dd6bb5fff3e8e55321f5893c5018a45659afbb042ffc7b664d52)
    - Grouped summary:
        - abort_session × 1 (lines: 309)
        - cleanup_expired × 1 (lines: 334)
        - complete_session × 1 (lines: 243)
        - completes_chunked_payload_and_reassembles_in_order × 1 (lines: 370)
        - init_session × 1 (lines: 69)
        - new × 1 (lines: 51)
        - rejects_invalid_chunk_byte_size × 1 (lines: 433)
        - remove_session × 1 (lines: 314)
        - save_chunk × 1 (lines: 134)
        - status × 1 (lines: 219)
        - with_ttl × 1 (lines: 55)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `backend/src/services/project/package.rs`
- `backend/src/services/project/package.rs` (12 functions, fingerprint 5c407ac13e17a0cfa3334fd80300caefab45f4b0ae69737bf0b1d7ae877a9fcd)
    - Grouped summary:
        - build_desktop_blob_html × 1 (lines: 188)
        - create_desktop_readme × 1 (lines: 135)
        - create_root_index × 1 (lines: 67)
        - create_tour_package × 1 (lines: 223)
        - create_web_only_deployment_readme × 1 (lines: 101)
        - data_uri_for_bytes × 1 (lines: 184)
        - infer_mime_from_filename × 1 (lines: 171)
        - require_scene_policy × 1 (lines: 51)
        - rewrite_tour_html_for_subfolder × 1 (lines: 154)
        - rewrite_web_only_index_html × 1 (lines: 167)
        - target_dimensions × 1 (lines: 29)
        - write_zip_file × 1 (lines: 40)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
