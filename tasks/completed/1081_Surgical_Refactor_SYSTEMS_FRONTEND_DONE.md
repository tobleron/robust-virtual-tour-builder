# Task 1081: Surgical Refactor SYSTEMS FRONTEND

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
- [ ] **../../src/systems/Resizer.res**
    - **Metric:** [Nesting: 1.35, Density: 0.26, Deps: 0.11] | Drag: 8.01 | LOC: 300/89  Hotspot: Lines 217-221
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/LinkEditorLogic.res**
    - **Metric:** [Nesting: 0.90, Density: 0.19, Deps: 0.09] | Drag: 7.29 | LOC: 122/97  Hotspot: Lines 123-127
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/Simulation.res**
    - **Metric:** [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 553/221  Hotspot: Lines 366-370
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/Scene.res**
    - **Metric:** [Nesting: 1.05, Density: 0.14, Deps: 0.10] | Drag: 3.90 | LOC: 338/155  Hotspot: Lines 319-323
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/Teaser.res**
    - **Metric:** [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 3.72 | LOC: 572/168  Hotspot: Lines 585-589
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/PanoramaClusterer.res**
    - **Metric:** [Nesting: 1.20, Density: 0.29, Deps: 0.10] | Drag: 9.99 | LOC: 146/80  Hotspot: Lines 44-48
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/ViewerSystem.res**
    - **Metric:** [Nesting: 1.20, Density: 0.23, Deps: 0.06] | Drag: 8.87 | LOC: 272/86  Hotspot: Lines 168-172
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/HotspotLine.res**
    - **Metric:** [Nesting: 1.35, Density: 0.12, Deps: 0.06] | Drag: 5.95 | LOC: 697/116  Hotspot: Lines 245-249
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/UploadProcessor.res**
    - **Metric:** [Nesting: 1.50, Density: 0.02, Deps: 0.01] | Drag: 2.94 | LOC: 331/204  Hotspot: Lines 336-340
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/Api.res**
    - **Metric:** [Nesting: 1.35, Density: 0.01, Deps: 0.03] | Drag: 2.53 | LOC: 592/225  Hotspot: Lines 601-605
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/ProjectManager.res**
    - **Metric:** [Nesting: 1.20, Density: 0.28, Deps: 0.18] | Drag: 8.10 | LOC: 247/84  Hotspot: Lines 235-239
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/ExifReportGenerator.res**
    - **Metric:** [Nesting: 1.65, Density: 0.00, Deps: 0.00] | Drag: 2.65 | LOC: 542/222  Hotspot: Lines 204-208
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/NavigationRenderer.res**
    - **Metric:** [Nesting: 1.80, Density: 0.14, Deps: 0.08] | Drag: 6.79 | LOC: 248/104  Hotspot: Lines 206-210
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/NavigationController.res**
    - **Metric:** [Nesting: 2.25, Density: 0.20, Deps: 0.11] | Drag: 9.08 | LOC: 194/81  Hotspot: Lines 163-167
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/Navigation.res**
    - **Metric:** [Nesting: 2.10, Density: 0.21, Deps: 0.13] | Drag: 7.83 | LOC: 415/90  Hotspot: Lines 376-380
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/SvgManager.res**
    - **Metric:** [Nesting: 0.90, Density: 0.24, Deps: 0.19] | Drag: 8.83 | LOC: 191/80  Hotspot: Lines 164-168
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/Exporter.res**
    - **Metric:** [Nesting: 1.35, Density: 0.08, Deps: 0.13] | Drag: 4.38 | LOC: 205/139  Hotspot: Lines 55-59
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/NavigationGraph.res**
    - **Metric:** [Nesting: 1.20, Density: 0.21, Deps: 0.06] | Drag: 7.06 | LOC: 121/102  Hotspot: Lines 92-96
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/Simulation.res**
    - **Metric:** [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 557/221  Hotspot: Lines 370-374
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/UploadProcessor.res**
    - **Metric:** [Nesting: 1.50, Density: 0.02, Deps: 0.01] | Drag: 2.94 | LOC: 333/204  Hotspot: Lines 338-342
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/PanoramaClusterer.res**
    - **Metric:** [Nesting: 1.20, Density: 0.28, Deps: 0.10] | Drag: 9.88 | LOC: 148/80  Hotspot: Lines 44-48
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/ViewerSystem.res**
    - **Metric:** [Nesting: 1.20, Density: 0.23, Deps: 0.06] | Drag: 7.24 | LOC: 287/100  Hotspot: Lines 199-203
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/Teaser.res**
    - **Metric:** [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 2.53 | LOC: 581/225  Hotspot: Lines 594-598
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/systems/SvgManager.res**
    - **Metric:** [Nesting: 0.90, Density: 0.24, Deps: 0.19] | Drag: 8.08 | LOC: 190/83  Hotspot: Lines 163-167
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
