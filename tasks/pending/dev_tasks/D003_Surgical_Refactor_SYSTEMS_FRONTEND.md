# Task D003: Surgical Refactor SYSTEMS FRONTEND

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

- [ ] - **../../src/systems/ProjectManager.res** (Metric: [Nesting: 4.20, Density: 0.20, Coupling: 0.10] | Drag: 5.40 | LOC: 403/300  🎯 Target: Function: `finalToken` (High Local Complexity (2.0). Logic heavy.))

- [ ] - **../../src/systems/UploadProcessorLogic.res** (Metric: [Nesting: 2.40, Density: 0.04, Coupling: 0.11] | Drag: 3.44 | LOC: 399/300  🎯 Target: Function: `getNotificationType` (High Local Complexity (4.0). Logic heavy.))

- [ ] - **../../src/systems/ViewerSystem.res** (Metric: [Nesting: 4.20, Density: 0.51, Coupling: 0.08] | Drag: 5.75 | LOC: 379/300  🎯 Target: Function: `elOpt` (High Local Complexity (6.9). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D003/verification.json` (files at `_dev-system/tmp/D003/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D003/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/ProjectManager.res`
- `src/systems/ProjectManager.res` (39 functions, fingerprint f72840fd2299661eca8e73fafe88dbd59b97158a00797ae3f9f581bea7fe6ee2)
    - validationReportWrapperDecoder — let validationReportWrapperDecoder = JsonCombinators.Json.Decode.object(field => {
    - validateProjectStructure — let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
    - createSavePackage — let createSavePackage = (state: state, ~signal=?, ~onProgress: option<onProgress>=?): Promise.t<
    - progress — let progress = (curr, total, msg) => {
    - project — let project: Types.project = {
    - jsonStr — let jsonStr = JsonCombinators.Json.stringify(JsonParsers.Encoders.project(project))
    - formData — let formData = FormData.newFormData()
    - processLoadedProjectData — let processLoadedProjectData = (
    - progress — let progress = (curr, total, msg) => {
    - token — let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")
    - finalToken — let finalToken = switch token {
    - tokenQuery — let tokenQuery = "?token=" ++ finalToken
    - allInventoryScenes — let allInventoryScenes =
    - validScenes — let validScenes = ProjectManagerUrl.rebuildSceneUrls(
    - updatedInventory — let updatedInventory = validScenes->Belt.Array.reduce(pd.inventory, (acc, s) => {
    - finalOrder — let finalOrder = if Array.length(pd.sceneOrder) > 0 {
    - resolvedActiveScenes — let resolvedActiveScenes = finalOrder->Belt.Array.keepMap(id => {
    - loadedProject — let loadedProject: Types.project = {
    - loadProjectZip — let loadProjectZip = (zipFile: File.t, ~onProgress: option<onProgress>=?) => {
    - progress — let progress = (curr, total, msg) => {
    - loadStartTime — let loadStartTime = Date.now()
    - saveProject — let saveProject = (state: state, ~signal=?, ~onProgress: option<onProgress>=?) => {
    - tourName — let tourName = if state.tourName == "" {
    - safeName — let safeName = String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")->String.toLowerCase
    - dateParts — let dateParts = String.split(Date.toISOString(Date.make()), "T")
    - dateStr — let dateStr = Belt.Array.get(dateParts, 0)->Option.getOr("unknown_date")
    - filename — let filename =
    - useFileHandle — let useFileHandle = %raw(`typeof window.showSaveFilePicker !== 'undefined'`)
    - handlePromise — let handlePromise = if useFileHandle {
    - saveStartTime — let saveStartTime = Date.now()
    - progress — let progress = (curr, total, msg) => {
    - recoverSaveProject — let recoverSaveProject = (
    - waitForStateUpdate — let waitForStateUpdate = () => {
    - unsubscribeRef — let unsubscribeRef = ref(() => ())
    - timerId — let timerId: ref<int> = ref(0)
    - callback — let callback = (newState: state) => {
    - state — let state = getState()
    - restorePromise — let restorePromise = if Array.length(state.scenes) > 0 {
    - loadProject — let loadProject = (zipFile: File.t, ~onProgress: option<onProgress>=?): Promise.t<
### Pre-split snapshot for `src/systems/UploadProcessorLogic.res`
- `src/systems/UploadProcessorLogic.res` (53 functions, fingerprint a70b893efe954ef90729a98fa3001cbc1f06a7dc1256b9c16cc368833bbd637d)
    - getNotificationType — let getNotificationType = (typeStr: string) => {
    - notify — let notify = (msg, typeStr) => {
    - importance — let importance = switch typeStr {
    - handleProcessSuccess — let handleProcessSuccess = (res: Resizer.processResult, item: uploadItem) => {
    - handleProcessError — let handleProcessError = (msg, item: uploadItem) => {
    - processItem — let processItem = (i, item: uploadItem, onStatus: string => unit) => {
    - newItem — let newItem = switch processResult {
    - createScenePayload — let createScenePayload = (items: array<UploadTypes.uploadItem>) => {
    - preview — let preview = Option.getOr(item.preview, item.original)
    - tiny — let tiny = Option.getOr(item.tiny, preview)
    - sanitizedName — let sanitizedName = File.name(preview)
    - handleExifReport — let handleExifReport = (
    - reportData — let reportData = Belt.Array.map(processedWithClusters, i => {
    - item — let item: ExifReportGenerator.sceneDataItem = {
    - successNames — let successNames = Belt.Array.map(processedWithClusters, i => {
    - preview — let preview = Option.getOr(i.preview, i.original)
    - skippedNames — let skippedNames = Belt.Array.makeBy(skippedCount, i => "Duplicate " ++ Belt.Int.toString(i + 1))
    - report — let report: Types.uploadReport = {success: successNames, skipped: skippedNames}
    - currentName — let currentName = getState().tourName
    - finalizeUploads — let finalizeUploads = (
    - existingScenes — let existingScenes = getState().scenes
    - wasEmpty — let wasEmpty = getState().activeIndex == -1
    - currentScenes — let currentScenes = getState().scenes
    - durationStr — let durationStr = ((Date.now() -. startTime) /. 1000.0)->Float.toFixed(~digits=1)
    - qualityResults — let qualityResults = Belt.Array.map(
    - q — let q =
    - score — let score = %raw("(q => q && typeof q.score === 'number' ? q.score : -1)")(q)
    - preview — let preview = Option.getOr(i.preview, i.original)
    - sanitizedName — let sanitizedName = UrlUtils.stripExtension(File.name(preview))
    - recoverUpload — let recoverUpload = (entry: OperationJournal.journalEntry) => {
    - count — let count = switch JsonCombinators.Json.decode(
    - executeProcessingChain — let executeProcessingChain = (
    - processedCount — let processedCount = ref(0)
    - allProcessedItems — let allProcessedItems = ref([])
    - lastJournalUpdate — let lastJournalUpdate = ref(Date.now())
    - now — let now = Date.now()
    - shouldUpdateJournal — let shouldUpdateJournal = now -. lastJournalUpdate.contents > 1000.0
    - journalPromise — let journalPromise = if shouldUpdateJournal {
    - scaledPct — let scaledPct = 20.0 +. 75.0 *. pct
    - validProcessed — let validProcessed = Belt.Array.keep(allProcessedItems.contents, i => i.error == None)
    - scored — let scored: array<filenameItem> = Belt.Array.mapWithIndex(validProcessed, (idx, item) => {
    - nameCmp — let nameCmp = Float.toInt(String.localeCompare(a.name, b.name))
    - sortedItems — let sortedItems = Belt.Array.map(scored, scored => scored.item)
    - existingScenesCount — let existingScenesCount = Belt.Array.length(getState().scenes)
    - finalItems — let finalItems = Belt.Array.mapWithIndex(sortedItems, (i, item) => {
    - newIndex — let newIndex = existingScenesCount + i
    - newName — let newName = TourLogic.computeSceneFilename(newIndex, "", "")
    - existingScenes — let existingScenes = getState().scenes
    - jsonPayload — let jsonPayload = createScenePayload(clustered)
    - handleFingerprinting — let handleFingerprinting = (
    - currentState — let currentState = getState()
    - uniqueItems — let uniqueItems = FingerprintService.filterDuplicates(
    - skippedFromFingerprint — let skippedFromFingerprint = Belt.Array.length(results) - Belt.Array.length(uniqueItems)
### Pre-split snapshot for `src/systems/ViewerSystem.res`
- `src/systems/ViewerSystem.res` (86 functions, fingerprint 77eef4d0afc38fe63c86ae9b740035bb6edff1c25f74ebbd990af67856dbe5e8)
    - name — let name = "Pannellum"
    - initialize — let initialize = (id, config) => {
    - v — let v = Pannellum.viewer(id, config)
    - lastDown — let lastDown = ref(None)
    - elOpt — let elOpt = Dom.getElementById(id)
    - clientX — let clientX = e->Dom.clientX->Int.toFloat
    - clientY — let clientY = e->Dom.clientY->Int.toFloat
    - clientX — let clientX = e->Dom.clientX->Int.toFloat
    - clientY — let clientY = e->Dom.clientY->Int.toFloat
    - diffX — let diffX = Math.abs(clientX -. x)
    - diffY — let diffY = Math.abs(clientY -. y)
    - diffT — let diffT = Date.now() -. t
    - asEvent — let asEvent: Dom.event => Viewer.mouseEvent = %raw(`function(e) { return { clientX: e.clientX, clientY: e.clientY }; }`)
    - coords — let coords = Viewer.mouseEventToCoords(v, asEvent(e))
    - p — let p = Belt.Array.get(coords, 0)->Option.getOr(0.0)
    - y — let y = Belt.Array.get(coords, 1)->Option.getOr(0.0)
    - cp — let cp = Viewer.getPitch(v)
    - cy — let cy = Viewer.getYaw(v)
    - hf — let hf = Viewer.getHfov(v)
    - dispatchEvent — let dispatchEvent: (float, float, float, float, float) => unit = %raw(`
    - initializeViewer — let initializeViewer = initialize
    - destroy — let destroy = v => {
    - _ — let _ = %raw(`
    - getPitch — let getPitch = v => Viewer.getPitch(v)
    - getYaw — let getYaw = v => Viewer.getYaw(v)
    - getHfov — let getHfov = v => Viewer.getHfov(v)
    - setPitch — let setPitch = (v, p, a) => Viewer.setPitch(v, p, a)
    - setYaw — let setYaw = (v, y, a) => Viewer.setYaw(v, y, a)
    - setHfov — let setHfov = (v, h, a) => Viewer.setHfov(v, h, a)
    - setView — let setView = (v, ~pitch=?, ~yaw=?, ~hfov=?, ~animated=false, ()) => {
    - addHotSpot — let addHotSpot = (v, config) => Viewer.addHotSpot(v, config)
    - removeHotSpot — let removeHotSpot = (v, id) => Viewer.removeHotSpot(v, id)
    - getScene — let getScene = v => Viewer.getScene(v)
    - loadScene — let loadScene = (v, sceneId, ~pitch=?, ~yaw=?, ~hfov=?, ()) => {
    - p — let p = pitch->Option.getOr(Viewer.getPitch(v))
    - y — let y = yaw->Option.getOr(Viewer.getYaw(v))
    - h — let h = hfov->Option.getOr(Viewer.getHfov(v))
    - addScene — let addScene = (v, id, config) => Viewer.addScene(v, id, config)
    - on — let on = (v, ev, cb) => Viewer.on(v, ev, cb)
    - isLoaded — let isLoaded = v => Viewer.isLoaded(v)
    - setMetaData — let setMetaData = (v, key, value) => {
    - c — let c = asCustom(v)
    - getMetaData — let getMetaData = (v, key) => {
    - c — let c = asCustom(v)
    - pool — let pool = ref([
    - getViewport — let getViewport = id => pool.contents->Belt.Array.getBy(v => v.id == id)
    - getViewportByContainer — let getViewportByContainer = cId => pool.contents->Belt.Array.getBy(v => v.containerId == cId)
    - getActive — let getActive = () => pool.contents->Belt.Array.getBy(v => v.status == #Active)
    - getActiveViewer — let getActiveViewer = () => getActive()->Option.flatMap(v => v.instance)
    - getInactive — let getInactive = () => pool.contents->Belt.Array.getBy(v => v.status == #Background)
    - getInactiveViewer — let getInactiveViewer = () => getInactive()->Option.flatMap(v => v.instance)
    - swapActive — let swapActive = () =>
    - registerInstance — let registerInstance = (cId, inst) =>
    - clearInstance — let clearInstance = cId =>
    - setCleanupTimeout — let setCleanupTimeout = (id, t) =>
    - clearCleanupTimeout — let clearCleanupTimeout = id =>
    - reset — let reset = () => {
    - isInsideDeadZone — let isInsideDeadZone = (startPt, lastMouse) => {
    - d — let d = Math.sqrt(
    - busy — let busy =
    - vOpt — let vOpt = Pool.getActiveViewer()
    - s — let s = getState()
    - hasHotspots — let hasHotspots = if s.activeIndex >= 0 && s.activeIndex < Array.length(s.scenes) {
    - fsmBusy — let fsmBusy = switch Nullable.toOption(Adapter.asAny(s)["navigationState"]) {
    - startPt — let startPt = ViewerState.state.contents.linkingStartPoint->Nullable.toOption
    - lastMouse — let lastMouse = ViewerState.state.contents.lastMouseEvent->Nullable.toOption
    - yb — let yb = ViewerLogic.getBoost(ViewerState.state.contents.mouseVelocityX)
    - pb — let pb = ViewerLogic.getBoost(ViewerState.state.contents.mouseVelocityY)
    - yd — let yd = insideDz
    - pd — let pd = insideDz
    - me — let me = ViewerState.state.contents.lastMouseEvent->Nullable.toOption
    - _ — let _ = Window.requestAnimationFrame(() => updateFollowLoop(~getState))
    - getActiveViewer — let getActiveViewer = () => Pool.getActiveViewer()->Nullable.fromOption
    - getInactiveViewer — let getInactiveViewer = () => Pool.getInactiveViewer()->Nullable.fromOption
    - getActiveContainerId — let getActiveContainerId = () =>
    - getInactiveContainerId — let getInactiveContainerId = () =>
    - resetState — let resetState = () => {
    - isViewerValid — let isViewerValid = (viewer: Viewer.t): bool => {
    - loaded — let loaded = Viewer.isLoaded(viewer)
    - hfov — let hfov = Viewer.getHfov(viewer)
    - yaw — let yaw = Viewer.getYaw(viewer)
    - pitch — let pitch = Viewer.getPitch(viewer)
    - isActiveViewer — let isActiveViewer = (viewer: Viewer.t): bool => {
    - activeViewer — let activeViewer = getActiveViewer()
    - isViewerReady — let isViewerReady = (viewer: Viewer.t): bool => {
    - destroyViewer — let destroyViewer = Adapter.destroy
