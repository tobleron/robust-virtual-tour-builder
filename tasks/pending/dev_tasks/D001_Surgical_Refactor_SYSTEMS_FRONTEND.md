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
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/systems/Exporter.res** (Metric: [Nesting: 2.40, Density: 0.04, Coupling: 0.09] | Drag: 3.46 | LOC: 407/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D001/verification.json` (files at `_dev-system/tmp/D001/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D001/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Exporter.res`
- `src/systems/Exporter.res` (7 functions, fingerprint 0ab80b65d78cf5a8d7b51ae65ec60c8308921c080f789426efa58fe5ed1b611b)
    - Grouped summary:
        - exportScenes × 1 (lines: 14)
        - finalMsg × 1 (lines: 414)
        - msg × 1 (lines: 401)
        - normalizedStack × 1 (lines: 402)
        - payload × 1 (lines: 413)
        - progress × 1 (lines: 16)
        - tourName × 1 (lines: 23)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
