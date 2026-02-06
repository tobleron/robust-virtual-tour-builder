# Task 1253: Surgical Refactor CORE FRONTEND

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
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions. 🏗️ ARCHITECTURAL TARGET: Split into exactly 2 cohesive modules to respect the Read Tax (avg 300 LOC/module).

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 4.20, Density: 0.31, Coupling: 0.10] | Drag: 5.51 | LOC: 373/300  🎯 Target: Function: `finalState` (High Local Complexity (2.0). Logic heavy.))

- [ ] - **../../src/core/SceneMutations.res** (Metric: [Nesting: 6.60, Density: 0.49, Coupling: 0.04] | Drag: 8.11 | LOC: 363/300  🎯 Target: Function: `syncSceneNames` (High Local Complexity (5.6). Logic heavy.))

