# Task 1105: Surgical Refactor SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/Api.res** (Metric: [Nesting: 1.35, Density: 0.01, Coupling: 0.54] | Drag: 2.38 | LOC: 592/250  Hotspot: Lines 601-605)

- [ ] - **../../src/systems/ExifParser.res** (Metric: [Nesting: 1.05, Density: 0.00, Coupling: 0.53] | Drag: 2.05 | LOC: 266/250  Hotspot: Lines 49-53)

- [ ] - **../../src/systems/ExifReportGenerator.res** (Metric: [Nesting: 1.65, Density: 0.00, Coupling: 0.49] | Drag: 2.65 | LOC: 542/250  Hotspot: Lines 204-208)

- [ ] - **../../src/systems/HotspotLine.res** (Metric: [Nesting: 1.35, Density: 0.12, Coupling: 0.37] | Drag: 2.78 | LOC: 697/250  Hotspot: Lines 245-249)

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 2.10, Density: 0.21, Coupling: 0.36] | Drag: 4.10 | LOC: 415/250  Hotspot: Lines 376-380)

- [ ] - **../../src/systems/Resizer.res** (Metric: [Nesting: 1.50, Density: 0.26, Coupling: 0.51] | Drag: 3.21 | LOC: 303/250  Hotspot: Lines 218-222)

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 1.05, Density: 0.14, Coupling: 0.54] | Drag: 2.32 | LOC: 338/250  Hotspot: Lines 319-323)

- [ ] - **../../src/systems/Simulation.res** (Metric: [Nesting: 1.65, Density: 0.00, Coupling: 0.27] | Drag: 2.65 | LOC: 557/250  Hotspot: Lines 370-374)

- [ ] - **../../src/systems/Teaser.res** (Metric: [Nesting: 1.20, Density: 0.01, Coupling: 0.45] | Drag: 2.24 | LOC: 581/250  Hotspot: Lines 594-598)

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: [Nesting: 1.50, Density: 0.02, Coupling: 0.58] | Drag: 2.55 | LOC: 333/250  Hotspot: Lines 338-342)

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 1.20, Density: 0.21, Coupling: 0.51] | Drag: 3.96 | LOC: 299/250  Hotspot: Lines 207-211)


### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../src/systems/NavigationController.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 194))

- [ ] - **../../src/systems/NavigationRenderer.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 248))

- [ ] - **../../src/systems/NavigationUI.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 54))

