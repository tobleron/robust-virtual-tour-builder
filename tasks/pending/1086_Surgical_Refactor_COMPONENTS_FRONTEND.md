# Task 1086: Surgical Refactor COMPONENTS FRONTEND

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

- [ ] - **../../src/components/HotspotManager.res** (Metric: [Nesting: 0.60, Density: 0.18, Deps: 0.14] | Drag: 5.83 | LOC: 115/113  Hotspot: Lines 109-113)

- [ ] - **../../src/components/ModalContext.res** (Metric: [Nesting: 1.05, Density: 0.34, Deps: 0.09] | Drag: 11.83 | LOC: 170/120  Hotspot: Lines 113-117)

- [ ] - **../../src/components/PreviewArrow.res** (Metric: [Nesting: 0.90, Density: 0.22, Deps: 0.03] | Drag: 8.19 | LOC: 194/166  Hotspot: Lines 137-141)

- [ ] - **../../src/components/SceneList.res** (Metric: [Nesting: 1.05, Density: 0.07, Deps: 0.06] | Drag: 3.55 | LOC: 416/303  Hotspot: Lines 436-440)

- [ ] - **../../src/components/Sidebar.res** (Metric: [Nesting: 1.20, Density: 0.00, Deps: 0.01] | Drag: 2.20 | LOC: 569/451  Hotspot: Lines 103-107)

- [ ] - **../../src/components/ViewerManagerLogic.res** (Metric: [Nesting: 1.20, Density: 0.24, Deps: 0.21] | Drag: 8.81 | LOC: 314/80  Hotspot: Lines 185-189)

- [ ] - **../../src/components/VisualPipeline.res** (Metric: [Nesting: 1.35, Density: 0.14, Deps: 0.24] | Drag: 5.85 | LOC: 365/183  Hotspot: Lines 242-246)

- [ ] - **../../src/components/SceneList.res** (Metric: [Nesting: 1.05, Density: 0.07, Deps: 0.06] | Drag: 2.42 | LOC: 416/404  Hotspot: Lines 436-440)

- [ ] - **../../src/components/ViewerManagerLogic.res** (Metric: [Nesting: 1.20, Density: 0.24, Deps: 0.21] | Drag: 3.84 | LOC: 314/146  Hotspot: Lines 185-189)

- [ ] - **../../src/components/VisualPipeline.res** (Metric: [Nesting: 1.35, Density: 0.14, Deps: 0.24] | Drag: 3.22 | LOC: 365/287  Hotspot: Lines 242-246)

- [ ] - **../../src/components/ViewerManagerLogic.res** (Metric: [Nesting: 1.20, Density: 0.24, Deps: 0.21] | Drag: 3.00 | LOC: 314/176  Hotspot: Lines 185-189)

- [ ] - **../../src/components/VisualPipeline.res** (Metric: [Nesting: 1.35, Density: 0.14, Deps: 0.24] | Drag: 2.78 | LOC: 365/320  Hotspot: Lines 242-246)

- [ ] - **../../src/components/ViewerManagerLogic.res** (Metric: [Nesting: 1.20, Density: 0.24, Deps: 0.21] | Drag: 3.00 | LOC: 314/180  Hotspot: Lines 185-189)

- [ ] - **../../src/components/ViewerManagerLogic.res** (Metric: [Nesting: 1.20, Density: 0.24, Deps: 0.21] | Drag: 3.00 | LOC: 314/250  Hotspot: Lines 185-189)

- [ ] - **../../src/components/Sidebar.res** (Metric: [Nesting: 1.20, Density: 0.00, Deps: 0.01] | Drag: 2.20 | LOC: 569/450  Hotspot: Lines 103-107)

- [ ] - **../../src/components/VisualPipeline.res** (Metric: [Nesting: 1.35, Density: 0.14, Deps: 0.24] | Drag: 2.78 | LOC: 365/319  Hotspot: Lines 242-246)

- [ ] - **../../css/components/viewer.css** (Metric: [Nesting: 0.30, Density: 0.11, Deps: 0.00] | Drag: 1.87 | LOC: 627/510)


### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../src/components/AppErrorBoundary.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 58))

- [ ] - **../../src/components/FloorNavigation.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 63))

- [ ] - **../../src/components/HotspotActionMenu.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 147))

- [ ] - **../../src/components/HotspotManager.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 115))

- [ ] - **../../src/components/HotspotMenuLayer.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 51))

- [ ] - **../../src/components/LabelMenu.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 169))

- [ ] - **../../src/components/LinkModal.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 175))

- [ ] - **../../src/components/ModalContext.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 170))

- [ ] - **../../src/components/NotificationLayer.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 59))

- [ ] - **../../src/components/PopOver.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 147))

- [ ] - **../../src/components/PreviewArrow.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 194))

- [ ] - **../../src/components/ReturnPrompt.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 61))

- [ ] - **../../src/components/SceneList.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 416))

- [ ] - **../../src/components/Sidebar.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 569))

- [ ] - **../../src/components/UploadReport.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 189))

- [ ] - **../../src/components/UtilityBar.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 119))

- [ ] - **../../src/components/ViewerManagerLogic.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 314))

- [ ] - **../../src/components/ViewerSnapshot.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 57))

- [ ] - **../../src/components/VisualPipeline.res** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 365))

- [ ] - **../../css/components/buttons.css** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 124))

- [ ] - **../../css/components/error-fallback.css** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 55))

- [ ] - **../../css/components/label-menu.css** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 150))

- [ ] - **../../css/components/modals.css** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 109))

- [ ] - **../../css/components/ui.css** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 179))

- [ ] - **../../css/components/upload-report.css** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 189))

- [ ] - **../../css/components/viewer.css** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 627))

- [ ] - **../../src/components/Sidebar.res** (Metric: [Nesting: 1.20, Density: 0.00, Coupling: 0.00] | Drag: 2.20 | LOC: 569/453  Hotspot: Lines 103-107)

- [ ] - **../../src/components/ViewerManagerLogic.res** (Metric: [Nesting: 1.20, Density: 0.24, Coupling: 0.21] | Drag: 3.00 | LOC: 314/250  Hotspot: Lines 185-189)
- [ ] - **../../src/components/ViewerManagerLogic.res** (Metric: [Nesting: 1.20, Density: 0.24, Coupling: 0.39] | Drag: 3.00 | LOC: 314/250  Hotspot: Lines 185-189)

- [ ] - **../../src/components/ViewerManagerLogic.res** (Metric: [Nesting: 1.20, Density: 0.24, Coupling: 0.56] | Drag: 3.00 | LOC: 314/250  Hotspot: Lines 185-189)

- [ ] - **../../src/components/SceneList.res** (Metric: [Nesting: 1.05, Density: 0.07, Coupling: 0.43] | Drag: 2.24 | LOC: 416/319  Hotspot: Lines 436-440)

- [ ] - **../../src/components/Sidebar.res** (Metric: [Nesting: 1.20, Density: 0.00, Coupling: 0.30] | Drag: 2.20 | LOC: 569/363  Hotspot: Lines 103-107)

- [ ] - **../../src/components/ViewerManagerLogic.res** (Metric: [Nesting: 1.20, Density: 0.24, Coupling: 0.57] | Drag: 3.00 | LOC: 314/250  Hotspot: Lines 185-189)

- [ ] - **../../src/components/VisualPipeline.res** (Metric: [Nesting: 1.35, Density: 0.14, Coupling: 0.47] | Drag: 2.78 | LOC: 365/260  Hotspot: Lines 242-246)

- [ ] - **../../src/components/Sidebar.res** (Metric: [Nesting: 1.20, Density: 0.00, Coupling: 0.30] | Drag: 2.20 | LOC: 569/361  Hotspot: Lines 103-107)

- [ ] - **../../src/components/VisualPipeline.res** (Metric: [Nesting: 1.35, Density: 0.14, Coupling: 0.48] | Drag: 2.78 | LOC: 365/259  Hotspot: Lines 242-246)

