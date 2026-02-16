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

- [ ] - **../../src/systems/Exporter.res** (Metric: [Nesting: 1.80, Density: 0.08, Coupling: 0.07] | Drag: 2.89 | LOC: 436/300  🎯 Target: Function: `normalizeThrowableMessage` (High Local Complexity (3.0). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D001/verification.json` (files at `_dev-system/tmp/D001/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D001/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Exporter.res`
- `src/systems/Exporter.res` (14 functions, fingerprint 43ccb5b4bf4d0a82a37f208c488e10ae0211d41754160e1990b02185b0e05a9e)
    - Grouped summary:
        - apiErrorDecoder × 1 (lines: 11)
        - extractHttpErrorBody × 1 (lines: 153)
        - fetchLib × 1 (lines: 21)
        - fetchSceneUrlBlob × 1 (lines: 162)
        - finalMsg × 1 (lines: 459)
        - isUnauthorizedHttpError × 1 (lines: 149)
        - msg × 1 (lines: 446)
        - normalizeThrowableMessage × 1 (lines: 135)
        - normalizedStack × 1 (lines: 447)
        - payload × 1 (lines: 458)
        - progress × 1 (lines: 192)
        - throwableMessageRaw × 1 (lines: 114)
        - tourName × 1 (lines: 199)
        - uploadAndProcessRaw × 1 (lines: 40)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
