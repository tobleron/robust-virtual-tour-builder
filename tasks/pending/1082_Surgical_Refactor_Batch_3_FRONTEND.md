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
- [ ] **../../src/systems/Simulation.res** - [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 553/97  Hotspot: Lines 366-370 (AI Context Fog (score 124.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ViewerSystem.res** - [Nesting: 1.20, Density: 0.46, Deps: 0.06] | Drag: 9.11 | LOC: 272/80  Hotspot: Lines 168-172 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationGraph.res** - [Nesting: 1.20, Density: 0.43, Deps: 0.06] | Drag: 7.28 | LOC: 121/80  Hotspot: Lines 92-96 (AI Context Fog (score 55.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Reducer.res** - [Nesting: 1.50, Density: 0.42, Deps: 0.04] | Drag: 8.19 | LOC: 430/80  Hotspot: Lines 182-186 (AI Context Fog (score 86.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Actions.res** - [Nesting: 0.15, Density: 1.85, Deps: 0.01] | Drag: 26.24 | LOC: 105/80  Hotspot: Lines 55-59 (AI Context Fog (score 3.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Schemas.res** - [Nesting: 0.90, Density: 0.48, Deps: 0.02] | Drag: 6.86 | LOC: 386/80  Hotspot: Lines 385-389 (AI Context Fog (score 27.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/AppContext.res** - [Nesting: 0.90, Density: 0.09, Deps: 0.05] | Drag: 3.32 | LOC: 135/80  Hotspot: Lines 85-89 (AI Context Fog (score 36.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/SceneHelpers.res** - [Nesting: 1.05, Density: 0.32, Deps: 0.05] | Drag: 7.00 | LOC: 264/80  Hotspot: Lines 196-200 (AI Context Fog (score 41.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Types.res** - [Nesting: 0.15, Density: 0.15, Deps: 0.00] | Drag: 3.11 | LOC: 193/152
- [ ] **../../src/core/SharedTypes.res** - [Nesting: 0.30, Density: 0.00, Deps: 0.00] | Drag: 8.12 | LOC: 132/80  Hotspot: Lines 6-10 (AI Context Fog (score 26.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
