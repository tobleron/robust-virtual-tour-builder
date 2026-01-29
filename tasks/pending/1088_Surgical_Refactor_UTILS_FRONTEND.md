# Task 1088: Surgical Refactor UTILS FRONTEND

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

- [ ] - **../../src/utils/Constants.res** (Metric: [Nesting: 0.45, Density: 0.03, Deps: 0.00] | Drag: 2.05 | LOC: 185/136  Hotspot: Lines 216-220)

- [ ] - **../../src/utils/ImageOptimizer.res** (Metric: [Nesting: 1.05, Density: 0.03, Deps: 0.16] | Drag: 3.06 | LOC: 92/90  Hotspot: Lines 59-63)

- [ ] - **../../src/utils/LazyLoad.res** (Metric: [Nesting: 1.20, Density: 0.10, Deps: 0.16] | Drag: 4.46 | LOC: 87/80  Hotspot: Lines 30-34)

- [ ] - **../../src/utils/Logger.res** (Metric: [Nesting: 0.90, Density: 0.13, Deps: 0.02] | Drag: 5.24 | LOC: 492/80  Hotspot: Lines 175-179)

- [ ] - **../../src/utils/PathInterpolation.res** (Metric: [Nesting: 1.20, Density: 0.13, Deps: 0.06] | Drag: 5.11 | LOC: 236/80  Hotspot: Lines 109-113)

- [ ] - **../../src/utils/ProgressBar.res** (Metric: [Nesting: 0.90, Density: 0.25, Deps: 0.14] | Drag: 5.79 | LOC: 109/80  Hotspot: Lines 100-104)

