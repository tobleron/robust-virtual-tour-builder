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

- [ ] - **../../src/systems/Exporter.res** (Metric: [Nesting: 2.40, Density: 0.04, Coupling: 0.08] | Drag: 3.45 | LOC: 423/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D001/verification.json` (files at `_dev-system/tmp/D001/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D001/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Exporter.res`
- `src/systems/Exporter.res` (20 functions, fingerprint 3ef31dbeeec0cc9bcd17dc7de5ca6cb6278812cdbcf66c3c845e30bc2d132bf0)
    - Grouped summary:
        - apiErrorDecoder × 1 (lines: 10)
        - backendOfflineExportMessage × 1 (lines: 17)
        - exportScenes × 1 (lines: 34)
        - extractHttpErrorBody × 1 (lines: 16)
        - fetchLib × 1 (lines: 11)
        - fetchSceneUrlBlob × 1 (lines: 18)
        - filenameFromUrl × 1 (lines: 20)
        - finalMsg × 1 (lines: 432)
        - isLikelyImageBlob × 1 (lines: 22)
        - isLikelyImageUrl × 1 (lines: 21)
        - isUnauthorizedHttpError × 1 (lines: 15)
        - msg × 1 (lines: 419)
        - normalizeLogoExtension × 1 (lines: 19)
        - normalizeThrowableMessage × 1 (lines: 14)
        - normalizedStack × 1 (lines: 420)
        - payload × 1 (lines: 431)
        - progress × 1 (lines: 36)
        - throwableMessageRaw × 1 (lines: 13)
        - tourName × 1 (lines: 43)
        - uploadAndProcessRaw × 1 (lines: 12)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
