# Task D007: Surgical Refactor COMPONENTS FRONTEND

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

- [ ] - **../../src/components/Sidebar.res** (Metric: [Nesting: 3.00, Density: 0.03, Coupling: 0.08] | Drag: 4.09 | LOC: 406/300  🎯 Target: Function: `make` (High Local Complexity (13.5). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D007/verification.json` (files at `_dev-system/tmp/D007/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D007/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/Sidebar.res`
- `src/components/Sidebar.res` (32 functions, fingerprint cb5f7ce22384a688f2531aa2fa7a216e1427ce3cec3eea5d041b1043d3636a28)
    - make — let make = () => {
    - toggleDiagnostic — let toggleDiagnostic = _ => {
    - make — let make = React.memo(() => {
    - sceneSlice — let sceneSlice = AppContext.useSceneSlice()
    - uiSlice — let uiSlice = AppContext.useUiSlice()
    - dispatch — let dispatch = AppContext.useAppDispatch()
    - getState — let getState = AppContext.getBridgeState
    - fileInputRef — let fileInputRef = React.useRef(Nullable.null)
    - projectFileInputRef — let projectFileInputRef = React.useRef(Nullable.null)
    - expectedTourName — let expectedTourName = React.useRef(sceneSlice.tourName)
    - actual — let actual = sceneSlice.tourName
    - local — let local = localTourName
    - expected — let expected = expectedTourName.current
    - timerId — let timerId = ReBindings.Window.setTimeout(
    - appearanceTimerRef — let appearanceTimerRef = React.useRef(Nullable.null)
    - hideTimerRef — let hideTimerRef = React.useRef(Nullable.null)
    - isBarVisible — let isBarVisible = React.useRef(false)
    - unsubscribe — let unsubscribe = EventBus.subscribe(
    - wantedActive — let wantedActive = payload["active"]
    - tid — let tid = ReBindings.Window.setTimeout(
    - tid — let tid = ReBindings.Window.setTimeout(
    - next — let next = Object.assign(Object.make(), prev)
    - totalHotspots — let totalHotspots =
    - teaserReady — let teaserReady = totalHotspots >= 3
    - exportReady — let exportReady = totalHotspots > 0
    - handleSave — let handleSave = async (~getState, ~signal, ~onCancel) => {
    - state — let state = getState()
    - success — let success = await ProjectManager.saveProject(state, ~signal, ~onProgress=(pct, _t, msg) => {
    - _ — let _ = ReBindings.Window.setTimeout(() => {
    - target — let target = JsxEvent.Form.target(e)->ReBindings.Dom.unsafeToElement
    - target — let target = JsxEvent.Form.target(e)->ReBindings.Dom.unsafeToElement
    - val — let val = JsxEvent.Form.target(e)["value"]
