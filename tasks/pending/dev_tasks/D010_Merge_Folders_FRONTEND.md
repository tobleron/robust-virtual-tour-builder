# Task D010: Merge Folders FRONTEND

## Objective
## 🧩 Merge Objective
**Role:** Architecture Cleanup Bot
**Goal:** Reduce File Fragmentation (Read Tax).
**Constraint:** Combined file must not exceed 800 LOC.
**Optimal State:** Related small modules are unified into a single context window, reducing token consumption.

## Tasks

### 🔧 Action: Merge Fragmented Folders
**Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `ExifReport.res`). Preserve the existing folder unless it is truly empty and no other generated task still touches that subtree.

- [ ] Folder: `src/systems/ExifReport` (Metric: Read Tax high (Score 4.00). Projected Limit: 400 (Drag 3.92))
    - `src/systems/ExifReport/ExifReportGeneratorLogicExtraction.res`
    - `src/systems/ExifReport/ExifReportGeneratorLogicGroups.res`
    - `src/systems/ExifReport/ExifReportGeneratorLogicLocation.res`
    - `src/systems/ExifReport/ExifReportGeneratorLogicTypes.res`
    - Conflict Guard: preserve `src/systems/ExifReport` because the folder still contains non-merged paths: `src/systems/ExifReport/ExifReportGeneratorLogicExtraction.bs.js, src/systems/ExifReport/ExifReportGeneratorLogicGroups.bs.js, src/systems/ExifReport/ExifReportGeneratorLogicLocation.bs.js, src/systems/ExifReport/ExifReportGeneratorLogicTypes.bs.js`.

### 🔧 Action: Merge Fragmented Folders
**Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `Viewer.res`). Preserve the existing folder unless it is truly empty and no other generated task still touches that subtree.

- [ ] Folder: `src/systems/Viewer` (Metric: Read Tax high (Score 3.00). Projected Limit: 400 (Drag 5.06))
    - `src/systems/Viewer/ViewerAdapter.res`
    - `src/systems/Viewer/ViewerFollow.res`
    - `src/systems/Viewer/ViewerPool.res`
    - Conflict Guard: preserve `src/systems/Viewer` because the folder still contains non-merged paths: `src/systems/Viewer/ViewerAdapter.bs.js, src/systems/Viewer/ViewerFollow.bs.js, src/systems/Viewer/ViewerPool.bs.js`.

## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D010_Merge_Folders_FRONTEND/verification.json` (files at `_dev-system/tmp/D010_Merge_Folders_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D010_Merge_Folders_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-merge snapshots for `../../src/systems/Viewer`
- `src/systems/Viewer/ViewerPool.res` (13 functions, fingerprint 24dcb180435ff050c476908592dcc686240602b152601a3fb9bdc3195bce16e6)
    - Grouped summary:
        - clearCleanupTimeout × 1 (lines: 71)
        - clearInstance × 1 (lines: 52)
        - getActive × 1 (lines: 29)
        - getActiveViewer × 1 (lines: 30)
        - getInactive × 1 (lines: 31)
        - getInactiveViewer × 1 (lines: 32)
        - getViewport × 1 (lines: 27)
        - getViewportByContainer × 1 (lines: 28)
        - pool × 1 (lines: 11)
        - registerInstance × 1 (lines: 43)
        - reset × 1 (lines: 82)
        - setCleanupTimeout × 1 (lines: 61)
        - swapActive × 1 (lines: 33)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
- `src/systems/Viewer/ViewerFollow.res` (5 functions, fingerprint c632b0b784d08e282a1d50b48a94d85959218434069b5d5b3f9c09c625a650a0)
    - Grouped summary:
        - isInsideDeadZone × 1 (lines: 8)
        - linkingDeadZone × 1 (lines: 4)
        - linkingPitchSensitivity × 1 (lines: 6)
        - linkingYawSensitivity × 1 (lines: 5)
        - updateFollowLoop × 1 (lines: 25)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
- `src/systems/Viewer/ViewerAdapter.res` (20 functions, fingerprint edec2a95380cfa4c76fb69d6b61e86002dda40c6f82ed4e2612d592411a6bf22)
    - Grouped summary:
        - addHotSpot × 1 (lines: 128)
        - addScene × 1 (lines: 137)
        - destroy × 1 (lines: 85)
        - getHfov × 1 (lines: 119)
        - getMetaData × 1 (lines: 148)
        - getPitch × 1 (lines: 117)
        - getScene × 1 (lines: 130)
        - getYaw × 1 (lines: 118)
        - initialize × 1 (lines: 18)
        - initializeViewer × 1 (lines: 83)
        - isLoaded × 1 (lines: 139)
        - loadScene × 1 (lines: 131)
        - name × 1 (lines: 16)
        - on × 1 (lines: 138)
        - removeHotSpot × 1 (lines: 129)
        - setHfov × 1 (lines: 122)
        - setMetaData × 1 (lines: 140)
        - setPitch × 1 (lines: 120)
        - setView × 1 (lines: 123)
        - setYaw × 1 (lines: 121)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-merge snapshots for `../../src/systems/ExifReport`
- `src/systems/ExifReport/ExifReportGeneratorLogicGroups.res` (2 functions, fingerprint 0c614deb623ccce92005ad856266bbf052b326605fc422677563f1f9e3f6a570)
    - Grouped summary:
        - analyzeGroups × 1 (lines: 6)
        - listIndividualFiles × 1 (lines: 64)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
- `src/systems/ExifReport/ExifReportGeneratorLogicTypes.res` (0 functions, fingerprint e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
- `src/systems/ExifReport/ExifReportGeneratorLogicLocation.res` (1 functions, fingerprint 757a25ee836c8cdd83d5417e22d81462edec73a61ae9f61898f08a7b24c0f05b)
    - Grouped summary:
        - analyzeLocation × 1 (lines: 3)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
- `src/systems/ExifReport/ExifReportGeneratorLogicExtraction.res` (7 functions, fingerprint ef7d28e1dde0b406c2fa5375f5b5cc9e6e658c3b186f4f8833d7ebb503cc0dac)
    - Grouped summary:
        - decodeExifMetadata × 1 (lines: 22)
        - decodeQualityAnalysis × 1 (lines: 50)
        - extractAllExif × 1 (lines: 137)
        - isLikelyValidExif × 1 (lines: 11)
        - isLikelyValidQuality × 1 (lines: 19)
        - processSceneDataItem × 1 (lines: 109)
        - resolveExifData × 1 (lines: 78)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
