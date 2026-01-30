# Task 1120: Surgical Refactor SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/ApiLogic.res** (Metric: [Nesting: 3.50, Density: 0.11, Coupling: 0.05] | Drag: 7.09 | LOC: 586/300  🎯 Target: Function: `handleResponse` (High Local Complexity (4.2). Logic heavy.))

- [ ] - **../../src/systems/ExifReportGeneratorLogic.res** (Metric: [Nesting: 4.00, Density: 0.12, Coupling: 0.07] | Drag: 7.94 | LOC: 433/300  🎯 Target: Function: `locationPart` (High Local Complexity (6.6). Logic heavy.))

- [ ] - **../../src/systems/HotspotLineLogic.res** (Metric: [Nesting: 4.00, Density: 0.30, Coupling: 0.04] | Drag: 7.65 | LOC: 514/300  🎯 Target: Function: `getPointAtProgress` (High Local Complexity (25.5). Logic heavy.))

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 5.50, Density: 0.41, Coupling: 0.08] | Drag: 10.84 | LOC: 372/300  🎯 Target: Function: `make` (High Local Complexity (11.3). Logic heavy.))

- [ ] - **../../src/systems/Resizer.res** (Metric: [Nesting: 3.50, Density: 0.19, Coupling: 0.10] | Drag: 8.17 | LOC: 303/300  🎯 Target: Function: `getMemoryUsage` (High Local Complexity (10.4). Logic heavy.))

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 3.00, Density: 0.15, Coupling: 0.10] | Drag: 8.69 | LOC: 338/300  🎯 Target: Function: `clv` (High Local Complexity (3.5). Logic heavy.))

- [ ] - **../../src/systems/SimulationLogic.res** (Metric: [Nesting: 4.50, Density: 0.10, Coupling: 0.06] | Drag: 9.24 | LOC: 458/300  🎯 Target: Function: `globalViewer` (High Local Complexity (11.2). Logic heavy.))

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: [Nesting: 2.50, Density: 0.05, Coupling: 0.10] | Drag: 5.68 | LOC: 333/300  🎯 Target: Function: `type_` (High Local Complexity (4.0). Logic heavy.))

