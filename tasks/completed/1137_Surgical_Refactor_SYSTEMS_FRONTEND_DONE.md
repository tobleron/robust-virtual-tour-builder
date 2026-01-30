# Task 1137: Surgical Refactor SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/ApiLogic.res** (Metric: [Nesting: 3.50, Density: 0.11, Coupling: 0.05] | Drag: 7.10 | LOC: 589/300  🎯 Target: Function: `processErrorResponse` (High Local Complexity (4.5). Logic heavy.))

- [ ] - **../../src/systems/ExifReportGeneratorLogic.res** (Metric: [Nesting: 4.00, Density: 0.13, Coupling: 0.07] | Drag: 7.96 | LOC: 433/300  🎯 Target: Function: `extractLocationName` (High Local Complexity (9.2). Logic heavy.))

- [ ] - **../../src/systems/HotspotLineLogic.res** (Metric: [Nesting: 4.00, Density: 0.29, Coupling: 0.04] | Drag: 7.54 | LOC: 538/300  🎯 Target: Function: `mousePtOpt` (High Local Complexity (5.0). Logic heavy.))

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 6.00, Density: 0.40, Coupling: 0.08] | Drag: 10.23 | LOC: 390/300  🎯 Target: Function: `startJourney` (High Local Complexity (10.1). Logic heavy.))

- [ ] - **../../src/systems/Resizer.res** (Metric: [Nesting: 3.50, Density: 0.20, Coupling: 0.10] | Drag: 8.23 | LOC: 301/300  🎯 Target: Function: `getMemoryUsage` (High Local Complexity (10.9). Logic heavy.))

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 3.00, Density: 0.16, Coupling: 0.09] | Drag: 6.97 | LOC: 350/300  🎯 Target: Function: `scheduleCleanup` (High Local Complexity (6.6). Logic heavy.))

- [ ] - **../../src/systems/SimulationLogic.res** (Metric: [Nesting: 4.50, Density: 0.11, Coupling: 0.06] | Drag: 9.22 | LOC: 459/300  🎯 Target: Function: `globalViewer` (High Local Complexity (7.5). Logic heavy.))

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: [Nesting: 2.50, Density: 0.05, Coupling: 0.10] | Drag: 5.68 | LOC: 337/300  🎯 Target: Function: `type_` (High Local Complexity (4.0). Logic heavy.))

