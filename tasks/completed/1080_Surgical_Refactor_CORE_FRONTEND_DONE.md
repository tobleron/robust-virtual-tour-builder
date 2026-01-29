# Task 1080: Surgical Refactor CORE FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 2.00 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🚨 Hotspots (Focus Area)
The following regions are calculated to be the most confusing for AI:

## Tasks

### 🔧 Action: De-bloat
- [ ] **../../src/core/Reducer.res**
    - **Metric:** [Nesting: 1.50, Density: 0.21, Deps: 0.04] | Drag: 7.98 | LOC: 430/94  Hotspot: Lines 182-186
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/core/Schemas.res**
    - **Metric:** [Nesting: 0.90, Density: 0.24, Deps: 0.02] | Drag: 6.62 | LOC: 386/110  Hotspot: Lines 385-389
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/core/Actions.res**
    - **Metric:** [Nesting: 0.15, Density: 0.92, Deps: 0.01] | Drag: 25.31 | LOC: 105/80  Hotspot: Lines 55-59
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/core/SceneHelpers.res**
    - **Metric:** [Nesting: 1.05, Density: 0.16, Deps: 0.05] | Drag: 6.84 | LOC: 264/106  Hotspot: Lines 196-200
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
