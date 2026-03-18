# Task D007: Surgical Refactor SRC SYSTEMS FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** Reduce estimated modification risk below the applicable drag target without fragmenting cohesive modules.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules only when the resulting split stays within the preferred size policy.
**Optimal State:** The file remains a clear 'Orchestrator' or 'Service' boundary, with only truly dense or isolated logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/systems/TourTemplateHtml.res** (Metric: [Nesting: 3.00, Density: 0.01, Coupling: 0.01] | Drag: 4.01 | LOC: 620/400  ⚠️ Trigger: Drag above target (2.40); keep the module within the 350-450 LOC working band if you extract helpers.) → 🏗️ Split into 2 modules (target 350-450 LOC each, center ~400 LOC, floor 220 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D007_Surgical_Refactor_SRC_SYSTEMS_FRONTEND/verification.json` (files at `_dev-system/tmp/D007_Surgical_Refactor_SRC_SYSTEMS_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D007_Surgical_Refactor_SRC_SYSTEMS_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/TourTemplateHtml.res`
- `src/systems/TourTemplateHtml.res` (0 functions, fingerprint e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
