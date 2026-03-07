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

- [ ] - **../../backend/src/services/project/package.rs** (Metric: [Nesting: 3.00, Density: 0.05, Coupling: 0.02] | Drag: 4.41 | LOC: 378/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D008/verification.json` (files at `_dev-system/tmp/D008/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D008/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/services/project/package.rs`
- `backend/src/services/project/package.rs` (9 functions, fingerprint cd2bc06d5a4a57e8752b4c38ecbe912e94ffaeaf10cb2731d161777dfc2418a2)
    - Grouped summary:
        - build_desktop_blob_html × 1 (lines: 63)
        - create_desktop_readme × 1 (lines: 51)
        - create_root_index × 1 (lines: 43)
        - create_tour_package × 1 (lines: 72)
        - create_web_only_deployment_readme × 1 (lines: 47)
        - rewrite_tour_html_for_subfolder × 1 (lines: 55)
        - rewrite_web_only_index_html × 1 (lines: 59)
        - target_dimensions × 1 (lines: 30)
        - write_zip_file × 1 (lines: 34)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
