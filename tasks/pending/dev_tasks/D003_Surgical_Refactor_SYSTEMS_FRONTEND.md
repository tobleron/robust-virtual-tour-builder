# Task D003: Surgical Refactor SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/ProjectManager.res** (Metric: [Nesting: 4.20, Density: 0.21, Coupling: 0.10] | Drag: 5.41 | LOC: 395/300  🎯 Target: Function: `finalToken` (High Local Complexity (2.0). Logic heavy.))

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 3.60, Density: 0.05, Coupling: 0.08] | Drag: 4.67 | LOC: 391/300  🎯 Target: Function: `elOpt` (High Local Complexity (4.0). Logic heavy.))

