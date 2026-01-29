# Task 1108: Surgical Refactor COMPONENTS FRONTEND

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

- [ ] - **../../src/components/SceneList.res** (Metric: [Nesting: 1.05, Density: 0.07, Coupling: 0.43] | Drag: 2.24 | LOC: 416/400  Hotspot: Lines 436-440)

- [ ] - **../../src/components/Sidebar.res** (Metric: [Nesting: 1.20, Density: 0.00, Coupling: 0.30] | Drag: 2.20 | LOC: 569/400  Hotspot: Lines 103-107)

