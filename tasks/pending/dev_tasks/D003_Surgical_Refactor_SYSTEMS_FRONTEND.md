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

- [ ] - **../../src/systems/ProjectManager.res** (Metric: [Nesting: 4.20, Density: 0.20, Coupling: 0.10] | Drag: 5.40 | LOC: 403/300  🎯 Target: Function: `finalToken` (High Local Complexity (2.0). Logic heavy.))

- [ ] - **../../src/systems/UploadProcessorLogic.res** (Metric: [Nesting: 2.40, Density: 0.04, Coupling: 0.11] | Drag: 3.44 | LOC: 399/300  🎯 Target: Function: `getNotificationType` (High Local Complexity (4.0). Logic heavy.))

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 4.20, Density: 0.51, Coupling: 0.08] | Drag: 5.75 | LOC: 379/300  🎯 Target: Function: `elOpt` (High Local Complexity (6.9). Logic heavy.))

