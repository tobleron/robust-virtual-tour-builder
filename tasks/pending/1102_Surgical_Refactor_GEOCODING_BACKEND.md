# Task 1102: Surgical Refactor GEOCODING BACKEND

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

- [ ] - **../../backend/src/services/geocoding/logic.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 129))

- [ ] - **../../backend/src/services/geocoding/mod.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 246))
