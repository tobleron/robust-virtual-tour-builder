# Task D001: Surgical Refactor CSS COMPONENTS FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** Reduce estimated modification risk below the applicable drag target without fragmenting cohesive modules.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules only when the resulting split stays within the preferred size policy.
**Optimal State:** The file remains a clear 'Orchestrator' or 'Service' boundary, with only truly dense or isolated logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../css/components/portal-pages-admin-tables.css** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 159)) → Refactor in-place (keep near ~400 LOC and above 220 LOC floor)

- [ ] - **../../css/components/portal-pages-admin-ui.css** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 305)) → Refactor in-place (keep near ~400 LOC and above 220 LOC floor)

- [ ] - **../../css/components/portal-pages-auth.css** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 76)) → Refactor in-place (keep near ~400 LOC and above 220 LOC floor)

- [ ] - **../../css/components/portal-pages-base.css** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 238)) → Refactor in-place (keep near ~400 LOC and above 220 LOC floor)

- [ ] - **../../css/components/portal-pages-customer.css** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 319)) → Refactor in-place (keep near ~400 LOC and above 220 LOC floor)


### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../css/components/portal-pages.css** (Metric: [Nesting: 1.20, Density: 0.17, Coupling: 0.00] | Drag: 2.37 | LOC: 1078/400  ⚠️ Trigger: Oversized beyond the preferred 350-450 LOC working band.) → 🏗️ Split into 3 modules (target 350-450 LOC each, center ~400 LOC, floor 220 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D001_Surgical_Refactor_CSS_COMPONENTS_FRONTEND/verification.json` (files at `_dev-system/tmp/D001_Surgical_Refactor_CSS_COMPONENTS_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D001_Surgical_Refactor_CSS_COMPONENTS_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `css/components/portal-pages.css`
- `css/components/portal-pages.css` (0 functions, fingerprint e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
