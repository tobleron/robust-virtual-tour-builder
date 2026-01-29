# Task 1101: Surgical Refactor MIDDLEWARE BACKEND

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

- [ ] - **../../backend/src/middleware/auth.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 155))

- [ ] - **../../backend/src/middleware/quota_check.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 127))

- [ ] - **../../backend/src/middleware/request_tracker.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 90))
