# Task 1090: Surgical Refactor CORE FRONTEND

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
- [ ] **../../src/core/Schemas.res**
    - **Metric:** [Nesting: 0.90, Density: 0.25, Deps: 0.02] | Drag: 6.78 | LOC: 373/108  Hotspot: Lines 389-393
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/core/Reducer.res**
    - **Metric:** [Nesting: 1.20, Density: 0.21, Deps: 0.04] | Drag: 7.64 | LOC: 433/97  Hotspot: Lines 191-195
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/core/SceneHelpers.res**
    - **Metric:** [Nesting: 1.05, Density: 0.15, Deps: 0.04] | Drag: 6.72 | LOC: 271/107  Hotspot: Lines 204-208
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/core/Actions.res**
    - **Metric:** [Nesting: 1.05, Density: 0.82, Deps: 0.01] | Drag: 24.49 | LOC: 154/80  Hotspot: Lines 153-157
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
