# Task 1092: Surgical Refactor COMPONENTS FRONTEND

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
- [ ] **../../src/components/PreviewArrow.res** - [Nesting: 1.20, Density: 0.22, Deps: 0.03] | Drag: 8.69 | LOC: 188/157  Hotspot: Lines 90-94 (AI Context Fog (score 66.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/SceneList.res** - [Nesting: 1.05, Density: 0.08, Deps: 0.06] | Drag: 3.57 | LOC: 413/298  Hotspot: Lines 433-437 (AI Context Fog (score 51.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ModalContext.res** - [Nesting: 1.35, Density: 0.34, Deps: 0.09] | Drag: 12.36 | LOC: 166/115  Hotspot: Lines 77-81 (AI Context Fog (score 81.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/VisualPipeline.res** - [Nesting: 1.35, Density: 0.14, Deps: 0.24] | Drag: 6.05 | LOC: 365/176  Hotspot: Lines 242-246 (AI Context Fog (score 83.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ViewerManagerLogic.res** - [Nesting: 1.20, Density: 0.23, Deps: 0.22] | Drag: 8.93 | LOC: 307/80  Hotspot: Lines 183-187 (AI Context Fog (score 61.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/HotspotManager.res** - [Nesting: 0.60, Density: 0.18, Deps: 0.14] | Drag: 5.83 | LOC: 115/111  Hotspot: Lines 109-113 (AI Context Fog (score 16.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/Sidebar.res** - [Nesting: 1.20, Density: 0.00, Deps: 0.01] | Drag: 2.20 | LOC: 569/446  Hotspot: Lines 103-107 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
