# Task D007: Surgical Refactor SRC MIDDLEWARE BACKEND

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

- [ ] - **../../backend/src/middleware/rate_limiter.rs** (Metric: [Nesting: 3.60, Density: 0.04, Coupling: 0.02] | Drag: 4.66 | LOC: 343/300  ⚠️ Trigger: Drag above target (1.80) with file already at 343 LOC.) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D007/verification.json` (files at `_dev-system/tmp/D007/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D007/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/middleware/rate_limiter.rs`
- `backend/src/middleware/rate_limiter.rs` (13 functions, fingerprint 0e20bb6f4198a7b753b768168158f060725175243ffc58c57def7bbb28fe129b)
    - Grouped summary:
        - call × 1 (lines: 216)
        - create_config × 1 (lines: 132)
        - eq × 1 (lines: 30)
        - extract × 1 (lines: 88)
        - extract_ip × 1 (lines: 63)
        - extract_session × 1 (lines: 73)
        - hash × 1 (lines: 36)
        - is_critical_path × 1 (lines: 54)
        - new × 3 (lines: 48, 122, 172)
        - new_transform × 1 (lines: 191)
        - whitelisted_keys × 1 (lines: 102)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
