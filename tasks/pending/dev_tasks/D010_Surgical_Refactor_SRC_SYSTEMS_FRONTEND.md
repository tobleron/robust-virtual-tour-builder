# Task D010: Surgical Refactor SRC SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/TeaserRecorderHudSupport.res** (Metric: [Nesting: 4.20, Density: 0.35, Coupling: 0.03] | Drag: 5.58 | LOC: 256/300  ⚠️ Trigger: Drag above target (1.80) with file already at 256 LOC.  🎯 Target: Function: `clampCorner` (High Local Complexity (4.0). Logic heavy.)) → Refactor in-place (keep near ~300 LOC)

- [ ] - **../../src/systems/TourTemplateHtml.res** (Metric: [Nesting: 3.00, Density: 0.01, Coupling: 0.01] | Drag: 4.01 | LOC: 621/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.) → 🏗️ Split into 2 modules (target 250-350 LOC each, center ~300 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D010_Surgical_Refactor_SRC_SYSTEMS_FRONTEND/verification.json` (files at `_dev-system/tmp/D010_Surgical_Refactor_SRC_SYSTEMS_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D010_Surgical_Refactor_SRC_SYSTEMS_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/TeaserRecorderHudSupport.res`
- `src/systems/TeaserRecorderHudSupport.res` (3 functions, fingerprint 3b71133bc3bd110c968b887c62b2a24c4366e7085b773837f8e3dc5f45d82863)
    - Grouped summary:
        - drawRoundedRectCorners × 1 (lines: 10)
        - fitTextToWidth × 1 (lines: 74)
        - renderMarketingBanner × 1 (lines: 106)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TourTemplateHtml.res`
- `src/systems/TourTemplateHtml.res` (0 functions, fingerprint e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
