# Task 1095: Surgical Refactor API BACKEND

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
- [ ] **../../backend/src/api/project.rs**
    - **Metric:** [Nesting: 0.75, Density: 0.04, Deps: 0.00] | Drag: 2.19 | LOC: 374/353
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../backend/src/api/project.rs**
    - **Metric:** [Nesting: 0.75, Density: 0.04, Deps: 0.00] | Drag: 2.19 | LOC: 375/353
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
