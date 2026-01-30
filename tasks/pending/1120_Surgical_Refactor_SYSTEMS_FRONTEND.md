# Task 1120: Surgical Refactor SYSTEMS FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 2.00 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🚨 Hotspots (Focus Area)
The following regions are calculated to be the most confusing for AI:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/systems/ApiLogic.res** (Metric: [Nesting: 1.05, Density: 0.09, Coupling: 0.02] | Drag: 4.35 | LOC: 586/500  🎯 Target: Function: `handleResponse` (High Local Complexity (4.2). Logic heavy.))

- [ ] - **../../src/systems/HotspotLineLogic.res** (Metric: [Nesting: 1.20, Density: 0.25, Coupling: 0.01] | Drag: 4.22 | LOC: 514/500  🎯 Target: Function: `getPointAtProgress` (High Local Complexity (25.5). Logic heavy.))

