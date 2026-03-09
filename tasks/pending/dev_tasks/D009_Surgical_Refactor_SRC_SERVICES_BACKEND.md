# Task D009: Surgical Refactor SRC SERVICES BACKEND

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

- [ ] - **../../backend/src/services/upload_quota.rs** (Metric: [Nesting: 2.40, Density: 0.05, Coupling: 0.02] | Drag: 3.45 | LOC: 326/300  ⚠️ Trigger: Drag above target (1.80) with file already at 326 LOC.) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D009/verification.json` (files at `_dev-system/tmp/D009/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D009/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/services/upload_quota.rs`
- `backend/src/services/upload_quota.rs` (13 functions, fingerprint f001259d11524a4fcc99456f703d08cc03357eacc882a74507589c6e148be6e3)
    - Grouped summary:
        - add_upload × 1 (lines: 124)
        - check_disk_space × 1 (lines: 271)
        - cleanup_old × 1 (lines: 135)
        - count_in_window × 1 (lines: 128)
        - default × 1 (lines: 31)
        - env_u64 × 1 (lines: 68)
        - env_usize × 1 (lines: 60)
        - from_env × 1 (lines: 77)
        - get_stats × 1 (lines: 305)
        - new × 2 (lines: 118, 149)
        - try_register_upload × 1 (lines: 159)
        - unregister_upload × 1 (lines: 248)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
