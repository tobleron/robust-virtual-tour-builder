# Task D003: Surgical Refactor SRC BACKEND

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
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions. 🏗️ ARCHITECTURAL TARGET: Split into exactly 2 cohesive modules to respect the Read Tax (avg 300 LOC/module).

- [ ] - **../../backend/src/models.rs** (Metric: [Nesting: 1.80, Density: 0.01, Coupling: 0.01] | Drag: 2.81 | LOC: 546/335)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D003/verification.json` (files at `_dev-system/tmp/D003/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D003/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `backend/src/models.rs`
- `backend/src/models.rs` (16 functions, fingerprint 3f59a286fa8a359f00d79824a53e2514ec37f5a95df0284d5b99ec6a3b495902)
    - Grouped summary:
        - create × 3 (lines: 288, 331, 460)
        - default × 1 (lines: 511)
        - error_response × 1 (lines: 48)
        - find_by_email × 1 (lines: 487)
        - fmt × 1 (lines: 31)
        - from × 5 (lines: 111, 116, 121, 126, 241)
        - has_issues × 1 (lines: 527)
        - new × 1 (lines: 517)
        - test_app_error_response_format × 1 (lines: 541)
        - to_string × 1 (lines: 251)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
