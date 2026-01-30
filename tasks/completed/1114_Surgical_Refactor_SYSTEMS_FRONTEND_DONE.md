# Task 1114: Surgical Refactor SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/Api.res** (Metric: [Nesting: 1.35, Density: 0.04, Coupling: 0.54] | Drag: 2.69 | LOC: 592/500  Hotspot: Lines 601-605)

- [ ] - **../../src/systems/ExifReportGenerator.res** (Metric: [Nesting: 1.65, Density: 0.01, Coupling: 0.49] | Drag: 2.72 | LOC: 542/500  Hotspot: Lines 204-208)

- [ ] - **../../src/systems/HotspotLine.res** (Metric: [Nesting: 1.35, Density: 0.27, Coupling: 0.37] | Drag: 4.31 | LOC: 697/500  Hotspot: Lines 245-249)

- [ ] - **../../src/systems/Simulation.res** (Metric: [Nesting: 1.65, Density: 0.00, Coupling: 0.27] | Drag: 2.83 | LOC: 557/500  Hotspot: Lines 370-374)

- [ ] - **../../src/systems/Teaser.res** (Metric: [Nesting: 1.20, Density: 0.08, Coupling: 0.45] | Drag: 2.93 | LOC: 581/500  Hotspot: Lines 594-598)

