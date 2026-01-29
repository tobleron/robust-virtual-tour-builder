# Task 1080: Surgical Refactor Batch 1 FRONTEND

## Objective
### 📚 Complexity Legend
* **Nesting:** Nesting depth penalty (Weight: 0.15).
* **Density:** Logic density (branching/loops) (Weight: 2.00).
* **Deps:** External dependency pressure.

### 🎯 General Instruction
Reduce the complexity variables for the following files to reach a Drag factor below 2.00. 
You have full architectural autonomy on how to split, extract, or simplify the code to achieve this goal while maintaining logic integrity.

## Tasks
- [ ] **../../src/ReBindings.res** - [Nesting: 0.60, Density: 0.00, Deps: 0.00] | Drag: 4.10 | LOC: 350/49  Hotspot: Lines 233-237 (AI Context Fog (score 12.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Reducer.res** - [Nesting: 1.50, Density: 0.42, Deps: 0.04] | Drag: 48.22 | LOC: 430/30  Hotspot: Lines 182-186 (AI Context Fog (score 86.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/ViewerState.res** - [Nesting: 0.30, Density: 0.09, Deps: 0.01] | Drag: 39.19 | LOC: 70/30  Hotspot: Lines 18-22 (AI Context Fog (score 26.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Actions.res** - [Nesting: 0.15, Density: 1.85, Deps: 0.01] | Drag: 51.80 | LOC: 105/30  Hotspot: Lines 55-59 (AI Context Fog (score 3.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/SceneHelpers.res** - [Nesting: 1.05, Density: 0.32, Deps: 0.05] | Drag: 26.82 | LOC: 264/30  Hotspot: Lines 196-200 (AI Context Fog (score 41.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/UiHelpers.res** - [Nesting: 0.75, Density: 0.50, Deps: 0.05] | Drag: 18.15 | LOC: 40/30  Hotspot: Lines 25-29 (AI Context Fog (score 17.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/SharedTypes.res** - [Nesting: 0.30, Density: 0.00, Deps: 0.00] | Drag: 19.30 | LOC: 132/30  Hotspot: Lines 6-10 (AI Context Fog (score 26.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/AppContext.res** - [Nesting: 0.90, Density: 0.09, Deps: 0.05] | Drag: 5.59 | LOC: 135/30  Hotspot: Lines 85-89 (AI Context Fog (score 36.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Types.res** - [Nesting: 0.15, Density: 0.15, Deps: 0.00] | Drag: 8.30 | LOC: 193/30
- [ ] **../../src/core/Schemas.res** - [Nesting: 0.90, Density: 0.48, Deps: 0.02] | Drag: 36.93 | LOC: 386/30  Hotspot: Lines 385-389 (AI Context Fog (score 27.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/AuthContext.res** - [Nesting: 0.90, Density: 0.39, Deps: 0.08] | Drag: 7.69 | LOC: 76/30  Hotspot: Lines 42-46 (AI Context Fog (score 29.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/SceneCache.res** - [Nesting: 0.30, Density: 0.34, Deps: 0.23] | Drag: 5.24 | LOC: 35/30  Hotspot: Lines 4-8 (AI Context Fog (score 6.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/ServiceWorkerMain.res** - [Nesting: 1.20, Density: 0.00, Deps: 0.00] | Drag: 2.20 | LOC: 164/91  Hotspot: Lines 169-173 (AI Context Fog (score 61.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/GeoUtils.res** - [Nesting: 0.90, Density: 0.07, Deps: 0.00] | Drag: 3.77 | LOC: 83/30  Hotspot: Lines 67-71 (AI Context Fog (score 29.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/PersistenceLayer.res** - [Nesting: 0.60, Density: 0.36, Deps: 0.09] | Drag: 9.26 | LOC: 66/30  Hotspot: Lines 38-42 (AI Context Fog (score 11.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
