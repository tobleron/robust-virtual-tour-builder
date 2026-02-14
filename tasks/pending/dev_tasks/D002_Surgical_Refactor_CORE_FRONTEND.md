# Task D002: Surgical Refactor CORE FRONTEND

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

- [ ] - **../../src/core/Reducer.res** (Metric: [Nesting: 5.40, Density: 0.28, Coupling: 0.10] | Drag: 6.68 | LOC: 409/300  🎯 Target: Function: `finalState` (High Local Complexity (2.0). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D002/verification.json` (files at `_dev-system/tmp/D002/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D002/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/core/Reducer.res`
- `src/core/Reducer.res` (32 functions, fingerprint f83955b3476ee464a4e3f334a2ee9209e771cb20e1bd367da123e284e28696c0)
    - updateInteractive — updateInteractive = (state: state, updater: interactiveState => interactiveState): state => {
    - updateUiMode — updateUiMode = (state: state, mode: uiMode): state => {
    - updateNavigation — updateNavigation = (state: state, nav: NavigationFSM.distinctState): state => {
    - updateBackgroundTask — updateBackgroundTask = (state: state, task: option<backgroundTask>): state => {
    - handleAddScenes — handleAddScenes = (state: state, scenesData): state => {
    - handleDeleteScene — handleDeleteScene = (state: state, index: int): state => {
    - handleReorderScenes — handleReorderScenes = (state: state, fromIndex: int, toIndex: int): state => {
    - handleSetActiveScene — handleSetActiveScene = (
    - handleUpdateSceneMetadata — handleUpdateSceneMetadata = (state: state, index: int, metaJson): state => {
    - handleSyncSceneNames — handleSyncSceneNames = (state: state): state => {
    - handleApplyLazyRename — handleApplyLazyRename = (state: state, index: int, name: string): state => {
    - reduce — reduce = (state: state, action: action): option<state> => {
    - reduce — reduce = (state: state, action: action): option<state> => {
    - reduce — reduce = (state: state, action: action): option<state> => {
    - reduce — reduce = (state: state, action: action): option<state> => {
    - nextAppMode — nextAppMode = AppFSM.transition(state.appMode, event)
    - nextState — nextState = {...state, appMode: nextAppMode}
    - reduce — reduce = (state: state, action: action): option<state> => {
    - resetNavState — resetNavState = {
    - nextState — nextState = {...state, navigationState: nextNavState}
    - nextAppMode — nextAppMode = AppFSM.transition(state.appMode, event)
    - nextState — nextState = {...state, appMode: nextAppMode}
    - finalState — finalState = switch nextAppMode {
    - reduce — reduce = (state: state, action: action): option<state> => {
    - reduce — reduce = (state: state, action: action): option<state> => {
    - item — item = SimHelpers.parseTimelineItem(json)
    - itemOpt — itemOpt = Belt.Array.get(state.timeline, fromIdx)
    - rest — rest = Belt.Array.keepWithIndex(state.timeline, (_, i) => i != fromIdx)
    - newTimeline — newTimeline = UiHelpers.insertAt(rest, toIdx, item)
    - reduce — reduce = (state: state, action: action): option<state> => {
    - apply — apply = (state: state, action: action, reducerFn: (state, action) => option<state>): state => {
    - reducer — reducer = (state: state, action: action): state => {
