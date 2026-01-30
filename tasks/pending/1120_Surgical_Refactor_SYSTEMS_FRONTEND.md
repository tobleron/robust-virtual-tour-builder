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

- [ ] - **../../src/systems/ApiLogic.res** (Metric: [Nesting: 1.35, Density: 0.04, Coupling: 0.11] | Drag: 2.69 | LOC: 586/500  Hotspot: Lines 598-602)

- [ ] - **../../src/systems/HotspotLineLogic.res** (Metric: [Nesting: 1.35, Density: 0.28, Coupling: 0.43] | Drag: 4.40 | LOC: 514/500  Hotspot: Lines 245-249)

