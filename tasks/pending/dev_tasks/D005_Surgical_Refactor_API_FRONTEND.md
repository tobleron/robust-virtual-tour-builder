# Task D005: Surgical Refactor API FRONTEND

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

- [ ] - **../../src/systems/Api/AuthenticatedClient.res** (Metric: [Nesting: 2.40, Density: 0.18, Coupling: 0.09] | Drag: 3.64 | LOC: 388/300  🎯 Target: Function: `getTimeoutMs` (High Local Complexity (4.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/Api/ProjectApi.res** (Metric: [Nesting: 1.20, Density: 0.00, Coupling: 0.05] | Drag: 2.20 | LOC: 437/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D005/verification.json` (files at `_dev-system/tmp/D005/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D005/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Api/AuthenticatedClient.res`
- `src/systems/Api/AuthenticatedClient.res` (10 functions, fingerprint 54025c386ca048345d2c27981094b399c701320923e2f1dcef1f5c2d74f1ca8a)
    - Grouped summary:
        - circuitBreaker × 1 (lines: 25)
        - fetchBlob × 1 (lines: 20)
        - fetchJson × 1 (lines: 18)
        - fetchText × 1 (lines: 19)
        - getTimeoutMs × 1 (lines: 28)
        - prepareRequestBody × 1 (lines: 104)
        - prepareRequestSignal × 1 (lines: 47)
        - request × 1 (lines: 115)
        - requestWithRetry × 1 (lines: 309)
        - toUpper × 1 (lines: 23)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/Api/ProjectApi.res`
- `src/systems/Api/ProjectApi.res` (15 functions, fingerprint bf9ee190c9f06bd7598c0e35183abf12c5708c4bd73ffea9e1cc223890e0b615)
    - Grouped summary:
        - calculatePath × 1 (lines: 401)
        - decodeImportChunkResponse × 1 (lines: 64)
        - decodeImportInitResponse × 1 (lines: 51)
        - decodeImportStatusResponse × 1 (lines: 76)
        - handleError × 1 (lines: 6)
        - handleJsonDecode × 1 (lines: 17)
        - importProject × 1 (lines: 328)
        - requestImportAbort × 1 (lines: 267)
        - requestImportChunk × 1 (lines: 164)
        - requestImportComplete × 1 (lines: 224)
        - requestImportInit × 1 (lines: 92)
        - requestImportStatus × 1 (lines: 131)
        - reverseGeocode × 1 (lines: 436)
        - saveProject × 1 (lines: 379)
        - uploadMissingChunks × 1 (lines: 283)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
