# Task D003: Surgical Refactor COMPONENTS SIDEBAR FRONTEND

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

- [ ] - **../../src/components/Sidebar/SidebarActionsSupport.res** (Metric: [Nesting: 3.60, Density: 0.14, Coupling: 0.06] | Drag: 4.83 | LOC: 254/300  ⚠️ Trigger: Drag above target (1.80) with file already at 254 LOC.  🎯 Target: Function: `saveTargetLabel` (High Local Complexity (3.0). Logic heavy.)) → Refactor in-place (keep near ~300 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D003_Surgical_Refactor_COMPONENTS_SIDEBAR_FRONTEND/verification.json` (files at `_dev-system/tmp/D003_Surgical_Refactor_COMPONENTS_SIDEBAR_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D003_Surgical_Refactor_COMPONENTS_SIDEBAR_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/Sidebar/SidebarActionsSupport.res`
- `src/components/Sidebar/SidebarActionsSupport.res` (7 functions, fingerprint 8bd1d122c153eab7dcab75cb582fa2b76b01a8d2fd38e7610e84451476c771ce)
    - Grouped summary:
        - defaultTeaserRequest × 1 (lines: 9)
        - make × 1 (lines: 115)
        - publishModalConfig × 1 (lines: 86)
        - resetPublishOptions × 1 (lines: 80)
        - saveModalConfig × 1 (lines: 22)
        - saveTargetLabel × 1 (lines: 15)
        - teaserModalConfig × 1 (lines: 241)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
