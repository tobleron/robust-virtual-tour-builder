# Task D004: Surgical Refactor SYSTEMS TOURTEMPLATES FRONTEND

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
**Directive:** Right-size Surface: Keep the module as the orchestration boundary and extract only adjacent sections that reduce file length without fragmenting the public API.

- [ ] - **../../src/systems/TourTemplates/TourScriptNavigation.res** (Metric: [Nesting: 0.00, Density: 0.00, Coupling: 0.00] | Drag: 1.00 | LOC: 719/414  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.) → 🏗️ Split into 2 modules (target 250-350 LOC each, center ~300 LOC) [Size-only candidate; drag already within target.]

- [ ] - **../../src/systems/TourTemplates/TourScriptUINav.res** (Metric: [Nesting: 0.00, Density: 0.00, Coupling: 0.00] | Drag: 1.00 | LOC: 556/414  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.) → 🏗️ Split into 2 modules (target 250-350 LOC each, center ~300 LOC) [Size-only candidate; drag already within target.]


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D004_Surgical_Refactor_SYSTEMS_TOURTEMPLATES_FRONTEND/verification.json` (files at `_dev-system/tmp/D004_Surgical_Refactor_SYSTEMS_TOURTEMPLATES_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D004_Surgical_Refactor_SYSTEMS_TOURTEMPLATES_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/TourTemplates/TourScriptNavigation.res`
- `src/systems/TourTemplates/TourScriptNavigation.res` (1 functions, fingerprint 1b4994e3d0d530e944a37ae6a8149a225dcf114ddac118de74f1c95d1b2a3e5c)
    - Grouped summary:
        - script × 1 (lines: 1)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TourTemplates/TourScriptUINav.res`
- `src/systems/TourTemplates/TourScriptUINav.res` (1 functions, fingerprint 1b4994e3d0d530e944a37ae6a8149a225dcf114ddac118de74f1c95d1b2a3e5c)
    - Grouped summary:
        - script × 1 (lines: 1)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
