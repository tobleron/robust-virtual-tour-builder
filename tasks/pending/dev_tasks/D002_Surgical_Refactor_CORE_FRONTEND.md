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

- [ ] - **../../src/core/SceneMutations.res** (Metric: [Nesting: 5.40, Density: 0.25, Coupling: 0.05] | Drag: 6.67 | LOC: 405/300  🎯 Target: Function: `getDeletedIds` (High Local Complexity (3.5). Logic heavy.))


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D002/verification.json` (files at `_dev-system/tmp/D002/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D002/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/core/Reducer.res`
- `src/core/Reducer.res` (31 functions, fingerprint c5fce2ba8a4621fb10b9c0996ca69e777e076092fde7d4e6fb290730ea5fd239)
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
    - nextAppMode — let nextAppMode = AppFSM.transition(state.appMode, event)
    - nextState — let nextState = {...state, appMode: nextAppMode}
    - reduce — let reduce = (state: state, action: action): option<state> => {
    - resetNavState — let resetNavState = {
    - nextState — let nextState = {...state, navigationState: nextNavState}
    - nextAppMode — let nextAppMode = AppFSM.transition(state.appMode, event)
    - nextState — let nextState = {...state, appMode: nextAppMode}
    - finalState — let finalState = switch nextAppMode {
    - reduce — let reduce = (state: state, action: action): option<state> => {
    - reduce — let reduce = (state: state, action: action): option<state> => {
    - item — let item = SimHelpers.parseTimelineItem(json)
    - itemOpt — let itemOpt = Belt.Array.get(state.timeline, fromIdx)
    - rest — let rest = Belt.Array.keepWithIndex(state.timeline, (_, i) => i != fromIdx)
    - newTimeline — let newTimeline = UiHelpers.insertAt(rest, toIdx, item)
    - reduce — let reduce = (state: state, action: action): option<state> => {
    - apply — let apply = (state: state, action: action, reducerFn: (state, action) => option<state>): state => {
### Pre-split snapshot for `src/core/SceneMutations.res`
- `src/core/SceneMutations.res` (68 functions, fingerprint 3b8bb04ad3b2575b2e33ecdca530659a7fb2b8f9d24cc028cf03bbbc404d4961)
    - getActiveScenes — let getActiveScenes = (inventory, sceneOrder) => {
    - getDeletedIds — let getDeletedIds = inventory => {
    - syncInventoryNames — let syncInventoryNames = (inventory, sceneOrder) => {
    - renameMap — let renameMap = Belt.MutableMap.String.make()
    - updatedRef — let updatedRef = ref(inventory)
    - oldName — let oldName = scene.name
    - baseName — let baseName = TourLogic.recoverBaseName(scene.name, scene.label)
    - newName — let newName = TourLogic.computeSceneFilename(index, scene.label, baseName)
    - _ — let _ = Belt.MutableMap.String.set(renameMap, oldName, newName)
    - inventoryWithRenames — let inventoryWithRenames = if Belt.MutableMap.String.size(renameMap) > 0 {
    - s — let s = entry.scene
    - updatedHotspots — let updatedHotspots = s.hotspots->Belt.Array.map(h => {
    - rebuildLegacyFields — let rebuildLegacyFields = (state: state): state => {
    - calculateActiveIndexAfterDelete — let calculateActiveIndexAfterDelete = (
    - handleDeleteScene — let handleDeleteScene = (state: state, index: int): state => {
    - targetName — let targetName = entry.scene.name
    - updatedInventory — let updatedInventory =
    - updatedOrder — let updatedOrder = state.sceneOrder->Belt.Array.keep(id => id != idToDelete)
    - inventoryWithCleanHotspots — let inventoryWithCleanHotspots = updatedInventory->Belt.Map.String.map(e => {
    - s — let s = e.scene
    - newHotspots — let newHotspots = s.hotspots->Belt.Array.keep(h => h.target != targetName)
    - newLen — let newLen = Belt.Array.length(updatedOrder)
    - newActiveIndex — let newActiveIndex = calculateActiveIndexAfterDelete(state.activeIndex, index, newLen)
    - finalizedInventory — let finalizedInventory = syncInventoryNames(inventoryWithCleanHotspots, updatedOrder)
    - handleReorderScenes — let handleReorderScenes = (state: state, fromIndex: int, toIndex: int): state => {
    - rest — let rest = state.sceneOrder->Belt.Array.keepWithIndex((_, i) => i != fromIndex)
    - updatedOrder — let updatedOrder = UiHelpers.insertAt(rest, toIndex, movedId)
    - newActiveIndex — let newActiveIndex = if state.activeIndex == fromIndex {
    - finalizedInventory — let finalizedInventory = syncInventoryNames(state.inventory, updatedOrder)
    - updateSceneCategories — let updateSceneCategories = (
    - handleAddScenes — let handleAddScenes = (state: state, scenesData: array<JSON.t>): state => {
    - modeStr — let modeStr = state.appMode->(
    - wasEmpty — let wasEmpty = Belt.Map.String.isEmpty(state.inventory)
    - newScene — let newScene = SceneHelpers.parseScene(dataJson)
    - mergedOrder — let mergedOrder = Belt.Array.concat(state.sceneOrder, addedIds)
    - sortedOrder — let sortedOrder = Array.copy(mergedOrder)
    - nameA — let nameA = switch updatedInventory->Belt.Map.String.get(a) {
    - nameB — let nameB = switch updatedInventory->Belt.Map.String.get(b) {
    - finalizedInventory — let finalizedInventory = syncInventoryNames(updatedInventory, sortedOrder)
    - activeIndex — let activeIndex = if (
    - nextState — let nextState = {
    - handleUpdateSceneMetadata — let handleUpdateSceneMetadata = (state: state, index: int, metaJson: JSON.t): state => {
    - meta — let meta = switch JsonCombinators.Json.decode(metaJson, JsonParsers.Domain.updateMetadata) {
    - newCategory — let newCategory = switch meta.category {
    - newFloor — let newFloor = switch meta.floor {
    - newLabel — let newLabel = switch meta.label {
    - newIsAutoForward — let newIsAutoForward = switch meta.isAutoForward {
    - categorySet — let categorySet = switch meta.category {
    - manualBaseName — let manualBaseName = switch JSON.Decode.object(metaJson) {
    - updatedScene — let updatedScene = {
    - finalScene — let finalScene = switch manualBaseName {
    - newName — let newName = TourLogic.computeSceneFilename(index, newLabel, base)
    - updatedInventory — let updatedInventory =
    - finalizedInventory — let finalizedInventory = syncInventoryNames(updatedInventory, state.sceneOrder)
    - calculateTransition — let calculateTransition = (transition: option<transition>): transition => {
    - handleSetActiveScene — let handleSetActiveScene = (
    - newTransition — let newTransition = calculateTransition(transition)
    - updatedInventory — let updatedInventory = updateSceneCategories(
    - handleApplyLazyRename — let handleApplyLazyRename = (state: state, index: int, name: string): state => {
    - updatedInventory — let updatedInventory =
    - finalizedInventory — let finalizedInventory = syncInventoryNames(updatedInventory, state.sceneOrder)
    - syncSceneNames — let syncSceneNames = (scenes: array<Types.scene>) => {
    - renameMap — let renameMap = Belt.MutableMap.String.make()
    - updatedScenes — let updatedScenes = Belt.Array.mapWithIndex(scenes, (index, scene) => {
    - oldName — let oldName = scene.name
    - newName — let newName = TourLogic.computeSceneFilename(index, scene.label, "")
    - _ — let _ = Belt.MutableMap.String.set(renameMap, oldName, newName)
    - updatedHotspots — let updatedHotspots = Belt.Array.map(s.hotspots, h => {
