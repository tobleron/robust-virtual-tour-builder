# Task 1092: Surgical Refactor COMPONENTS FRONTEND

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
- [ ] **../../src/components/ViewerManagerLogic.res**
    - **Metric:** [Nesting: 1.20, Density: 0.24, Deps: 0.21] | Drag: 8.81 | LOC: 314/80  Hotspot: Lines 185-189
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/components/PreviewArrow.res**
    - **Metric:** [Nesting: 0.90, Density: 0.22, Deps: 0.03] | Drag: 8.19 | LOC: 194/164  Hotspot: Lines 137-141
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/components/VisualPipeline.res**
    - **Metric:** [Nesting: 1.35, Density: 0.14, Deps: 0.24] | Drag: 5.85 | LOC: 365/181  Hotspot: Lines 242-246
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/components/ModalContext.res**
    - **Metric:** [Nesting: 1.05, Density: 0.34, Deps: 0.09] | Drag: 11.83 | LOC: 170/119  Hotspot: Lines 113-117
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/components/Sidebar.res**
    - **Metric:** [Nesting: 1.20, Density: 0.00, Deps: 0.01] | Drag: 2.20 | LOC: 569/446  Hotspot: Lines 103-107
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/components/SceneList.res**
    - **Metric:** [Nesting: 1.05, Density: 0.07, Deps: 0.06] | Drag: 3.55 | LOC: 416/299  Hotspot: Lines 436-440
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
- [ ] **../../src/components/HotspotManager.res**
    - **Metric:** [Nesting: 0.60, Density: 0.18, Deps: 0.14] | Drag: 5.83 | LOC: 115/111  Hotspot: Lines 109-113
    - **Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.
