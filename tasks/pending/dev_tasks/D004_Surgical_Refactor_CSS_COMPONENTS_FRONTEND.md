# Task D004: Surgical Refactor CSS COMPONENTS FRONTEND

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

- [ ] - **../../css/components/portal-pages.css** (Metric: [Nesting: 1.20, Density: 0.17, Coupling: 0.00] | Drag: 2.37 | LOC: 980/393  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.) → 🏗️ Split into 3 modules (target 250-350 LOC each, center ~300 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D004_Surgical_Refactor_CSS_COMPONENTS_FRONTEND/verification.json` (files at `_dev-system/tmp/D004_Surgical_Refactor_CSS_COMPONENTS_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D004_Surgical_Refactor_CSS_COMPONENTS_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `css/components/portal-pages.css`
- `css/components/portal-pages.css` (0 functions, fingerprint e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
