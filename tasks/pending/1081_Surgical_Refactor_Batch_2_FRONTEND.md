# Task 1081: Surgical Refactor Batch 2 FRONTEND

## Objective
### 📚 Complexity Legend
* **Nesting:** Nesting depth penalty (Weight: 0.15).
* **Density:** Logic density (branching/loops) (Weight: 2.00).
* **Deps:** External dependency pressure.

### 🎯 General Instruction
Reduce the complexity variables for the following files to reach a Drag factor below 2.00. 
You have full architectural autonomy on how to split, extract, or simplify the code to achieve this goal while maintaining logic integrity.

## Tasks
- [ ] **../../src/utils/ProgressBar.res** - [Nesting: 0.90, Density: 0.51, Deps: 0.14] | Drag: 10.36 | LOC: 106/30  Hotspot: Lines 111-115 (AI Context Fog (score 37.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ColorPalette.res** - [Nesting: 0.75, Density: 0.65, Deps: 0.00] | Drag: 11.40 | LOC: 46/30  Hotspot: Lines 22-26 (AI Context Fog (score 25.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/StateInspector.res** - [Nesting: 0.90, Density: 0.11, Deps: 0.03] | Drag: 4.81 | LOC: 88/30  Hotspot: Lines 67-71 (AI Context Fog (score 25.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/TourLogic.res** - [Nesting: 0.90, Density: 0.03, Deps: 0.00] | Drag: 2.03 | LOC: 129/103  Hotspot: Lines 75-79 (AI Context Fog (score 32.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Logger.res** - [Nesting: 0.90, Density: 0.25, Deps: 0.02] | Drag: 33.75 | LOC: 492/30  Hotspot: Lines 175-179 (AI Context Fog (score 31.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ImageOptimizer.res** - [Nesting: 1.05, Density: 0.07, Deps: 0.16] | Drag: 3.92 | LOC: 92/30  Hotspot: Lines 59-63 (AI Context Fog (score 49.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/LazyLoad.res** - [Nesting: 1.20, Density: 0.21, Deps: 0.16] | Drag: 6.16 | LOC: 87/30  Hotspot: Lines 30-34 (AI Context Fog (score 58.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/PathInterpolation.res** - [Nesting: 1.20, Density: 0.26, Deps: 0.06] | Drag: 15.56 | LOC: 236/30  Hotspot: Lines 109-113 (AI Context Fog (score 64.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ProjectionMath.res** - [Nesting: 0.60, Density: 0.11, Deps: 0.02] | Drag: 4.51 | LOC: 88/30  Hotspot: Lines 104-108 (AI Context Fog (score 14.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/RequestQueue.res** - [Nesting: 0.75, Density: 0.35, Deps: 0.11] | Drag: 5.15 | LOC: 57/30  Hotspot: Lines 43-47 (AI Context Fog (score 27.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Constants.res** - [Nesting: 0.45, Density: 0.06, Deps: 0.00] | Drag: 3.61 | LOC: 185/30  Hotspot: Lines 216-220 (AI Context Fog (score 6.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/SessionStore.res** - [Nesting: 0.75, Density: 0.79, Deps: 0.01] | Drag: 10.49 | LOC: 84/30  Hotspot: Lines 53-57 (AI Context Fog (score 29.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/NotificationLayer.res** - [Nesting: 1.05, Density: 0.20, Deps: 0.03] | Drag: 5.85 | LOC: 59/36  Hotspot: Lines 38-42 (AI Context Fog (score 49.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/LabelMenu.res** - [Nesting: 1.05, Density: 0.17, Deps: 0.05] | Drag: 6.22 | LOC: 169/32  Hotspot: Lines 134-138 (AI Context Fog (score 43.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/HotspotManager.res** - [Nesting: 0.60, Density: 0.37, Deps: 0.14] | Drag: 11.27 | LOC: 115/30  Hotspot: Lines 109-113 (AI Context Fog (score 16.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/UploadReport.res** - [Nesting: 1.05, Density: 0.10, Deps: 0.07] | Drag: 7.55 | LOC: 189/30  Hotspot: Lines 91-95 (AI Context Fog (score 36.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/HotspotActionMenu.res** - [Nesting: 0.90, Density: 0.41, Deps: 0.03] | Drag: 20.31 | LOC: 147/30  Hotspot: Lines 84-88 (AI Context Fog (score 38.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/QualityIndicator.res** - [Nesting: 0.75, Density: 0.33, Deps: 0.04] | Drag: 5.78 | LOC: 48/36  Hotspot: Lines 44-48 (AI Context Fog (score 14.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ViewerSnapshot.res** - [Nesting: 1.20, Density: 0.67, Deps: 0.07] | Drag: 13.67 | LOC: 54/30  Hotspot: Lines 41-45 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/PopOver.res** - [Nesting: 0.90, Density: 0.50, Deps: 0.09] | Drag: 20.15 | LOC: 147/30  Hotspot: Lines 50-54 (AI Context Fog (score 29.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/Sidebar.res** - [Nesting: 1.20, Density: 0.00, Deps: 0.01] | Drag: 2.20 | LOC: 569/160  Hotspot: Lines 103-107 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/PreviewArrow.res** - [Nesting: 1.20, Density: 0.45, Deps: 0.03] | Drag: 26.20 | LOC: 188/30  Hotspot: Lines 90-94 (AI Context Fog (score 66.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
