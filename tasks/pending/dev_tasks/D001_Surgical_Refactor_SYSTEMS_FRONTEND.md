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

- [ ] - **../../src/systems/Exporter.res** (Metric: [Nesting: 1.80, Density: 0.11, Coupling: 0.06] | Drag: 2.92 | LOC: 545/300  🎯 Target: Function: `normalizeLogoExtension` (High Local Complexity (5.0). Logic heavy.))

- [ ] - **../../src/systems/ProjectManager.res** (Metric: [Nesting: 2.40, Density: 0.09, Coupling: 0.08] | Drag: 3.48 | LOC: 400/300  🎯 Target: Function: `classifySaveError` (High Local Complexity (10.5). Logic heavy.))

- [ ] - **../../src/systems/TourTemplates.res** (Metric: [Nesting: 3.60, Density: 0.12, Coupling: 0.02] | Drag: 4.72 | LOC: 1199/300  🎯 Target: Function: `autoForwardHotspotIndex` (High Local Complexity (6.8). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D001/verification.json` (files at `_dev-system/tmp/D001/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D001/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Exporter.res`
- `src/systems/Exporter.res` (18 functions, fingerprint 9bc25854425bc359d2921bbb5923e43101e5412ec3c3a9dcc188fa485219276e)
    - Grouped summary:
        - apiErrorDecoder × 1 (lines: 11)
        - extractHttpErrorBody × 1 (lines: 164)
        - fetchLib × 1 (lines: 21)
        - fetchSceneUrlBlob × 1 (lines: 173)
        - filenameFromUrl × 1 (lines: 205)
        - finalMsg × 1 (lines: 575)
        - isLikelyImageBlob × 1 (lines: 225)
        - isLikelyImageUrl × 1 (lines: 216)
        - isUnauthorizedHttpError × 1 (lines: 160)
        - msg × 1 (lines: 562)
        - normalizeLogoExtension × 1 (lines: 196)
        - normalizeThrowableMessage × 1 (lines: 146)
        - normalizedStack × 1 (lines: 563)
        - payload × 1 (lines: 574)
        - progress × 1 (lines: 245)
        - throwableMessageRaw × 1 (lines: 125)
        - tourName × 1 (lines: 252)
        - uploadAndProcessRaw × 1 (lines: 40)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/ProjectManager.res`
- `src/systems/ProjectManager.res` (12 functions, fingerprint 9b4e84d0baee8f570fe024565bde5d4a0fe2ff4844ccf48261a72e528f2643d6)
    - Grouped summary:
        - classifySaveError × 1 (lines: 85)
        - createSavePackage × 1 (lines: 29)
        - loadProject × 1 (lines: 433)
        - loadProjectZip × 1 (lines: 43)
        - notifySaveFailure × 1 (lines: 113)
        - processLoadedProjectData × 1 (lines: 35)
        - recoverSaveProject × 1 (lines: 324)
        - saveProject × 1 (lines: 127)
        - saveRecoveryContextDecoder × 1 (lines: 56)
        - updateSaveContext × 1 (lines: 65)
        - validateProjectStructure × 1 (lines: 25)
        - validationReportWrapperDecoder × 1 (lines: 21)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/TourTemplates.res`
- `src/systems/TourTemplates.res` (4 functions, fingerprint 304350c5fd614be01d30b964ec8fd71537a12de284d7a372709b85f9db712f9c)
    - Grouped summary:
        - generateEmbedCodes × 1 (lines: 1273)
        - generateExportIndex × 2 (lines: 43, 1274)
        - indexTemplate × 1 (lines: 9)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
