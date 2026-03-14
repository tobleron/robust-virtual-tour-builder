# Task D006: Surgical Refactor SERVICES PROJECT BACKEND

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

- [ ] - **../../backend/src/services/project/package_output.rs** (Metric: [Nesting: 2.40, Density: 0.05, Coupling: 0.02] | Drag: 3.75 | LOC: 466/300  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.) → Refactor in-place (keep near ~300 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D006_Surgical_Refactor_SERVICES_PROJECT_BACKEND/verification.json` (files at `_dev-system/tmp/D006_Surgical_Refactor_SERVICES_PROJECT_BACKEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D006_Surgical_Refactor_SERVICES_PROJECT_BACKEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/services/project/package_output.rs`
- `backend/src/services/project/package_output.rs` (12 functions, fingerprint 2f7dd26562ee7df68b4c7b19ed15897108a16ccc22be665e41464e5b275863f0)
    - Grouped summary:
        - export_html_minifier_cfg × 1 (lines: 11)
        - minify_export_html × 1 (lines: 31)
        - minify_export_html_reduces_markup_and_keeps_inline_runtime × 1 (lines: 437)
        - write_desktop_bundle × 1 (lines: 219)
        - write_desktop_support × 1 (lines: 361)
        - write_image_assets × 1 (lines: 114)
        - write_project_metadata × 1 (lines: 203)
        - write_root_launcher × 1 (lines: 35)
        - write_shared_assets × 1 (lines: 65)
        - write_supporting_files × 1 (lines: 191)
        - write_tour_htmls × 1 (lines: 153)
        - write_web_only_support × 1 (lines: 322)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
