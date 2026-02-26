# Task D017: Surgical Refactor TOURTEMPLATES FRONTEND

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

- [ ] - **../../src/systems/TourTemplates/TourScriptUI.res** (Metric: [Nesting: 0.00, Density: 0.00, Coupling: 0.00] | Drag: 1.00 | LOC: 547/416) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D017/verification.json` (files at `_dev-system/tmp/D017/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D017/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/TourTemplates/TourScriptUI.res`
- `src/systems/TourTemplates/TourScriptUI.res` (1 functions, fingerprint 1b4994e3d0d530e944a37ae6a8149a225dcf114ddac118de74f1c95d1b2a3e5c)
    - Grouped summary:
        - script × 1 (lines: 1)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
