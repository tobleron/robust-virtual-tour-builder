# Task 1081: Surgical Refactor Batch 2 FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 2.00 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.

### 🚨 Hotspots (Focus Area)
The following regions are calculated to be the most confusing for AI:

## Tasks
- [ ] **../../src/systems/ProjectManager.res** - [Nesting: 1.20, Density: 0.28, Deps: 0.18] | Drag: 8.10 | LOC: 247/84  Hotspot: Lines 235-239 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Schemas.res** - [Nesting: 0.90, Density: 0.24, Deps: 0.02] | Drag: 6.62 | LOC: 386/110  Hotspot: Lines 385-389 (AI Context Fog (score 27.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Constants.res** - [Nesting: 0.45, Density: 0.03, Deps: 0.00] | Drag: 2.05 | LOC: 185/134  Hotspot: Lines 216-220 (AI Context Fog (score 6.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Simulation.res** - [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 553/221  Hotspot: Lines 366-370 (AI Context Fog (score 124.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ProgressBar.res** - [Nesting: 0.90, Density: 0.25, Deps: 0.14] | Drag: 5.90 | LOC: 106/80  Hotspot: Lines 111-115 (AI Context Fog (score 37.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Exporter.res** - [Nesting: 1.35, Density: 0.08, Deps: 0.13] | Drag: 4.38 | LOC: 205/139  Hotspot: Lines 55-59 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/SessionStore.res** - [Nesting: 0.75, Density: 0.39, Deps: 0.01] | Drag: 6.88 | LOC: 84/80  Hotspot: Lines 53-57 (AI Context Fog (score 29.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Resizer.res** - [Nesting: 1.35, Density: 0.26, Deps: 0.11] | Drag: 8.01 | LOC: 300/89  Hotspot: Lines 217-221 (AI Context Fog (score 55.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationController.res** - [Nesting: 2.25, Density: 0.21, Deps: 0.11] | Drag: 9.59 | LOC: 193/80  Hotspot: Lines 162-166 (AI Context Fog (score 201.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Teaser.res** - [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 3.72 | LOC: 572/168  Hotspot: Lines 585-589 (AI Context Fog (score 65.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Logger.res** - [Nesting: 0.90, Density: 0.13, Deps: 0.02] | Drag: 5.24 | LOC: 492/80  Hotspot: Lines 175-179 (AI Context Fog (score 31.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/UploadProcessor.res** - [Nesting: 1.50, Density: 0.02, Deps: 0.01] | Drag: 2.94 | LOC: 331/204  Hotspot: Lines 336-340 (AI Context Fog (score 84.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/HotspotLine.res** - [Nesting: 1.35, Density: 0.13, Deps: 0.06] | Drag: 6.45 | LOC: 612/109  Hotspot: Lines 245-249 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
