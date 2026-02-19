# Task D011: Merge Folders FRONTEND

## Objective
## 🧩 Merge Objective
**Role:** Architecture Cleanup Bot
**Goal:** Reduce File Fragmentation (Read Tax).
**Constraint:** Combined file must not exceed 800 LOC.
**Optimal State:** Related small modules are unified into a single context window, reducing token consumption.

## Tasks

### 🔧 Action: Merge Fragmented Folders
**Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `Exporter.rs`). CRITICAL: Delete the now-empty `../../src/systems/Exporter/` folder to reduce directory nesting tax and strip any existing '@efficiency' tags.

- [ ] Folder: `../../src/systems/Exporter` (Metric: Read Tax high (Score 2.00). Projected Limit: 300 (Drag 3.17))
    - `../../src/systems/Exporter/ExporterUpload.res`
    - `../../src/systems/Exporter/ExporterUtils.res`

## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D011/verification.json` (files at `_dev-system/tmp/D011/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D011/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-merge snapshots for `../../src/systems/Exporter`
- `src/systems/Exporter/ExporterUtils.res` (12 functions, fingerprint fb5d2057024a8418e0b7898f79996b074ea83baacd8df99911d149c37fdb1596)
    - Grouped summary:
        - apiErrorDecoder × 1 (lines: 8)
        - backendOfflineExportMessage × 1 (lines: 63)
        - extractHttpErrorBody × 1 (lines: 54)
        - fetchLib × 1 (lines: 132)
        - fetchSceneUrlBlob × 1 (lines: 67)
        - filenameFromUrl × 1 (lines: 99)
        - isLikelyImageBlob × 1 (lines: 119)
        - isLikelyImageUrl × 1 (lines: 110)
        - isUnauthorizedHttpError × 1 (lines: 50)
        - normalizeLogoExtension × 1 (lines: 90)
        - normalizeThrowableMessage × 1 (lines: 36)
        - throwableMessageRaw × 1 (lines: 15)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
- `src/systems/Exporter/ExporterUpload.res` (1 functions, fingerprint 297d394e042a8ba627f45e39c303e8f1bd66047b288ce23cb9f12912d95607d4)
    - Grouped summary:
        - uploadAndProcessRaw × 1 (lines: 4)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
