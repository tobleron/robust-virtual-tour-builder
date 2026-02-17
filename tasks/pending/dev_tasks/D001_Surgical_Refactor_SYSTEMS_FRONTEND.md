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

- [ ] - **../../src/systems/Exporter.res** (Metric: [Nesting: 1.80, Density: 0.12, Coupling: 0.06] | Drag: 2.93 | LOC: 514/300  🎯 Target: Function: `normalizeLogoExtension` (High Local Complexity (5.0). Logic heavy.))

- [ ] - **../../src/systems/TourTemplates.res** (Metric: [Nesting: 3.60, Density: 0.12, Coupling: 0.03] | Drag: 4.72 | LOC: 978/300  🎯 Target: Function: `extractScenePrefix` (High Local Complexity (3.0). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D001/verification.json` (files at `_dev-system/tmp/D001/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D001/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Exporter.res`
- `src/systems/Exporter.res` (18 functions, fingerprint 9bc25854425bc359d2921bbb5923e43101e5412ec3c3a9dcc188fa485219276e)
    - Grouped summary:
        - apiErrorDecoder × 1 (lines: 11)
        - extractHttpErrorBody × 1 (lines: 153)
        - fetchLib × 1 (lines: 21)
        - fetchSceneUrlBlob × 1 (lines: 162)
        - filenameFromUrl × 1 (lines: 194)
        - finalMsg × 1 (lines: 542)
        - isLikelyImageBlob × 1 (lines: 214)
        - isLikelyImageUrl × 1 (lines: 205)
        - isUnauthorizedHttpError × 1 (lines: 149)
        - msg × 1 (lines: 529)
        - normalizeLogoExtension × 1 (lines: 185)
        - normalizeThrowableMessage × 1 (lines: 135)
        - normalizedStack × 1 (lines: 530)
        - payload × 1 (lines: 541)
        - progress × 1 (lines: 233)
        - throwableMessageRaw × 1 (lines: 114)
        - tourName × 1 (lines: 240)
        - uploadAndProcessRaw × 1 (lines: 40)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TourTemplates.res`
- `src/systems/TourTemplates.res` (4 functions, fingerprint 304350c5fd614be01d30b964ec8fd71537a12de284d7a372709b85f9db712f9c)
    - Grouped summary:
        - generateEmbedCodes × 1 (lines: 1014)
        - generateExportIndex × 2 (lines: 43, 1015)
        - indexTemplate × 1 (lines: 9)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
