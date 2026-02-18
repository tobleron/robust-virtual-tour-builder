# Task D007: Surgical Refactor COMPONENTS FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 1.80 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions. 🏗️ ARCHITECTURAL TARGET: Split into exactly 2 cohesive modules to respect the Read Tax (avg 300 LOC/module).

- [ ] - **../../src/components/ViewerManagerLogic.res** (Metric: [Nesting: 3.00, Density: 0.12, Coupling: 0.08] | Drag: 4.12 | LOC: 377/300  🎯 Target: Function: `isLastIdValid` (High Local Complexity (3.0). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D007/verification.json` (files at `_dev-system/tmp/D007/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D007/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/ViewerManagerLogic.res`
- `src/components/ViewerManagerLogic.res` (9 functions, fingerprint 0fea42f43f3083e336ee539f610f377531e76d509de51e084ee2eb457f931023)
    - Grouped summary:
        - handleMainSceneLoad × 1 (lines: 66)
        - useHotspotLineLoop × 1 (lines: 247)
        - useHotspotSync × 1 (lines: 172)
        - useIntroPan × 1 (lines: 375)
        - useMainSceneLoading × 1 (lines: 145)
        - usePreloading × 1 (lines: 40)
        - useRatchetState × 1 (lines: 212)
        - useSceneCleanup × 1 (lines: 11)
        - useSimulationArrival × 1 (lines: 237)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
