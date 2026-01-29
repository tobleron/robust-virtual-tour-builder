# Task 1080: Surgical Refactor Batch 1 FRONTEND

## Objective
### 📚 Complexity Legend
* **Nesting:** Nesting depth penalty (Weight: 0.15).
* **Density:** Logic density (branching/loops) (Weight: 1.00).
* **Deps:** External dependency pressure.

### 🎯 General Instruction
Reduce the complexity variables for the following files to reach a Drag factor below 2.00. 
You have full architectural autonomy on how to split, extract, or simplify the code to achieve this goal while maintaining logic integrity.

## Tasks
- [ ] **../../src/utils/SessionStore.res** - [Nesting: 0.75, Density: 0.39, Deps: 0.01] | Drag: 6.88 | LOC: 84/80  Hotspot: Lines 53-57 (AI Context Fog (score 29.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Logger.res** - [Nesting: 0.90, Density: 0.13, Deps: 0.02] | Drag: 5.24 | LOC: 492/80  Hotspot: Lines 175-179 (AI Context Fog (score 31.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ImageOptimizer.res** - [Nesting: 1.05, Density: 0.03, Deps: 0.16] | Drag: 3.06 | LOC: 92/89  Hotspot: Lines 59-63 (AI Context Fog (score 49.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ProgressBar.res** - [Nesting: 0.90, Density: 0.25, Deps: 0.14] | Drag: 5.90 | LOC: 106/80  Hotspot: Lines 111-115 (AI Context Fog (score 37.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/LazyLoad.res** - [Nesting: 1.20, Density: 0.10, Deps: 0.16] | Drag: 4.46 | LOC: 87/80  Hotspot: Lines 30-34 (AI Context Fog (score 58.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/PathInterpolation.res** - [Nesting: 1.20, Density: 0.13, Deps: 0.06] | Drag: 5.11 | LOC: 236/80  Hotspot: Lines 109-113 (AI Context Fog (score 64.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Constants.res** - [Nesting: 0.45, Density: 0.03, Deps: 0.00] | Drag: 2.05 | LOC: 185/134  Hotspot: Lines 216-220 (AI Context Fog (score 6.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ViewerManagerLogic.res** - [Nesting: 1.20, Density: 0.23, Deps: 0.22] | Drag: 8.93 | LOC: 307/80  Hotspot: Lines 183-187 (AI Context Fog (score 61.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/SceneList.res** - [Nesting: 1.05, Density: 0.08, Deps: 0.06] | Drag: 3.57 | LOC: 413/298  Hotspot: Lines 433-437 (AI Context Fog (score 51.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/Sidebar.res** - [Nesting: 1.20, Density: 0.00, Deps: 0.01] | Drag: 2.20 | LOC: 569/446  Hotspot: Lines 103-107 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/VisualPipeline.res** - [Nesting: 1.35, Density: 0.14, Deps: 0.24] | Drag: 6.05 | LOC: 365/176  Hotspot: Lines 242-246 (AI Context Fog (score 83.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ModalContext.res** - [Nesting: 1.35, Density: 0.34, Deps: 0.09] | Drag: 12.36 | LOC: 166/115  Hotspot: Lines 77-81 (AI Context Fog (score 81.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/PreviewArrow.res** - [Nesting: 1.20, Density: 0.22, Deps: 0.03] | Drag: 8.69 | LOC: 188/157  Hotspot: Lines 90-94 (AI Context Fog (score 66.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/HotspotManager.res** - [Nesting: 0.60, Density: 0.18, Deps: 0.14] | Drag: 5.83 | LOC: 115/111  Hotspot: Lines 109-113 (AI Context Fog (score 16.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Teaser.res** - [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 3.72 | LOC: 572/168  Hotspot: Lines 585-589 (AI Context Fog (score 65.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ExifReportGenerator.res** - [Nesting: 1.65, Density: 0.00, Deps: 0.00] | Drag: 2.65 | LOC: 542/222  Hotspot: Lines 204-208 (AI Context Fog (score 121.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Api.res** - [Nesting: 1.35, Density: 0.01, Deps: 0.03] | Drag: 2.53 | LOC: 592/225  Hotspot: Lines 601-605 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationRenderer.res** - [Nesting: 1.80, Density: 0.14, Deps: 0.08] | Drag: 6.79 | LOC: 248/104  Hotspot: Lines 206-210 (AI Context Fog (score 125.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/LinkEditorLogic.res** - [Nesting: 0.90, Density: 0.19, Deps: 0.09] | Drag: 7.29 | LOC: 122/97  Hotspot: Lines 123-127 (AI Context Fog (score 38.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Scene.res** - [Nesting: 1.05, Density: 0.14, Deps: 0.10] | Drag: 3.93 | LOC: 332/154  Hotspot: Lines 224-228 (AI Context Fog (score 39.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Exporter.res** - [Nesting: 1.35, Density: 0.08, Deps: 0.13] | Drag: 4.38 | LOC: 205/139  Hotspot: Lines 55-59 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/SvgManager.res** - [Nesting: 0.90, Density: 0.24, Deps: 0.19] | Drag: 8.83 | LOC: 191/80  Hotspot: Lines 164-168 (AI Context Fog (score 40.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Resizer.res** - [Nesting: 1.35, Density: 0.26, Deps: 0.11] | Drag: 8.01 | LOC: 300/89  Hotspot: Lines 217-221 (AI Context Fog (score 55.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
