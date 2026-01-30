# Task 1119: Surgical Refactor COMPONENTS FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 2.00 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🚨 Hotspots (Focus Area)
The following regions are calculated to be the most confusing for AI:

## Tasks

### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../src/components/SceneList.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 416))

- [ ] - **../../src/components/VisualPipeline.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 365))


### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/components/Sidebar.res** (Metric: [Nesting: 1.20, Density: 0.00, Coupling: 0.00] | Drag: 2.22 | LOC: 569/500  Hotspot: Lines 103-107)

