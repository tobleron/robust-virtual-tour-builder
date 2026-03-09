# Task D021: Surgical Refactor SYSTEMS RESIZER FRONTEND

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

- [ ] - **../../src/systems/Resizer/ResizerLogic.res** (Metric: [Nesting: 2.40, Density: 0.06, Coupling: 0.11] | Drag: 3.46 | LOC: 310/300  ⚠️ Trigger: Drag above target (1.80) with file already at 310 LOC.) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D021/verification.json` (files at `_dev-system/tmp/D021/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D021/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Resizer/ResizerLogic.res`
- `src/systems/Resizer/ResizerLogic.res` (9 functions, fingerprint 9fe012439be0a56044c633b263b5c25442b0f08435ad719b64397bcd02c07048)
    - Grouped summary:
        - createResultFiles × 1 (lines: 117)
        - ensureGpsExtraction × 1 (lines: 36)
        - generateAndOverrideTiny × 1 (lines: 91)
        - generateResolutions × 1 (lines: 279)
        - hasGps × 1 (lines: 8)
        - mergeExifPreferBase × 1 (lines: 16)
        - pickNullable × 1 (lines: 10)
        - processAndAnalyzeImage × 1 (lines: 204)
        - processZipResponse × 1 (lines: 70)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
