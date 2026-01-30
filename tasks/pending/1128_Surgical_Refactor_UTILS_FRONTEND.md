# Task 1128: Surgical Refactor UTILS FRONTEND

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

- [ ] - **../../src/utils/Constants.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 185))

- [ ] - **../../src/utils/ImageOptimizer.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 92))

- [ ] - **../../src/utils/LazyLoad.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 87))

- [ ] - **../../src/utils/Logger.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 492))

- [ ] - **../../src/utils/PersistenceLayer.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 66))

- [ ] - **../../src/utils/ProgressBar.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 109))

- [ ] - **../../src/utils/ProjectionMath.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 88))

- [ ] - **../../src/utils/RequestQueue.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 57))

- [ ] - **../../src/utils/SessionStore.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 80))

- [ ] - **../../src/utils/StateInspector.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 88))
