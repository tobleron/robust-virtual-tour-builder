# Task D014: Surgical Refactor SYSTEMS API FRONTEND

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

- [ ] - **../../src/systems/Api/AuthenticatedClientRequest.res** (Metric: [Nesting: 2.40, Density: 0.15, Coupling: 0.10] | Drag: 3.55 | LOC: 253/300  ⚠️ Trigger: Drag above target (1.80) with file already at 253 LOC.  🎯 Target: Function: `classifyRateLimitScope` (High Local Complexity (8.0). Logic heavy.)) → Refactor in-place

- [ ] - **../../src/systems/Api/MediaApi.res** (Metric: [Nesting: 3.60, Density: 0.31, Coupling: 0.10] | Drag: 5.03 | LOC: 270/300  ⚠️ Trigger: Drag above target (1.80) with file already at 270 LOC.  🎯 Target: Function: `reserveProcessFullSlot` (High Local Complexity (4.0). Logic heavy.)) → Refactor in-place

- [ ] - **../../src/systems/Api/ProjectApi.res** (Metric: [Nesting: 3.00, Density: 0.32, Coupling: 0.05] | Drag: 4.32 | LOC: 440/300  🎯 Target: Function: `listDashboardProjects` (High Local Complexity (3.4). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D014/verification.json` (files at `_dev-system/tmp/D014/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D014/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Api/AuthenticatedClientRequest.res`
- `src/systems/Api/AuthenticatedClientRequest.res` (2 functions, fingerprint 33e5715c5d882bd8570840fd5a98d238308d90b9bd8a1f27f0ae0a82f0481433)
    - Grouped summary:
        - classifyRateLimitScope × 1 (lines: 6)
        - request × 1 (lines: 26)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/Api/MediaApi.res`
- `src/systems/Api/MediaApi.res` (15 functions, fingerprint db716bf5a2b06ccc6c58331e1ef50612b3536db4d940c8613ed737b91db71852)
    - Grouped summary:
        - applyProcessFullBackoff × 1 (lines: 115)
        - batchCalculateSimilarity × 1 (lines: 237)
        - clamp × 1 (lines: 19)
        - extractMetadata × 1 (lines: 128)
        - noteProcessFullSuccess × 1 (lines: 61)
        - parseRateLimitedSeconds × 1 (lines: 102)
        - processFullDynamicSpacingMs × 1 (lines: 10)
        - processFullLatencyEmaMs × 1 (lines: 11)
        - processFullNextAllowedAtMs × 1 (lines: 9)
        - processFullStableSuccessStreak × 1 (lines: 12)
        - processImageFull × 1 (lines: 171)
        - reserveProcessFullSlot × 1 (lines: 86)
        - sleepMs × 1 (lines: 14)
        - updateLatencyEma × 1 (lines: 51)
        - updateSpacing × 1 (lines: 28)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/Api/ProjectApi.res`
- `src/systems/Api/ProjectApi.res` (22 functions, fingerprint e5e9747d5b9059ed13aed8a0d2eeca451c0945b6ae143ab646340f45b9327d74)
    - Grouped summary:
        - calculatePath × 1 (lines: 130)
        - cleanupBackendCache × 1 (lines: 332)
        - dashboardLoadDecoder × 1 (lines: 30)
        - dashboardProjectDecoder × 1 (lines: 17)
        - decodeDashboardLoadResponse × 1 (lines: 98)
        - decodeDashboardProjects × 1 (lines: 95)
        - decodeSnapshotAssetSyncResponse × 1 (lines: 104)
        - decodeSnapshotHistory × 1 (lines: 101)
        - decodeSnapshotRestoreResponse × 1 (lines: 103)
        - decodeSnapshotSyncResponse × 1 (lines: 100)
        - listDashboardProjects × 1 (lines: 217)
        - listProjectSnapshots × 1 (lines: 352)
        - loadDashboardProject × 1 (lines: 246)
        - restoreProjectSnapshot × 1 (lines: 384)
        - reverseGeocode × 1 (lines: 175)
        - saveProject × 1 (lines: 107)
        - snapshotAssetSyncDecoder × 1 (lines: 90)
        - snapshotHistoryItemDecoder × 1 (lines: 74)
        - snapshotRestoreDecoder × 1 (lines: 84)
        - snapshotSyncDecoder × 1 (lines: 67)
        - syncSnapshot × 1 (lines: 280)
        - syncSnapshotAssets × 1 (lines: 421)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
