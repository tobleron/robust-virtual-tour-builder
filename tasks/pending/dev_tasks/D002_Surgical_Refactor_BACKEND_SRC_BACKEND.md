# Task D002: Surgical Refactor BACKEND SRC BACKEND

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

- [ ] - **../../backend/src/main.rs** (Metric: [Nesting: 3.00, Density: 0.04, Coupling: 0.06] | Drag: 4.04 | LOC: 447/300  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.) → Refactor in-place (keep near ~300 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D002_Surgical_Refactor_BACKEND_SRC_BACKEND/verification.json` (files at `_dev-system/tmp/D002_Surgical_Refactor_BACKEND_SRC_BACKEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D002_Surgical_Refactor_BACKEND_SRC_BACKEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/main.rs`
- `backend/src/main.rs` (11 functions, fingerprint 07058063f3c73ed3cc4e78bf1aac2837c10c8678936ca6825ba2acee209d26f5)
    - Grouped summary:
        - builder_dist_root × 1 (lines: 53)
        - detects_hashed_static_and_assets_paths × 1 (lines: 119)
        - dist_root × 1 (lines: 61)
        - from_env × 1 (lines: 40)
        - health_check × 1 (lines: 133)
        - ignores_non_hashed_or_non_static_paths × 1 (lines: 126)
        - is_hashed_static_asset × 1 (lines: 93)
        - main × 1 (lines: 153)
        - portal_dist_root × 1 (lines: 57)
        - wait_for_shutdown_signal × 2 (lines: 70, 88)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
