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

- [ ] - **../../src/systems/Exporter.res** (Metric: [Nesting: 2.40, Density: 0.10, Coupling: 0.05] | Drag: 3.52 | LOC: 624/300  🎯 Target: Function: `normalizeLogoExtension` (High Local Complexity (5.0). Logic heavy.)) → 🏗️ Split into 3 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D001/verification.json` (files at `_dev-system/tmp/D001/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D001/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Exporter.res`
- `src/systems/Exporter.res` (20 functions, fingerprint 410bdbee140202eed18d98260bed0a1641e09a5674ba36c01f014e4646c13eed)
    - Grouped summary:
        - apiErrorDecoder × 1 (lines: 11)
        - backendOfflineExportMessage × 1 (lines: 66)
        - exportScenes × 1 (lines: 261)
        - extractHttpErrorBody × 1 (lines: 57)
        - fetchLib × 1 (lines: 134)
        - fetchSceneUrlBlob × 1 (lines: 70)
        - filenameFromUrl × 1 (lines: 102)
        - finalMsg × 1 (lines: 657)
        - isLikelyImageBlob × 1 (lines: 122)
        - isLikelyImageUrl × 1 (lines: 113)
        - isUnauthorizedHttpError × 1 (lines: 53)
        - msg × 1 (lines: 644)
        - normalizeLogoExtension × 1 (lines: 93)
        - normalizeThrowableMessage × 1 (lines: 39)
        - normalizedStack × 1 (lines: 645)
        - payload × 1 (lines: 656)
        - progress × 1 (lines: 263)
        - throwableMessageRaw × 1 (lines: 18)
        - tourName × 1 (lines: 270)
        - uploadAndProcessRaw × 1 (lines: 152)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
