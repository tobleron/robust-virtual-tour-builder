# Task 1090: Surgical Refactor API BACKEND

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

- [ ] - **../../backend/src/api/project.rs** (Metric: [Nesting: 0.75, Density: 0.04, Deps: 0.00] | Drag: 2.19 | LOC: 375/357)


### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../backend/src/api/geocoding.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 153))

- [ ] - **../../backend/src/api/project.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 375))

- [ ] - **../../backend/src/api/project_logic.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 181))

- [ ] - **../../backend/src/api/telemetry.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 154))
