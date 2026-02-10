# Task D002: Surgical Refactor CORE FRONTEND

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

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 4.20, Density: 0.30, Coupling: 0.10] | Drag: 5.50 | LOC: 393/300  🎯 Target: Function: `finalState` (High Local Complexity (2.0). Logic heavy.))

- [ ] - **../../src/core/SceneMutations.res** (Metric: [Nesting: 5.40, Density: 0.26, Coupling: 0.04] | Drag: 6.68 | LOC: 394/300  🎯 Target: Function: `getDeletedIds` (High Local Complexity (3.5). Logic heavy.))

