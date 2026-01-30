# Task 1128: Surgical Refactor UTILS FRONTEND

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

- [ ] - **../../src/utils/Logger.res** (Metric: [Nesting: 3.00, Density: 0.31, Coupling: 0.05] | Drag: 7.56 | LOC: 492/300  🎯 Target: Function: `stringToLevel` (High Local Complexity (7.0). Logic heavy.))

