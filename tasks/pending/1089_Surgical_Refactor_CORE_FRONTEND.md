# Task 1089: Surgical Refactor CORE FRONTEND

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

- [ ] - **../../src/core/Actions.res** (Metric: [Nesting: 1.05, Density: 0.81, Deps: 0.01] | Drag: 24.35 | LOC: 155/80  Hotspot: Lines 155-159)

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.04] | Drag: 7.64 | LOC: 433/98  Hotspot: Lines 191-195)

- [ ] - **../../src/core/SceneHelpers.res** (Metric: [Nesting: 1.05, Density: 0.15, Deps: 0.04] | Drag: 6.72 | LOC: 271/108  Hotspot: Lines 204-208)

- [ ] - **../../src/core/Schemas.res** (Metric: [Nesting: 0.90, Density: 0.25, Deps: 0.02] | Drag: 6.78 | LOC: 373/205  Hotspot: Lines 390-394)

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.04] | Drag: 3.50 | LOC: 433/177  Hotspot: Lines 191-195)

- [ ] - **../../src/core/SceneHelpers.res** (Metric: [Nesting: 1.05, Density: 0.15, Deps: 0.04] | Drag: 3.20 | LOC: 271/189  Hotspot: Lines 204-208)

- [ ] - **../../src/core/Schemas.res** (Metric: [Nesting: 0.90, Density: 0.25, Deps: 0.02] | Drag: 6.06 | LOC: 373/223  Hotspot: Lines 390-394)

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.04] | Drag: 2.85 | LOC: 433/207  Hotspot: Lines 191-195)

- [ ] - **../../src/core/SceneHelpers.res** (Metric: [Nesting: 1.05, Density: 0.15, Deps: 0.04] | Drag: 2.60 | LOC: 271/221  Hotspot: Lines 204-208)

- [ ] - **../../src/core/Schemas.res** (Metric: [Nesting: 0.90, Density: 0.25, Deps: 0.02] | Drag: 3.72 | LOC: 373/322  Hotspot: Lines 390-394)

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 1.20, Density: 0.21, Deps: 0.04] | Drag: 2.85 | LOC: 433/250  Hotspot: Lines 191-195)

- [ ] - **../../src/core/SceneHelpers.res** (Metric: [Nesting: 1.05, Density: 0.15, Deps: 0.04] | Drag: 2.60 | LOC: 271/250  Hotspot: Lines 204-208)

- [ ] - **../../src/core/Schemas.res** (Metric: [Nesting: 0.90, Density: 0.25, Deps: 0.02] | Drag: 3.72 | LOC: 373/321  Hotspot: Lines 390-394)


### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../src/core/Actions.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 155))

- [ ] - **../../src/core/AppContext.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 135))

- [ ] - **../../src/core/AuthContext.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 76))

- [ ] - **../../src/core/Reducer.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 433))

- [ ] - **../../src/core/SceneHelpers.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 271))

- [ ] - **../../src/core/Schemas.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 373))

- [ ] - **../../src/core/SharedTypes.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 132))

- [ ] - **../../src/core/Types.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 200))

- [ ] - **../../src/core/ViewerState.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 70))
- [ ] - **../../src/core/Schemas.res** (Metric: [Nesting: 0.90, Density: 0.25, Coupling: 0.21] | Drag: 3.72 | LOC: 373/281  Hotspot: Lines 390-394)

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 1.20, Density: 0.21, Coupling: 0.19] | Drag: 2.85 | LOC: 433/250  Hotspot: Lines 191-195)

- [ ] - **../../src/core/SceneHelpers.res** (Metric: [Nesting: 1.05, Density: 0.15, Coupling: 0.35] | Drag: 2.60 | LOC: 271/250  Hotspot: Lines 204-208)

- [ ] - **../../src/core/Schemas.res** (Metric: [Nesting: 0.90, Density: 0.25, Coupling: 1.03] | Drag: 3.72 | LOC: 373/250  Hotspot: Lines 390-394)

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 1.20, Density: 0.21, Coupling: 0.26] | Drag: 2.85 | LOC: 433/250  Hotspot: Lines 191-195)

- [ ] - **../../src/core/Schemas.res** (Metric: [Nesting: 0.90, Density: 0.25, Coupling: 1.04] | Drag: 3.72 | LOC: 373/250  Hotspot: Lines 390-394)

- [ ] - **../../src/core/SceneHelpers.res** (Metric: [Nesting: 1.05, Density: 0.15, Coupling: 0.36] | Drag: 2.60 | LOC: 271/250  Hotspot: Lines 204-208)

- [ ] - **../../src/core/Schemas.res** (Metric: [Nesting: 0.90, Density: 0.25, Coupling: 1.06] | Drag: 3.72 | LOC: 373/250  Hotspot: Lines 390-394)

