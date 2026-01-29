# Task 1087: Surgical Refactor SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/Api.res** (Metric: [Nesting: 1.35, Density: 0.01, Deps: 0.03] | Drag: 2.53 | LOC: 592/228  Hotspot: Lines 601-605)

- [ ] - **../../src/systems/ExifReportGenerator.res** (Metric: [Nesting: 1.65, Density: 0.00, Deps: 0.00] | Drag: 2.65 | LOC: 542/224  Hotspot: Lines 204-208)

- [ ] - **../../src/systems/Exporter.res** (Metric: [Nesting: 1.35, Density: 0.08, Deps: 0.13] | Drag: 4.38 | LOC: 205/141  Hotspot: Lines 55-59)

- [ ] - **../../src/systems/HotspotLine.res** (Metric: [Nesting: 1.35, Density: 0.12, Deps: 0.06] | Drag: 5.95 | LOC: 697/118  Hotspot: Lines 245-249)

- [ ] - **../../src/systems/LinkEditorLogic.res** (Metric: [Nesting: 0.90, Density: 0.19, Deps: 0.09] | Drag: 7.29 | LOC: 122/99  Hotspot: Lines 123-127)

- [ ] - **../../src/systems/Navigation.res** (Metric: [Nesting: 2.10, Density: 0.21, Deps: 0.13] | Drag: 7.83 | LOC: 415/91  Hotspot: Lines 376-380)

- [ ] - **../../src/systems/NavigationController.res** (Metric: [Nesting: 2.25, Density: 0.20, Deps: 0.11] | Drag: 9.08 | LOC: 194/82  Hotspot: Lines 163-167)

- [ ] - **../../src/systems/NavigationGraph.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.06] | Drag: 7.06 | LOC: 121/103  Hotspot: Lines 92-96)

- [ ] - **../../src/systems/NavigationRenderer.res** (Metric: [Nesting: 1.80, Density: 0.14, Deps: 0.08] | Drag: 6.79 | LOC: 248/105  Hotspot: Lines 206-210)

- [ ] - **../../src/systems/PanoramaClusterer.res** (Metric: [Nesting: 1.20, Density: 0.29, Deps: 0.10] | Drag: 10.15 | LOC: 143/80  Hotspot: Lines 132-136)

- [ ] - **../../src/systems/ProjectManager.res** (Metric: [Nesting: 1.20, Density: 0.28, Deps: 0.18] | Drag: 8.10 | LOC: 247/85  Hotspot: Lines 235-239)

- [ ] - **../../src/systems/Resizer.res** (Metric: [Nesting: 1.50, Density: 0.26, Deps: 0.11] | Drag: 8.10 | LOC: 303/90  Hotspot: Lines 218-222)

- [ ] - **../../src/systems/Scene.res** (Metric: [Nesting: 1.05, Density: 0.14, Deps: 0.10] | Drag: 3.90 | LOC: 338/157  Hotspot: Lines 319-323)

- [ ] - **../../src/systems/Simulation.res** (Metric: [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 557/224  Hotspot: Lines 370-374)

- [ ] - **../../src/systems/SvgManager.res** (Metric: [Nesting: 0.90, Density: 0.24, Deps: 0.19] | Drag: 8.08 | LOC: 190/85  Hotspot: Lines 163-167)

- [ ] - **../../src/systems/Teaser.res** (Metric: [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 2.53 | LOC: 581/227  Hotspot: Lines 594-598)

- [ ] - **../../src/systems/UploadProcessor.res** (Metric: [Nesting: 1.50, Density: 0.02, Deps: 0.01] | Drag: 2.94 | LOC: 333/207  Hotspot: Lines 338-342)

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.05] | Drag: 6.87 | LOC: 299/106  Hotspot: Lines 207-211)

