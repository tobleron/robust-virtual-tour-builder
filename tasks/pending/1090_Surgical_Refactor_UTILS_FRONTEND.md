# Task 1090: Surgical Refactor UTILS FRONTEND

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
- [ ] **../../src/utils/ImageOptimizer.res** - [Nesting: 1.05, Density: 0.03, Deps: 0.16] | Drag: 3.06 | LOC: 92/89  Hotspot: Lines 59-63 (AI Context Fog (score 49.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/LazyLoad.res** - [Nesting: 1.20, Density: 0.10, Deps: 0.16] | Drag: 4.46 | LOC: 87/80  Hotspot: Lines 30-34 (AI Context Fog (score 58.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Logger.res** - [Nesting: 0.90, Density: 0.13, Deps: 0.02] | Drag: 5.24 | LOC: 492/80  Hotspot: Lines 175-179 (AI Context Fog (score 31.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/SessionStore.res** - [Nesting: 0.75, Density: 0.39, Deps: 0.01] | Drag: 6.88 | LOC: 84/80  Hotspot: Lines 53-57 (AI Context Fog (score 29.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Constants.res** - [Nesting: 0.45, Density: 0.03, Deps: 0.00] | Drag: 2.05 | LOC: 185/134  Hotspot: Lines 216-220 (AI Context Fog (score 6.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ProgressBar.res** - [Nesting: 0.90, Density: 0.25, Deps: 0.14] | Drag: 5.90 | LOC: 106/80  Hotspot: Lines 111-115 (AI Context Fog (score 37.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/PathInterpolation.res** - [Nesting: 1.20, Density: 0.13, Deps: 0.06] | Drag: 5.11 | LOC: 236/80  Hotspot: Lines 109-113 (AI Context Fog (score 64.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
