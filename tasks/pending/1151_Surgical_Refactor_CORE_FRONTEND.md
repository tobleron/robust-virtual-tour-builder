# Task 1151: Surgical Refactor CORE FRONTEND

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

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 4.00, Density: 0.45, Coupling: 0.06] | Drag: 8.85 | LOC: 443/300  🎯 Target: Function: `calculateTransition` (High Local Complexity (3.0). Logic heavy.))

- [ ] - **../../src/core/Schemas.res** (Metric: [Nesting: 2.00, Density: 0.51, Coupling: 0.05] | Drag: 6.14 | LOC: 377/300  🎯 Target: Function: `castToValidationReport` (High Local Complexity (3.0). Logic heavy.))

