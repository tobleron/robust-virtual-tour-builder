# Task D015: Surgical Refactor SCENE FRONTEND

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

- [ ] - **../../src/systems/Scene/SceneLoader.res** (Metric: [Nesting: 4.20, Density: 0.10, Coupling: 0.07] | Drag: 5.32 | LOC: 408/300  🎯 Target: Function: `taskMismatch` (High Local Complexity (2.0). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D015/verification.json` (files at `_dev-system/tmp/D015/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D015/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Scene/SceneLoader.res`
- `src/systems/Scene/SceneLoader.res` (37 functions, fingerprint 689e265a59a8353b85dfc6f97a234bfab85418210d900af4ba62cc227ad145e3)
    - castToString — let castToString: 'a => string = %raw("(x) => typeof x === 'string' ? x : ''")
    - castToDict — let castToDict: 'a => dict<string> = %raw("(x) => (typeof x === 'object' && x !== null) ? x : {}")
    - loadStartTime — let loadStartTime = ref(0.0)
    - getHotspots — let getHotspots = (scene: scene, ~state, ~dispatch) =>
    - makeSceneConfig — let makeSceneConfig = (scene: scene, ~state, ~dispatch) => {
    - url — let url = SceneCache.getSourceUrl(scene.id, scene.file)
    - makeInitialConfig — let makeInitialConfig = (scene: scene, ~state, ~dispatch) => {
    - inner — let inner = makeSceneConfig(scene, ~state, ~dispatch)
    - blankPanorama — let blankPanorama = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=="
    - backgroundViewerConfig — let backgroundViewerConfig = () => {
    - ensureBackgroundViewer — let ensureBackgroundViewer = (~_state: state, ~_dispatch) => {
    - instance — let instance = ViewerSystem.Adapter.initialize(
    - toPathRequest — let toPathRequest = (state: state): pathRequest => {
    - findReusableInstance — let findReusableInstance = (pathRequest, targetIdx: int): option<ViewerSystem.Adapter.t> => {
    - targetSceneId — let targetSceneId = pathRequest.scenes[targetIdx]->Option.map(s => s.id)
    - metaId — let metaId = ViewerSystem.Adapter.getMetaData(inst, "sceneId")
    - isStaleTask — let isStaleTask = (
    - taskMismatch — let taskMismatch = switch taskId {
    - signalAborted — let signalAborted = switch signal {
    - onSceneLoad — let onSceneLoad = (
    - vId — let vId = castToDict(v)->Dict.get("container")->Option.getOr("")
    - entry — let entry = ViewerSystem.Pool.pool.contents->Belt.Array.getBy(e => e.containerId == vId)
    - onSceneError — let onSceneError = (
    - currentLoadTimeout — let currentLoadTimeout: ref<option<timeoutId>> = ref(None)
    - cleanupLoadTimeout — let cleanupLoadTimeout = () => {
    - loadNewScene — let loadNewScene = (
    - targetSceneOpt — let targetSceneOpt = state.scenes->Belt.Array.getBy(s => s.id == targetSceneId)
    - tIdx — let tIdx = state.scenes->Belt.Array.getIndexBy(s => s.id == targetSceneId)->Option.getOr(-1)
    - config — let config = Config.makeSceneConfig(targetScene, ~state, ~dispatch)
    - safetyTimeoutId — let safetyTimeoutId = setTimeout(() => {
    - activeVp — let activeVp = ViewerSystem.Pool.getActive()
    - inactiveVp — let inactiveVp = ViewerSystem.Pool.getInactive()
    - vp — let vp = switch activeVp {
    - safetyTimeoutId — let safetyTimeoutId = setTimeout(() => {
    - isAborted — let isAborted = switch signal {
    - initialConfig — let initialConfig = Config.makeInitialConfig(targetScene, ~state, ~dispatch)
    - newInstance — let newInstance = ViewerSystem.Adapter.initialize(
