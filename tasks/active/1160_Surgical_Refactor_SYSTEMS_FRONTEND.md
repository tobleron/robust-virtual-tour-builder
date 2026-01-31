# Task 1160: Surgical Refactor SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/ApiLogic.res** (Metric: [Nesting: 3.50, Density: 0.07, Coupling: 0.04] | Drag: 7.09 | LOC: 503/300  🎯 Target: Function: `extractMetadata` (High Local Complexity (1.0). Logic heavy.))

- [ ] - **../../src/systems/ExifReportGeneratorLogic.res** (Metric: [Nesting: 4.00, Density: 0.16, Coupling: 0.06] | Drag: 7.92 | LOC: 333/300  🎯 Target: Function: `processSceneDataItem` (High Local Complexity (14.4). Logic heavy.))

- [ ] - **../../src/systems/HotspotLineLogic.res** (Metric: [Nesting: 4.00, Density: 0.29, Coupling: 0.04] | Drag: 7.55 | LOC: 538/300  🎯 Target: Function: `waypointsRaw` (High Local Complexity (2.0). Logic heavy.))

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 6.00, Density: 0.39, Coupling: 0.08] | Drag: 10.13 | LOC: 427/300  🎯 Target: Function: `req` (High Local Complexity (9.3). Logic heavy.))

- [ ] - **../../src/systems/Resizer.res** (Metric: [Nesting: 3.50, Density: 0.21, Coupling: 0.10] | Drag: 8.30 | LOC: 309/300  🎯 Target: Function: `getMemoryUsage` (High Local Complexity (12.9). Logic heavy.))

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 3.00, Density: 0.17, Coupling: 0.09] | Drag: 6.99 | LOC: 356/300  🎯 Target: Function: `updateGlobalStateAndViewer` (High Local Complexity (3.5). Logic heavy.))

- [ ] - **../../src/systems/SimulationLogic.res** (Metric: [Nesting: 3.50, Density: 0.12, Coupling: 0.06] | Drag: 8.29 | LOC: 470/300  🎯 Target: Function: `currentResult` (High Local Complexity (6.6). Logic heavy.))

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: [Nesting: 2.50, Density: 0.05, Coupling: 0.11] | Drag: 5.69 | LOC: 341/300  🎯 Target: Function: `getNotificationType` (High Local Complexity (4.0). Logic heavy.))

