# Task 1162: Surgical Refactor SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/ApiLogic.res** (Metric: [Nesting: 2.00, Density: 0.05, Coupling: 0.06] | Drag: 6.19 | LOC: 373/300)

- [ ] - **../../src/systems/ExifReportGeneratorLogic.res** (Metric: [Nesting: 4.00, Density: 0.16, Coupling: 0.06] | Drag: 7.88 | LOC: 342/300  🎯 Target: Function: `extractAllExif` (High Local Complexity (10.0). Logic heavy.))

- [ ] - **../../src/systems/HotspotLineLogic.res** (Metric: [Nesting: 4.00, Density: 0.29, Coupling: 0.04] | Drag: 7.54 | LOC: 546/300  🎯 Target: Function: `waypointsRaw` (High Local Complexity (2.0). Logic heavy.))

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 3.50, Density: 0.38, Coupling: 0.08] | Drag: 7.62 | LOC: 447/300  🎯 Target: Function: `req` (High Local Complexity (7.6). Logic heavy.))

- [ ] - **../../src/systems/Resizer.res** (Metric: [Nesting: 2.50, Density: 0.24, Coupling: 0.10] | Drag: 7.35 | LOC: 310/300  🎯 Target: Function: `getMemoryUsage` (High Local Complexity (10.5). Logic heavy.))

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 3.00, Density: 0.17, Coupling: 0.09] | Drag: 7.00 | LOC: 362/300  🎯 Target: Function: `scheduleCleanup` (High Local Complexity (3.0). Logic heavy.))

- [ ] - **../../src/systems/SimulationLogic.res** (Metric: [Nesting: 3.50, Density: 0.12, Coupling: 0.06] | Drag: 8.29 | LOC: 469/300  🎯 Target: Function: `start` (High Local Complexity (6.6). Logic heavy.))

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: [Nesting: 1.50, Density: 0.03, Coupling: 0.10] | Drag: 4.70 | LOC: 345/300  🎯 Target: Function: `getNotificationType` (High Local Complexity (4.0). Logic heavy.))

