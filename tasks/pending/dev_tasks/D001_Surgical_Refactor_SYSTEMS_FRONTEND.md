# Task D001: Surgical Refactor SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/TeaserLogic.res** (Metric: [Nesting: 3.00, Density: 0.05, Coupling: 0.10] | Drag: 4.05 | LOC: 384/300  🎯 Target: Function: `getConfigForStyle` (High Local Complexity (3.5). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D001/verification.json` (files at `_dev-system/tmp/D001/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D001/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/TeaserLogic.res`
- `src/systems/TeaserLogic.res` (17 functions, fingerprint ea7b9a17bc8669a89940630dd5886f485067e108ab5efacb8d95ae473461e0f9)
    - Grouped summary:
        - animatePan × 1 (lines: 76)
        - canvasHeight × 1 (lines: 9)
        - canvasWidth × 1 (lines: 8)
        - fastConfig × 1 (lines: 31)
        - finalizeTeaser × 1 (lines: 212)
        - getConfigForStyle × 1 (lines: 34)
        - prepareFirstScene × 1 (lines: 101)
        - punchyConfig × 1 (lines: 33)
        - recordShot × 1 (lines: 132)
        - signalIsAborted × 1 (lines: 199)
        - slowConfig × 1 (lines: 32)
        - startAutoTeaser × 1 (lines: 266)
        - startCinematicTeaser × 1 (lines: 240)
        - throwIfCancelled × 1 (lines: 205)
        - transitionToNextShot × 1 (lines: 144)
        - wait × 1 (lines: 18)
        - waitForViewerReady × 1 (lines: 45)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
