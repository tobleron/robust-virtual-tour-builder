# Task D009: Merge Folders FRONTEND

## Objective
## 🧩 Merge Objective
**Role:** Architecture Cleanup Bot
**Goal:** Reduce File Fragmentation (Read Tax).
**Constraint:** Combined file must not exceed 800 LOC.
**Optimal State:** Related small modules are unified into a single context window, reducing token consumption.

## Tasks

### 🔧 Action: Merge Fragmented Folders
**Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `Loader.rs`). CRITICAL: Delete the now-empty `src/systems/Scene/Loader/` folder to reduce directory nesting tax and strip any existing '@efficiency' tags.

- [ ] Folder: `src/systems/Scene/Loader` (Metric: Recursive Feature Pod: 3 files in subtree sum to 156 LOC (fits in context). Max Drag: 6.80)
    - `src/systems/Scene/Loader/../../src/systems/Scene/Loader/SceneLoaderConfig.res`
    - `src/systems/Scene/Loader/../../src/systems/Scene/Loader/SceneLoaderEvents.res`
    - `src/systems/Scene/Loader/../../src/systems/Scene/Loader/SceneLoaderReuse.res`

### 🔧 Action: Merge Fragmented Folders
**Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `Project.rs`). CRITICAL: Delete the now-empty `../../src/systems/Project/` folder to reduce directory nesting tax and strip any existing '@efficiency' tags.

- [ ] Folder: `../../src/systems/Project` (Metric: Read Tax high (Score 3.00). Projected Limit: 300 (Drag 4.92))
    - `../../src/systems/Project/ProjectLoader.res`
    - `../../src/systems/Project/ProjectSaver.res`
    - `../../src/systems/Project/ProjectValidator.res`

## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D009/verification.json` (files at `_dev-system/tmp/D009/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D009/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-merge snapshots for `../../src/systems/Project`
- `src/systems/Project/ProjectValidator.res` (2 functions, fingerprint c1da22b92cfb43a237f871bf8fcf11b5c39ff3c7931fb85fa73bbe455169f84d)
    - validationReportWrapperDecoder — validationReportWrapperDecoder = JsonCombinators.Json.Decode.object(field => {
    - validateProjectStructure — validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
- `src/systems/Project/ProjectLoader.res` (14 functions, fingerprint c19f172c88f9105107deeeceaad5008a1b9efdf270fc00f7b0d0659afb92402b)
    - processLoadedProjectData — processLoadedProjectData = (
    - progress — progress = (curr, total, msg) => {
    - token — token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")
    - finalToken — finalToken = switch token {
    - tokenQuery — tokenQuery = "?token=" ++ finalToken
    - allInventoryScenes — allInventoryScenes =
    - validScenes — validScenes = ProjectManagerUrl.rebuildSceneUrls(
    - updatedInventory — updatedInventory = validScenes->Belt.Array.reduce(pd.inventory, (acc, s) => {
    - finalOrder — finalOrder = if Array.length(pd.sceneOrder) > 0 {
    - resolvedActiveScenes — resolvedActiveScenes = finalOrder->Belt.Array.keepMap(id => {
    - loadedProject — loadedProject: Types.project = {
    - loadProjectZip — loadProjectZip = (zipFile: File.t, ~onProgress: option<onProgress>=?) => {
    - progress — progress = (curr, total, msg) => {
    - loadStartTime — loadStartTime = Date.now()
- `src/systems/Project/ProjectSaver.res` (5 functions, fingerprint 2e2e031360c1b2b4cda97833635631c1e5f7fb29df5cb770c75eb0d98b06cb1b)
    - createSavePackage — createSavePackage = (state: state, ~signal=?, ~onProgress: option<onProgress>=?): Promise.t<
    - progress — progress = (curr, total, msg) => {
    - project — project: Types.project = {
    - jsonStr — jsonStr = JsonCombinators.Json.stringify(JsonParsers.Encoders.project(project))
    - formData — formData = FormData.newFormData()
### Pre-merge snapshots for recursive cluster `src/systems/Scene/Loader`
- `src/systems/Scene/Loader/SceneLoaderEvents.res` (8 functions, fingerprint 4e8ceea824741cd661707f741fc1a482d4e2cb0595ac9fae388e6936f365aa26)
    - isStaleTask — isStaleTask = (~taskId: option<string>=?, ~signal: option<BrowserBindings.AbortSignal.t>=?) => {
    - taskMismatch — taskMismatch = switch taskId {
    - signalAborted — signalAborted = switch signal {
    - castToDict — castToDict: 'a => dict<string> = %raw("(x) => (typeof x === 'object' && x !== null) ? x : {}")
    - onSceneLoad — onSceneLoad = (
    - vId — vId = castToDict(v)->Dict.get("container")->Option.getOr("")
    - entry — entry = ViewerSystem.Pool.pool.contents->Belt.Array.getBy(e => e.containerId == vId)
    - onSceneError — onSceneError = (
- `src/systems/Scene/Loader/SceneLoaderConfig.res` (7 functions, fingerprint f4fd398f9137c60604b95ef249805b3adedf31eb810a43146a408204173e13c5)
    - getHotspots — getHotspots = (scene: scene, ~state, ~dispatch) =>
    - makeSceneConfig — makeSceneConfig = (scene: scene, ~state, ~dispatch) => {
    - url — url = SceneCache.getSourceUrl(scene.id, scene.file)
    - makeInitialConfig — makeInitialConfig = (scene: scene, ~state, ~dispatch) => {
    - inner — inner = makeSceneConfig(scene, ~state, ~dispatch)
    - blankPanorama — blankPanorama = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=="
    - backgroundViewerConfig — backgroundViewerConfig = () => {
- `src/systems/Scene/Loader/SceneLoaderReuse.res` (3 functions, fingerprint afe56389cbe21f3f18e6d254e8e228cbf835daaab5fa18214bb9579bb725550e)
    - findReusableInstance — findReusableInstance = (pathRequest: pathRequest, targetIdx: int): option<
    - targetSceneId — targetSceneId = pathRequest.scenes[targetIdx]->Option.map(s => s.id)
    - metaId — metaId = ViewerSystem.Adapter.getMetaData(inst, "sceneId")
