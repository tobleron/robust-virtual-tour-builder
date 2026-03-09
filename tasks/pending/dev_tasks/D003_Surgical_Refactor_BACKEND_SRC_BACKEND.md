# Task D003: Surgical Refactor BACKEND SRC BACKEND

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

- [ ] - **../../backend/src/auth.rs** (Metric: [Nesting: 2.40, Density: 0.04, Coupling: 0.03] | Drag: 3.44 | LOC: 452/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D003/verification.json` (files at `_dev-system/tmp/D003/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D003/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/auth.rs`
- `backend/src/auth.rs` (19 functions, fingerprint 98c5a1f4815f33bd5e25bac237267c9d8ce58832da8e7327690dd359f4fa8a6a)
    - Grouped summary:
        - attach_headless_user × 1 (lines: 368)
        - attach_user_to_request × 1 (lines: 305)
        - call × 2 (lines: 231, 274)
        - decode_token × 1 (lines: 135)
        - encode_token × 1 (lines: 112)
        - extract_token × 1 (lines: 290)
        - google_callback × 1 (lines: 92)
        - google_login × 1 (lines: 71)
        - headless_token × 1 (lines: 347)
        - headless_user_metadata × 1 (lines: 351)
        - is_headless_token × 1 (lines: 361)
        - is_step_up_verified × 1 (lines: 149)
        - new × 1 (lines: 35)
        - new_transform × 2 (lines: 187, 208)
        - process_authentication × 1 (lines: 389)
        - require_step_up_verified × 1 (lines: 159)
        - test_token_encode_decode × 1 (lines: 440)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
