# Task 1094: Surgical Refactor SRC FRONTEND

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

- [ ] - **../../src/ReBindings.res** (Metric: [Nesting: 0.60, Density: 0.00, Deps: 0.00] | Drag: 2.31 | LOC: 350/342  Hotspot: Lines 233-237)


### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../src/ServiceWorker.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 87))

- [ ] - **../../src/ServiceWorkerMain.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 164))
- [ ] - **../../src/ReBindings.res** (Metric: [Nesting: 0.60, Density: 0.00, Coupling: 0.21] | Drag: 1.89 | LOC: 350/344  Hotspot: Lines 233-237)

- [ ] - **../../src/ReBindings.res** (Metric: [Nesting: 0.60, Density: 0.00, Coupling: 0.32] | Drag: 1.89 | LOC: 350/314  Hotspot: Lines 233-237)

- [ ] - **../../src/ReBindings.res** (Metric: [Nesting: 0.60, Density: 0.00, Coupling: 0.34] | Drag: 1.89 | LOC: 350/309  Hotspot: Lines 233-237)

