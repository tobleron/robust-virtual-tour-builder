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

- [ ] - **../../src/systems/Api/ProjectApi.res** (Metric: [Nesting: 1.20, Density: 0.00, Coupling: 0.06] | Drag: 2.20 | LOC: 414/300) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D005/verification.json` (files at `_dev-system/tmp/D005/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D005/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Api/ProjectApi.res`
- `src/systems/Api/ProjectApi.res` (15 functions, fingerprint 22174c2415c722f3a8c4d26c8132e5838b1dfa88ec0a808b87dfd635844da180)
    - Grouped summary:
        - calculatePath × 1 (lines: 378)
        - decodeImportChunkResponse × 1 (lines: 64)
        - decodeImportInitResponse × 1 (lines: 51)
        - decodeImportStatusResponse × 1 (lines: 76)
        - handleError × 1 (lines: 6)
        - handleJsonDecode × 1 (lines: 17)
        - importProject × 1 (lines: 311)
        - requestImportAbort × 1 (lines: 247)
        - requestImportChunk × 1 (lines: 156)
        - requestImportComplete × 1 (lines: 208)
        - requestImportInit × 1 (lines: 92)
        - requestImportStatus × 1 (lines: 131)
        - reverseGeocode × 1 (lines: 413)
        - saveProject × 1 (lines: 356)
        - uploadMissingChunks × 1 (lines: 266)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
