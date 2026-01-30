# Task 1127: Surgical Refactor CORE FRONTEND

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

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 4.00, Density: 0.45, Coupling: 0.06] | Drag: 8.89 | LOC: 433/300  🎯 Target: Function: `newTransition` (High Local Complexity (2.0). Logic heavy.))

- [ ] - **../../src/core/Schemas.res** (Metric: [Nesting: 2.50, Density: 0.50, Coupling: 0.05] | Drag: 6.62 | LOC: 376/300  🎯 Target: Function: `castToProject` (High Local Complexity (3.4). Logic heavy.))

