open Types

let handleDeleteScene = (state: state, index: int): state => {
  SceneOperationsDelete.handleDeleteScene(state, index)
}

let handleReorderScenes = (state: state, fromIndex: int, toIndex: int): state => {
  SceneOperationsCollection.handleReorderScenes(state, fromIndex, toIndex)
}

let handleAddScenes = (state: state, scenesData: array<JSON.t>): state => {
  SceneOperationsCollection.handleAddScenes(state, scenesData)
}

let handleUpdateSceneMetadata = (state: state, index: int, metaJson: JSON.t): state => {
  SceneOperationsMetadata.handleUpdateSceneMetadata(state, index, metaJson)
}

let handleSetActiveScene = (
  state: state,
  index: int,
  yaw: float,
  pitch: float,
  transition: option<transition>,
): state => {
  SceneOperationsMetadata.handleSetActiveScene(state, index, yaw, pitch, transition)
}

let handleApplyLazyRename = (state: state, index: int, name: string): state => {
  SceneOperationsMetadata.handleApplyLazyRename(state, index, name)
}

let handlePatchSceneThumbnail = (state: state, id: string, file: file): state => {
  SceneOperationsMetadata.handlePatchSceneThumbnail(state, id, file)
}
