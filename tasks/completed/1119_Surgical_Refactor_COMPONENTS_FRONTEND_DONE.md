# Task 1119: Surgical Refactor COMPONENTS FRONTEND

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

- [ ] - **../../src/components/SceneList.res** (Metric: [Nesting: 3.50, Density: 0.09, Coupling: 0.08] | Drag: 7.02 | LOC: 419/300  🎯 Target: Function: `getThumbUrl` (High Local Complexity (3.0). Logic heavy.))

- [ ] - **../../src/components/Sidebar.res** (Metric: [Nesting: 4.00, Density: 0.05, Coupling: 0.09] | Drag: 7.12 | LOC: 571/300  🎯 Target: Function: `handleUpload` (High Local Complexity (3.5). Logic heavy.))

- [ ] - **../../src/components/ViewerManagerLogic.res** (Metric: [Nesting: 2.00, Density: 0.03, Coupling: 0.09] | Drag: 6.91 | LOC: 314/300  🎯 Target: Function: `v` (High Local Complexity (2.0). Logic heavy.))

- [ ] - **../../src/components/VisualPipeline.res** (Metric: [Nesting: 3.00, Density: 0.08, Coupling: 0.07] | Drag: 6.43 | LOC: 357/300  🎯 Target: Function: `injectStyles` (High Local Complexity (3.0). Logic heavy.))

