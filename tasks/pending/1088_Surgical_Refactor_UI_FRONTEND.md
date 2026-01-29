# Task 1088: Surgical Refactor UI FRONTEND

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
- [ ] **../../src/components/ui/context-menu.jsx**
    - **Metric:** [Nesting: 0.60, Density: 0.16, Deps: 0.00] | Drag: 14.10 | LOC: 158/110
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/components/ui/dropdown-menu.jsx**
    - **Metric:** [Nesting: 0.60, Density: 0.16, Deps: 0.00] | Drag: 14.34 | LOC: 155/109
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
