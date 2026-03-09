# Task D023: Surgical Refactor SYSTEMS SIMULATION FRONTEND

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
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/systems/Simulation/SimulationNavigation.res** (Metric: [Nesting: 3.60, Density: 0.10, Coupling: 0.08] | Drag: 4.70 | LOC: 261/300  ⚠️ Trigger: Drag above target (1.80) with file already at 261 LOC.  🎯 Target: Function: `start` (High Local Complexity (5.9). Logic heavy.)) → Refactor in-place


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D023/verification.json` (files at `_dev-system/tmp/D023/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D023/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Simulation/SimulationNavigation.res`
- `src/systems/Simulation/SimulationNavigation.res` (6 functions, fingerprint bc368da6d1eade3a359811dcbee2534ab40fe371ee337ca612ebee388f897d0a)
    - Grouped summary:
        - findBestNextLink × 1 (lines: 160)
        - findBestNextLinkByLinkId × 1 (lines: 223)
        - getActiveViewerForExpectedScene × 1 (lines: 15)
        - pickByPriority × 1 (lines: 119)
        - pollForViewer × 1 (lines: 19)
        - waitForViewerScene × 1 (lines: 51)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
