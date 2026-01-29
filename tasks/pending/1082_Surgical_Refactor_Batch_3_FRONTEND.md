# Task 1082: Surgical Refactor Batch 3 FRONTEND

## Objective
### 📚 Complexity Legend
* **Nesting:** Nesting depth penalty (Weight: 0.15).
* **Density:** Logic density (branching/loops) (Weight: 2.00).
* **Deps:** External dependency pressure.

### 🎯 General Instruction
Reduce the complexity variables for the following files to reach a Drag factor below 2.00. 
You have full architectural autonomy on how to split, extract, or simplify the code to achieve this goal while maintaining logic integrity.

## Tasks
- [ ] **../../src/components/VisualPipeline.res** - [Nesting: 1.35, Density: 0.28, Deps: 0.24] | Drag: 28.63 | LOC: 365/30  Hotspot: Lines 242-246 (AI Context Fog (score 83.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/HotspotMenuLayer.res** - [Nesting: 0.90, Density: 0.24, Deps: 0.04] | Drag: 5.74 | LOC: 51/37  Hotspot: Lines 21-25 (AI Context Fog (score 25.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/FloorNavigation.res** - [Nesting: 0.90, Density: 0.25, Deps: 0.06] | Drag: 5.85 | LOC: 63/35  Hotspot: Lines 59-63 (AI Context Fog (score 27.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ViewerManagerLogic.res** - [Nesting: 1.20, Density: 0.47, Deps: 0.22] | Drag: 42.57 | LOC: 307/30  Hotspot: Lines 183-187 (AI Context Fog (score 61.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ReturnPrompt.res** - [Nesting: 0.75, Density: 0.33, Deps: 0.11] | Drag: 7.53 | LOC: 61/30  Hotspot: Lines 25-29 (AI Context Fog (score 28.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/UtilityBar.res** - [Nesting: 0.60, Density: 0.10, Deps: 0.09] | Drag: 5.30 | LOC: 116/40  Hotspot: Lines 25-29 (AI Context Fog (score 18.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/SceneList.res** - [Nesting: 1.05, Density: 0.15, Deps: 0.06] | Drag: 14.10 | LOC: 413/30  Hotspot: Lines 433-437 (AI Context Fog (score 51.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/LinkModal.res** - [Nesting: 1.50, Density: 0.05, Deps: 0.01] | Drag: 2.75 | LOC: 175/114  Hotspot: Lines 135-139 (AI Context Fog (score 100.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ModalContext.res** - [Nesting: 1.35, Density: 0.69, Deps: 0.09] | Drag: 35.14 | LOC: 166/30  Hotspot: Lines 77-81 (AI Context Fog (score 81.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/ServiceWorker.res** - [Nesting: 0.90, Density: 0.44, Deps: 0.08] | Drag: 8.24 | LOC: 87/30  Hotspot: Lines 79-83 (AI Context Fog (score 36.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/i18n/I18n.res** - [Nesting: 0.60, Density: 0.36, Deps: 0.00] | Drag: 6.11 | LOC: 44/30  Hotspot: Lines 45-49 (AI Context Fog (score 16.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Resizer.res** - [Nesting: 1.35, Density: 0.52, Deps: 0.11] | Drag: 35.27 | LOC: 300/30  Hotspot: Lines 217-221 (AI Context Fog (score 55.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/VideoEncoder.res** - [Nesting: 1.35, Density: 0.32, Deps: 0.17] | Drag: 10.07 | LOC: 100/30  Hotspot: Lines 57-61 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/SvgManager.res** - [Nesting: 0.90, Density: 0.48, Deps: 0.19] | Drag: 27.93 | LOC: 191/30  Hotspot: Lines 164-168 (AI Context Fog (score 40.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationFSM.res** - [Nesting: 0.60, Density: 0.94, Deps: 0.01] | Drag: 21.64 | LOC: 79/30  Hotspot: Lines 52-56 (AI Context Fog (score 13.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/LinkEditorLogic.res** - [Nesting: 0.90, Density: 0.38, Deps: 0.09] | Drag: 14.98 | LOC: 122/30  Hotspot: Lines 123-127 (AI Context Fog (score 38.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/TourTemplates.res** - [Nesting: 1.05, Density: 0.11, Deps: 0.01] | Drag: 2.76 | LOC: 217/65  Hotspot: Lines 223-227 (AI Context Fog (score 19.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
