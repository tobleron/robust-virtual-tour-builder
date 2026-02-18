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

- [ ] - **../../src/systems/Exporter.res** (Metric: [Nesting: 2.40, Density: 0.11, Coupling: 0.06] | Drag: 3.52 | LOC: 592/300  🎯 Target: Function: `normalizeLogoExtension` (High Local Complexity (5.0). Logic heavy.))

- [ ] - **../../src/systems/ProjectManager.res** (Metric: [Nesting: 2.40, Density: 0.09, Coupling: 0.08] | Drag: 3.48 | LOC: 400/300  🎯 Target: Function: `classifySaveError` (High Local Complexity (10.5). Logic heavy.))

- [ ] - **../../src/systems/TourTemplates.res** (Metric: [Nesting: 3.60, Density: 0.12, Coupling: 0.02] | Drag: 4.72 | LOC: 1226/300  🎯 Target: Function: `autoForwardHotspotIndex` (High Local Complexity (6.8). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D001/verification.json` (files at `_dev-system/tmp/D001/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D001/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Exporter.res`
- `src/systems/Exporter.res` (20 functions, fingerprint 435470270f210dc9b98f087aa5b810eaa7f0c4e45c7a375978e88a1080eedcc9)
    - Grouped summary:
        - apiErrorDecoder × 1 (lines: 11)
        - backendOfflineExportMessage × 1 (lines: 164)
        - exportScenes × 1 (lines: 241)
        - extractHttpErrorBody × 1 (lines: 155)
        - fetchLib × 1 (lines: 21)
        - fetchSceneUrlBlob × 1 (lines: 169)
        - filenameFromUrl × 1 (lines: 201)
        - finalMsg × 1 (lines: 625)
        - isLikelyImageBlob × 1 (lines: 221)
        - isLikelyImageUrl × 1 (lines: 212)
        - isUnauthorizedHttpError × 1 (lines: 151)
        - msg × 1 (lines: 612)
        - normalizeLogoExtension × 1 (lines: 192)
        - normalizeThrowableMessage × 1 (lines: 137)
        - normalizedStack × 1 (lines: 613)
        - payload × 1 (lines: 624)
        - progress × 1 (lines: 243)
        - throwableMessageRaw × 1 (lines: 116)
        - tourName × 1 (lines: 250)
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
        - generateEmbedCodes × 1 (lines: 1304)
        - generateExportIndex × 2 (lines: 43, 1305)
        - indexTemplate × 1 (lines: 9)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
