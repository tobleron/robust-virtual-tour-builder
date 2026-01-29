# Task 1080: Surgical Refactor Batch 1 FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 2.00 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.

### 🚨 Hotspots (Focus Area)
The following regions are calculated to be the most confusing for AI:

## Tasks

### 🔧 Action: De-bloat
- [ ] **../../src/systems/HotspotLine.res** - [Nesting: 1.35, Density: 0.13, Deps: 0.06] | Drag: 6.45 | LOC: 612/109  Hotspot: Lines 245-249 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Logger.res** - [Nesting: 0.90, Density: 0.13, Deps: 0.02] | Drag: 5.24 | LOC: 492/80  Hotspot: Lines 175-179 (AI Context Fog (score 31.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Teaser.res** - [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 3.72 | LOC: 572/168  Hotspot: Lines 585-589 (AI Context Fog (score 65.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Reducer.res** - [Nesting: 1.50, Density: 0.21, Deps: 0.04] | Drag: 7.98 | LOC: 430/94  Hotspot: Lines 182-186 (AI Context Fog (score 86.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Navigation.res** - [Nesting: 2.10, Density: 0.21, Deps: 0.13] | Drag: 7.84 | LOC: 420/90  Hotspot: Lines 381-385 (AI Context Fog (score 196.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Api.res** - [Nesting: 1.35, Density: 0.01, Deps: 0.03] | Drag: 2.53 | LOC: 592/225  Hotspot: Lines 601-605 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Simulation.res** - [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 553/221  Hotspot: Lines 366-370 (AI Context Fog (score 124.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ExifReportGenerator.res** - [Nesting: 1.65, Density: 0.00, Deps: 0.00] | Drag: 2.65 | LOC: 542/222  Hotspot: Lines 204-208 (AI Context Fog (score 121.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Schemas.res** - [Nesting: 0.90, Density: 0.24, Deps: 0.02] | Drag: 6.62 | LOC: 386/110  Hotspot: Lines 385-389 (AI Context Fog (score 27.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ViewerManagerLogic.res** - [Nesting: 1.20, Density: 0.23, Deps: 0.22] | Drag: 8.93 | LOC: 307/80  Hotspot: Lines 183-187 (AI Context Fog (score 61.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Resizer.res** - [Nesting: 1.35, Density: 0.26, Deps: 0.11] | Drag: 8.01 | LOC: 300/89  Hotspot: Lines 217-221 (AI Context Fog (score 55.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Actions.res** - [Nesting: 0.15, Density: 0.92, Deps: 0.01] | Drag: 25.31 | LOC: 105/80  Hotspot: Lines 55-59 (AI Context Fog (score 3.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ViewerSystem.res** - [Nesting: 1.20, Density: 0.23, Deps: 0.06] | Drag: 8.87 | LOC: 272/86  Hotspot: Lines 168-172 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/HotspotLine.res** - [Nesting: 1.35, Density: 0.12, Deps: 0.06] | Drag: 5.96 | LOC: 695/116  Hotspot: Lines 245-249 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Navigation.res** - [Nesting: 2.10, Density: 0.20, Deps: 0.13] | Drag: 7.77 | LOC: 420/91  Hotspot: Lines 381-385 (AI Context Fog (score 196.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
