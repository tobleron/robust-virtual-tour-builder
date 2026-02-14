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
- `src/core/Reducer.res` (21 functions, fingerprint 821ce3f0a666d2face059a3d21bef6494d628027af877d44a0069274d62529af)
    - updateInteractive — let updateInteractive = (state: state, updater: interactiveState => interactiveState): state => {
    - updateUiMode — let updateUiMode = (state: state, mode: uiMode): state => {
    - updateNavigation — let updateNavigation = (state: state, nav: NavigationFSM.distinctState): state => {
    - updateBackgroundTask — let updateBackgroundTask = (state: state, task: option<backgroundTask>): state => {
    - handleAddScenes — let handleAddScenes = (state: state, scenesData): state => {
    - handleDeleteScene — let handleDeleteScene = (state: state, index: int): state => {
    - handleReorderScenes — let handleReorderScenes = (state: state, fromIndex: int, toIndex: int): state => {
    - handleSetActiveScene — let handleSetActiveScene = (
    - handleUpdateSceneMetadata — let handleUpdateSceneMetadata = (state: state, index: int, metaJson): state => {
    - handleSyncSceneNames — let handleSyncSceneNames = (state: state): state => {
    - handleApplyLazyRename — let handleApplyLazyRename = (state: state, index: int, name: string): state => {
    - reduce — let reduce = (state: state, action: action): option<state> => {
    - reduce — let reduce = (state: state, action: action): option<state> => {
    - reduce — let reduce = (state: state, action: action): option<state> => {
    - reduce — let reduce = (state: state, action: action): option<state> => {
    - reduce — let reduce = (state: state, action: action): option<state> => {
    - reduce — let reduce = (state: state, action: action): option<state> => {
    - reduce — let reduce = (state: state, action: action): option<state> => {
    - reduce — let reduce = (state: state, action: action): option<state> => {
    - apply — let apply = (state: state, action: action, reducerFn: (state, action) => option<state>): state => {
    - reducer — let rec reducer = (state: state, action: action): state => {
