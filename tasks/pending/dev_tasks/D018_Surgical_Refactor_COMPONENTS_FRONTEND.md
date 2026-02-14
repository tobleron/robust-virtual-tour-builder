# Task D018: Surgical Refactor COMPONENTS FRONTEND

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

- [ ] - **../../src/components/VisualPipeline.res** (Metric: [Nesting: 4.80, Density: 0.05, Coupling: 0.06] | Drag: 5.86 | LOC: 469/300)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D018/verification.json` (files at `_dev-system/tmp/D018/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D018/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/VisualPipeline.res`
- `src/components/VisualPipeline.res` (64 functions, fingerprint 5793ffa219c836c4dcc899ef337a7e1c086bc12bf52a465811a1e09c147a8b90)
    - handleDragStart — handleDragStart = (pipeline: t, e) => {
    - target — target = Dom.target(e)
    - id — id = Dict.get(Dom.dataset(target), "id")->Option.getOr("")
    - handleDragEnd — handleDragEnd = (pipeline: t, e) => {
    - target — target = Dom.target(e)
    - handleDragOver — handleDragOver = e => {
    - handleDragEnter — handleDragEnter = e => {
    - target — target = Dom.target(e)
    - handleDragLeave — handleDragLeave = e => {
    - target — target = Dom.target(e)
    - handleDrop — handleDrop = (
    - target — target = Dom.target(e)
    - dropIndex — dropIndex =
    - state — state = getState()
    - sourceIndex — sourceIndex =
    - finalIndex — finalIndex = if dropIndex > sourceIndex {
    - createDropZone — createDropZone = (pipeline: t, index: int, ~getState, ~dispatch) => {
    - zone — zone = Dom.createElement("div")
    - _ — _ = handleDragOver(e)
    - render — render = (pipeline: t, state: Types.state, ~getState, ~dispatch) => {
    - track — track = Dom.querySelector(pipeline.wrapper, ".pipeline-track")
    - fragment — fragment = Dom.createDocumentFragment()
    - firstZone — firstZone = createDropZone(pipeline, 0, ~getState, ~dispatch)
    - node — node = Dom.createElement("div")
    - activateNode — activateNode = () => {
    - sceneIdx — sceneIdx =
    - hotspot — hotspot = s.hotspots->Belt.Array.getBy(h => h.linkId == item.linkId)
    - scene — scene = state.scenes->Belt.Array.getBy(s => s.id == item.sceneId)
    - color — color = ref("var(--success-dark)")
    - isActive — isActive = switch state.activeTimelineStepId {
    - firstMatchIdx — firstMatchIdx =
    - key — key = Dom.key(e)
    - thumbUrl — thumbUrl = ref("")
    - thumbName — thumbName = ref("Unknown Scene")
    - file — file = switch sc.tinyFile {
    - url — url = UrlUtils.fileToUrl(file)
    - targetScene — targetScene = state.scenes->Belt.Array.getBy(s => s.name == item.targetScene)
    - isAutoForward — isAutoForward = switch targetScene {
    - tooltip — tooltip = Dom.createElement("div")
    - linkIdSpan — linkIdSpan = Dom.createElement("span")
    - img — img = Dom.createElement("img")
    - textSpan — textSpan = Dom.createElement("span")
    - indicator — indicator = Dom.createElement("span")
    - nextZone — nextZone = InternalLogic.createDropZone(pipeline, index + 1, ~getState, ~dispatch)
    - nodeSize — nodeSize = 22
    - styles — styles =
    - render — render = InternalRender.render
    - injectStyles — injectStyles = () => {
    - existing — existing = Dom.getElementById("visual-pipeline-styles")
    - style — style = Dom.createElement("style")
    - initByElement — initByElement = (c: Dom.element) => {
    - wrapper — wrapper = Dom.createElement("div")
    - track — track = Dom.createElement("div")
    - pipeline — pipeline = {
    - init — init = (containerId: string) => {
    - container — container = Dom.getElementById(containerId)
    - make — make = () => {
    - containerRef — containerRef = React.useRef(Nullable.null)
    - appState — appState = AppContext.useAppState()
    - dispatch — dispatch = AppContext.useAppDispatch()
    - stateRef — stateRef = React.useRef(appState)
    - getState — getState = () => stateRef.current
    - pipelineRef — pipelineRef = React.useRef(None)
    - pipeline — pipeline = initByElement(c)
