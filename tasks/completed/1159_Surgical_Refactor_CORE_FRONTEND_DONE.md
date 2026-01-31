# Task 1159: Surgical Refactor CORE FRONTEND

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

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 3.00, Density: 0.42, Coupling: 0.09] | Drag: 7.92 | LOC: 306/300)

- [ ] - **../../src/core/SceneHelpers.res** (Metric: [Nesting: 1.50, Density: 0.03, Coupling: 0.05] | Drag: 5.60 | LOC: 308/300  🎯 Target: Function: `sanitizeScene` (High Local Complexity (2.0). Logic heavy.))

