open Types

let getActiveScenes = (inventory, sceneOrder) => {
  SceneInventory.getActiveScenes(inventory, sceneOrder)
}

let getDeletedIds = inventory => {
  SceneInventory.getDeletedIds(inventory)
}

let syncInventoryNames = (inventory, sceneOrder) => {
  SceneNaming.syncInventoryNames(inventory, sceneOrder)
}

let rebuildLegacyFields = (state: state): state => {
  SceneInventory.rebuildLegacyFields(state)
}

let calculateActiveIndexAfterDelete = (
  currentIndex: int,
  deletedIndex: int,
  newOrderLength: int,
): int => {
  SceneInventory.calculateActiveIndexAfterDelete(currentIndex, deletedIndex, newOrderLength)
}

let handleDeleteScene = (state: state, index: int): state => {
  SceneOperations.handleDeleteScene(state, index)
}

let handleReorderScenes = (state: state, fromIndex: int, toIndex: int): state => {
  SceneOperations.handleReorderScenes(state, fromIndex, toIndex)
}

let updateSceneCategories = (
  inventory: Belt.Map.String.t<sceneEntry>,
  sceneOrder: array<string>,
  targetIndex: int,
  lastUsedCategory: string,
): Belt.Map.String.t<sceneEntry> => {
  SceneInventory.updateSceneCategories(inventory, sceneOrder, targetIndex, lastUsedCategory)
}

let handleAddScenes = (state: state, scenesData: array<JSON.t>): state => {
  SceneOperations.handleAddScenes(state, scenesData)
}

let handleUpdateSceneMetadata = (state: state, index: int, metaJson: JSON.t): state => {
  SceneOperations.handleUpdateSceneMetadata(state, index, metaJson)
}

let calculateTransition = (transition: option<transition>): transition => {
  SceneInventory.calculateTransition(transition)
}

let handleSetActiveScene = (
  state: state,
  index: int,
  yaw: float,
  pitch: float,
  transition: option<transition>,
): state => {
  SceneOperations.handleSetActiveScene(state, index, yaw, pitch, transition)
}

let handleApplyLazyRename = (state: state, index: int, name: string): state => {
  SceneOperations.handleApplyLazyRename(state, index, name)
}

let syncSceneNames = (scenes: array<Types.scene>) => {
  SceneNaming.syncSceneNames(scenes)
}
