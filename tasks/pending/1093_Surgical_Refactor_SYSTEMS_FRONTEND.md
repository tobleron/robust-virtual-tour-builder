# Task 1093: Surgical Refactor SYSTEMS FRONTEND

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
- [ ] **../../src/systems/HotspotLine.res** - [Nesting: 1.35, Density: 0.12, Deps: 0.06] | Drag: 5.95 | LOC: 697/116  Hotspot: Lines 245-249 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ProjectManager.res** - [Nesting: 1.20, Density: 0.28, Deps: 0.18] | Drag: 8.10 | LOC: 247/84  Hotspot: Lines 235-239 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Simulation.res** - [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 553/221  Hotspot: Lines 366-370 (AI Context Fog (score 124.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ExifReportGenerator.res** - [Nesting: 1.65, Density: 0.00, Deps: 0.00] | Drag: 2.65 | LOC: 542/222  Hotspot: Lines 204-208 (AI Context Fog (score 121.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Scene.res** - [Nesting: 1.05, Density: 0.14, Deps: 0.10] | Drag: 3.90 | LOC: 338/155  Hotspot: Lines 319-323 (AI Context Fog (score 39.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/SvgManager.res** - [Nesting: 0.90, Density: 0.24, Deps: 0.19] | Drag: 8.83 | LOC: 191/80  Hotspot: Lines 164-168 (AI Context Fog (score 40.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationController.res** - [Nesting: 2.25, Density: 0.20, Deps: 0.11] | Drag: 9.08 | LOC: 194/81  Hotspot: Lines 163-167 (AI Context Fog (score 201.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationRenderer.res** - [Nesting: 1.80, Density: 0.14, Deps: 0.08] | Drag: 6.79 | LOC: 248/104  Hotspot: Lines 206-210 (AI Context Fog (score 125.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationGraph.res** - [Nesting: 1.20, Density: 0.21, Deps: 0.06] | Drag: 7.06 | LOC: 121/102  Hotspot: Lines 92-96 (AI Context Fog (score 55.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/LinkEditorLogic.res** - [Nesting: 0.90, Density: 0.19, Deps: 0.09] | Drag: 7.29 | LOC: 122/97  Hotspot: Lines 123-127 (AI Context Fog (score 38.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Navigation.res** - [Nesting: 2.10, Density: 0.21, Deps: 0.13] | Drag: 7.83 | LOC: 415/90  Hotspot: Lines 376-380 (AI Context Fog (score 196.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/PanoramaClusterer.res** - [Nesting: 1.20, Density: 0.29, Deps: 0.10] | Drag: 9.99 | LOC: 146/80  Hotspot: Lines 44-48 (AI Context Fog (score 64.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Api.res** - [Nesting: 1.35, Density: 0.01, Deps: 0.03] | Drag: 2.53 | LOC: 592/225  Hotspot: Lines 601-605 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Resizer.res** - [Nesting: 1.35, Density: 0.26, Deps: 0.11] | Drag: 8.01 | LOC: 300/89  Hotspot: Lines 217-221 (AI Context Fog (score 55.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Teaser.res** - [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 3.72 | LOC: 572/168  Hotspot: Lines 585-589 (AI Context Fog (score 65.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Exporter.res** - [Nesting: 1.35, Density: 0.08, Deps: 0.13] | Drag: 4.38 | LOC: 205/139  Hotspot: Lines 55-59 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ViewerSystem.res** - [Nesting: 1.20, Density: 0.23, Deps: 0.06] | Drag: 8.87 | LOC: 272/86  Hotspot: Lines 168-172 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/UploadProcessor.res** - [Nesting: 1.50, Density: 0.02, Deps: 0.01] | Drag: 2.94 | LOC: 331/204  Hotspot: Lines 336-340 (AI Context Fog (score 84.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
