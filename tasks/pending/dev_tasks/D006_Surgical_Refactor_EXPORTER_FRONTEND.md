# Task D006: Surgical Refactor EXPORTER FRONTEND

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

- [ ] - **../../src/systems/Exporter/ExporterPackaging.res** (Metric: [Nesting: 3.60, Density: 0.06, Coupling: 0.06] | Drag: 4.67 | LOC: 500/300  🎯 Target: Function: `isAborted` (High Local Complexity (2.0). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/systems/Exporter/ExporterUpload.res** (Metric: [Nesting: 4.20, Density: 0.17, Coupling: 0.05] | Drag: 5.39 | LOC: 499/300  🎯 Target: Function: `uploadedCount` (High Local Complexity (8.5). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D006/verification.json` (files at `_dev-system/tmp/D006/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D006/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Exporter/ExporterPackaging.res`
- `src/systems/Exporter/ExporterPackaging.res` (2 functions, fingerprint 7cbb1e18bbdfe0a8746bcf2173a0711833d63d80b6e4887abcc46300a73a3076)
    - Grouped summary:
        - normalizeMarketingValue × 1 (lines: 13)
        - scenePct × 1 (lines: 502)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/Exporter/ExporterUpload.res`
- `src/systems/Exporter/ExporterUpload.res` (17 functions, fingerprint a0dd909684b143aa3cb34e7f72795c0385e06a284528202c58cd2617cb79a31a)
    - Grouped summary:
        - blobSlice × 1 (lines: 201)
        - decodeExportChunkResponse × 1 (lines: 173)
        - decodeExportCompleteResponse × 1 (lines: 192)
        - decodeExportInitResponse × 1 (lines: 163)
        - decodeExportStatusResponse × 1 (lines: 182)
        - defaultExportChunkSizeBytes × 1 (lines: 161)
        - formDataToBlob × 1 (lines: 490)
        - isAborted × 1 (lines: 212)
        - requestExportAbort × 1 (lines: 384)
        - requestExportChunk × 1 (lines: 281)
        - requestExportComplete × 1 (lines: 344)
        - requestExportInit × 1 (lines: 215)
        - requestExportStatus × 1 (lines: 253)
        - sha256HexForBlob × 1 (lines: 203)
        - uploadAndProcessRaw × 1 (lines: 4)
        - uploadChunkedThenLegacy × 1 (lines: 497)
        - uploadChunkedWithResume × 1 (lines: 405)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
