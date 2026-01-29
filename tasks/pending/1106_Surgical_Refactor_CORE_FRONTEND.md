# Task 1106: Surgical Refactor CORE FRONTEND

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

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 1.20, Density: 0.21, Coupling: 0.26] | Drag: 2.85 | LOC: 433/250  Hotspot: Lines 191-195)

- [ ] - **../../src/core/SceneHelpers.res** (Metric: [Nesting: 1.05, Density: 0.15, Coupling: 0.36] | Drag: 2.60 | LOC: 271/250  Hotspot: Lines 204-208)

- [ ] - **../../src/core/Schemas.res** (Metric: [Nesting: 0.90, Density: 0.25, Coupling: 1.06] | Drag: 3.72 | LOC: 373/250  Hotspot: Lines 390-394)


### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../src/core/AuthContext.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 76))

