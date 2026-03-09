# Task D012: Surgical Refactor SRC CORE FRONTEND

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

- [ ] - **../../src/core/AppContext.res** (Metric: [Nesting: 3.60, Density: 0.22, Coupling: 0.10] | Drag: 4.91 | LOC: 360/300  ⚠️ Trigger: Drag above target (1.80) with file already at 360 LOC.  🎯 Target: Function: `dispatch` (High Local Complexity (8.2). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/core/HotspotHelpers.res** (Metric: [Nesting: 6.60, Density: 0.53, Coupling: 0.05] | Drag: 8.13 | LOC: 261/300  ⚠️ Trigger: Drag above target (1.80) with file already at 261 LOC.  🎯 Target: Function: `hotspotLinkId` (High Local Complexity (6.0). Logic heavy.)) → Refactor in-place

- [ ] - **../../src/core/JsonParsersDecoders.res** (Metric: [Nesting: 3.00, Density: 0.65, Coupling: 0.05] | Drag: 4.65 | LOC: 377/300  🎯 Target: Function: `project` (High Local Complexity (13.4). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)

- [ ] - **../../src/core/SceneOperations.res** (Metric: [Nesting: 7.20, Density: 0.21, Coupling: 0.06] | Drag: 8.43 | LOC: 370/300  ⚠️ Trigger: Drag above target (1.80) with file already at 370 LOC.  🎯 Target: Function: `nextMovingHotspot` (High Local Complexity (8.2). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D012/verification.json` (files at `_dev-system/tmp/D012/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D012/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/core/AppContext.res`
- `src/core/AppContext.res` (36 functions, fingerprint b8b04c391b30d35e182a8f349f062b7aae12dbf5ca68f383a5f892f45206d10c)
    - Grouped summary:
        - defaultDispatch × 1 (lines: 6)
        - defaultSceneSlice × 1 (lines: 53)
        - defaultSimSlice × 1 (lines: 75)
        - defaultUiSlice × 1 (lines: 65)
        - dispatchBridgeRef × 1 (lines: 9)
        - dispatchContext × 1 (lines: 97)
        - getBridgeDispatch × 1 (lines: 13)
        - getBridgeState × 1 (lines: 11)
        - globalContext × 1 (lines: 83)
        - isRafBatchableAction × 1 (lines: 99)
        - make × 8 (lines: 107, 110, 113, 116, 119, 122, 131, 136)
        - navigationContext × 1 (lines: 87)
        - pipelineContext × 1 (lines: 88)
        - restoreState × 1 (lines: 14)
        - sceneContext × 1 (lines: 84)
        - setBridgeState × 1 (lines: 12)
        - simContext × 1 (lines: 86)
        - stateBridgeRef × 1 (lines: 8)
        - uiContext × 1 (lines: 85)
        - useAppDispatch × 1 (lines: 386)
        - useAppSelector × 1 (lines: 403)
        - useAppState × 1 (lines: 385)
        - useNavigationFsm × 1 (lines: 398)
        - useNavigationSlice × 1 (lines: 392)
        - useNavigationState × 1 (lines: 396)
        - usePipelineSlice × 1 (lines: 393)
        - useSceneSlice × 1 (lines: 389)
        - useSimSlice × 1 (lines: 391)
        - useUiSlice × 1 (lines: 390)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/core/HotspotHelpers.res`
- `src/core/HotspotHelpers.res` (9 functions, fingerprint 3d5812f57307ded30b54b89e5273d47154349030aaca404d52003967c4bc32cb)
    - Grouped summary:
        - canEnableAutoForward × 1 (lines: 258)
        - handleAddHotspot × 1 (lines: 3)
        - handleClearHotspots × 1 (lines: 72)
        - handleCommitHotspotMove × 1 (lines: 223)
        - handleRemoveHotspot × 1 (lines: 26)
        - handleStartMovingHotspot × 1 (lines: 200)
        - handleStopMovingHotspot × 1 (lines: 219)
        - handleUpdateHotspotMetadata × 1 (lines: 139)
        - handleUpdateHotspotTargetView × 1 (lines: 103)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/core/JsonParsersDecoders.res`
- `src/core/JsonParsersDecoders.res` (36 functions, fingerprint 69e5550b02111d1ee90511d0d3ebae6e1252bfbe39f9effe0fb87e5cde88e9ab)
    - Grouped summary:
        - array × 1 (lines: 19)
        - arrivalView × 1 (lines: 256)
        - bool × 1 (lines: 23)
        - decode × 1 (lines: 316)
        - encode × 1 (lines: 331)
        - field × 1 (lines: 18)
        - file × 1 (lines: 44)
        - float × 1 (lines: 21)
        - hotspot × 1 (lines: 74)
        - id × 1 (lines: 26)
        - importScene × 1 (lines: 276)
        - int × 1 (lines: 20)
        - inventory × 1 (lines: 171)
        - inventoryEntry × 1 (lines: 167)
        - map × 1 (lines: 25)
        - motionAnimationSegment × 1 (lines: 343)
        - motionManifest × 1 (lines: 410)
        - motionShot × 1 (lines: 363)
        - motionTransitionOut × 1 (lines: 356)
        - normalizeLogo × 1 (lines: 59)
        - object × 1 (lines: 17)
        - opt × 1 (lines: 36)
        - option × 1 (lines: 24)
        - persistedSession × 1 (lines: 239)
        - project × 1 (lines: 180)
        - scene × 1 (lines: 99)
        - sceneEntry × 1 (lines: 160)
        - sceneStatus × 1 (lines: 136)
        - step × 1 (lines: 263)
        - steps × 1 (lines: 274)
        - string × 1 (lines: 22)
        - timelineItem × 1 (lines: 122)
        - transitionTarget × 1 (lines: 247)
        - updateHotspotMetadata × 1 (lines: 306)
        - updateMetadata × 1 (lines: 297)
        - viewFrame × 1 (lines: 66)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/core/SceneOperations.res`
- `src/core/SceneOperations.res` (7 functions, fingerprint 8ab4006b4841abe6486325ccf679d711f8e8ac777de09563367d29c3ecf2c4ac)
    - Grouped summary:
        - handleAddScenes × 1 (lines: 155)
        - handleApplyLazyRename × 1 (lines: 396)
        - handleDeleteScene × 1 (lines: 3)
        - handlePatchSceneThumbnail × 1 (lines: 411)
        - handleReorderScenes × 1 (lines: 119)
        - handleSetActiveScene × 1 (lines: 364)
        - handleUpdateSceneMetadata × 1 (lines: 276)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
