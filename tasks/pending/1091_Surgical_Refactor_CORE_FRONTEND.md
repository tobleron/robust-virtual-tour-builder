# Task 1091: Surgical Refactor CORE FRONTEND

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
- [ ] **../../src/core/Actions.res** - [Nesting: 0.15, Density: 0.92, Deps: 0.01] | Drag: 25.31 | LOC: 105/80  Hotspot: Lines 55-59 (AI Context Fog (score 3.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Reducer.res** - [Nesting: 1.50, Density: 0.21, Deps: 0.04] | Drag: 7.98 | LOC: 430/94  Hotspot: Lines 182-186 (AI Context Fog (score 86.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/SceneHelpers.res** - [Nesting: 1.05, Density: 0.16, Deps: 0.05] | Drag: 6.84 | LOC: 264/106  Hotspot: Lines 196-200 (AI Context Fog (score 41.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Schemas.res** - [Nesting: 0.90, Density: 0.24, Deps: 0.02] | Drag: 6.62 | LOC: 386/110  Hotspot: Lines 385-389 (AI Context Fog (score 27.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
