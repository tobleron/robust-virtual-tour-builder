# Task D010: Surgical Refactor TOURTEMPLATES FRONTEND

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

- [ ] - **../../src/systems/TourTemplates/TourScripts.res** (Metric: [Nesting: 0.00, Density: 0.01, Coupling: 0.00] | Drag: 1.01 | LOC: 920/409) → 🏗️ Split into 3 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D010/verification.json` (files at `_dev-system/tmp/D010/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D010/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/TourTemplates/TourScripts.res`
- `src/systems/TourTemplates/TourScripts.res` (3 functions, fingerprint 24000339bdfe7cced029d1300d76747ddb9243a61d1b6d4e720da0de00542e5a)
    - Grouped summary:
        - generateRenderScript × 1 (lines: 948)
        - loadEventScript × 1 (lines: 929)
        - renderScriptTemplate × 1 (lines: 1)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
