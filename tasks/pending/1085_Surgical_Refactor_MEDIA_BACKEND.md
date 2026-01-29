# Task 1085: Surgical Refactor MEDIA BACKEND

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
- [ ] **../../backend/src/api/media/video.rs**
    - **Metric:** [Nesting: 0.75, Density: 0.05, Deps: 0.00] | Drag: 2.65 | LOC: 372/305
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../backend/src/api/media/image.rs**
    - **Metric:** [Nesting: 0.75, Density: 0.03, Deps: 0.00] | Drag: 2.75 | LOC: 482/297
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../backend/src/api/media/image.rs**
    - **Metric:** [Nesting: 0.75, Density: 0.03, Deps: 0.00] | Drag: 2.75 | LOC: 482/296
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../backend/src/api/media/video.rs**
    - **Metric:** [Nesting: 0.75, Density: 0.05, Deps: 0.00] | Drag: 2.65 | LOC: 372/304
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
