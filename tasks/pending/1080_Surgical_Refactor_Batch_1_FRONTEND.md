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
- [ ] **../../src/components/SceneList.res** - [Nesting: 1.05, Density: 0.08, Deps: 0.06] | Drag: 3.57 | LOC: 413/298  Hotspot: Lines 433-437 (AI Context Fog (score 51.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Actions.res** - [Nesting: 0.15, Density: 0.92, Deps: 0.01] | Drag: 25.31 | LOC: 105/80  Hotspot: Lines 55-59 (AI Context Fog (score 3.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/PanoramaClusterer.res** - [Nesting: 1.20, Density: 0.29, Deps: 0.10] | Drag: 9.99 | LOC: 146/80  Hotspot: Lines 44-48 (AI Context Fog (score 64.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Scene.res** - [Nesting: 1.05, Density: 0.14, Deps: 0.10] | Drag: 3.93 | LOC: 332/154  Hotspot: Lines 224-228 (AI Context Fog (score 39.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/HotspotLine.res** - [Nesting: 1.35, Density: 0.13, Deps: 0.06] | Drag: 6.45 | LOC: 612/109  Hotspot: Lines 245-249 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/SceneHelpers.res** - [Nesting: 1.05, Density: 0.16, Deps: 0.05] | Drag: 6.84 | LOC: 264/105  Hotspot: Lines 196-200 (AI Context Fog (score 41.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Logger.res** - [Nesting: 0.90, Density: 0.13, Deps: 0.02] | Drag: 5.24 | LOC: 492/80  Hotspot: Lines 175-179 (AI Context Fog (score 31.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Constants.res** - [Nesting: 0.45, Density: 0.03, Deps: 0.00] | Drag: 2.05 | LOC: 185/134  Hotspot: Lines 216-220 (AI Context Fog (score 6.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ViewerManagerLogic.res** - [Nesting: 1.20, Density: 0.23, Deps: 0.22] | Drag: 8.93 | LOC: 307/80  Hotspot: Lines 183-187 (AI Context Fog (score 61.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Simulation.res** - [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 553/221  Hotspot: Lines 366-370 (AI Context Fog (score 124.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ImageOptimizer.res** - [Nesting: 1.05, Density: 0.03, Deps: 0.16] | Drag: 3.06 | LOC: 92/89  Hotspot: Lines 59-63 (AI Context Fog (score 49.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ViewerSystem.res** - [Nesting: 1.20, Density: 0.23, Deps: 0.06] | Drag: 8.87 | LOC: 272/86  Hotspot: Lines 168-172 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Schemas.res** - [Nesting: 0.90, Density: 0.24, Deps: 0.02] | Drag: 6.62 | LOC: 386/110  Hotspot: Lines 385-389 (AI Context Fog (score 27.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/LazyLoad.res** - [Nesting: 1.20, Density: 0.10, Deps: 0.16] | Drag: 4.46 | LOC: 87/80  Hotspot: Lines 30-34 (AI Context Fog (score 58.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationController.res** - [Nesting: 2.25, Density: 0.21, Deps: 0.11] | Drag: 9.59 | LOC: 193/80  Hotspot: Lines 162-166 (AI Context Fog (score 201.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/VisualPipeline.res** - [Nesting: 1.35, Density: 0.14, Deps: 0.24] | Drag: 6.05 | LOC: 365/176  Hotspot: Lines 242-246 (AI Context Fog (score 83.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/PreviewArrow.res** - [Nesting: 1.20, Density: 0.22, Deps: 0.03] | Drag: 8.69 | LOC: 188/157  Hotspot: Lines 90-94 (AI Context Fog (score 66.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ModalContext.res** - [Nesting: 1.35, Density: 0.34, Deps: 0.09] | Drag: 12.36 | LOC: 166/115  Hotspot: Lines 77-81 (AI Context Fog (score 81.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Resizer.res** - [Nesting: 1.35, Density: 0.26, Deps: 0.11] | Drag: 8.01 | LOC: 300/89  Hotspot: Lines 217-221 (AI Context Fog (score 55.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
