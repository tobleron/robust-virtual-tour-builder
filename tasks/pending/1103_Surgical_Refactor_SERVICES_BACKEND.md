# Task 1103: Surgical Refactor SERVICES BACKEND

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

- [ ] - **../../backend/src/services/shutdown.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 162))

- [ ] - **../../backend/src/services/upload_quota.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 298))
