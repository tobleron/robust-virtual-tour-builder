open Types
open Actions

let handleAddScenes = (state: state, scenesData): state => {
  ReducerHelpers.handleAddScenes(state, scenesData)
}

let handleDeleteScene = (state: state, index: int): state => {
  ReducerHelpers.handleDeleteScene(state, index)
}

let handleReorderScenes = (state: state, fromIndex: int, toIndex: int): state => {
  if fromIndex != toIndex {
    let scenes = state.scenes
    switch Belt.Array.get(scenes, fromIndex) {
    | Some(movedItem) =>
      let rest = Belt.Array.keepWithIndex(scenes, (_, i) => i != fromIndex)
      let newScenes = ReducerHelpers.insertAt(rest, toIndex, movedItem)

      let newActiveIndex = if state.activeIndex == fromIndex {
        toIndex
      } else if state.activeIndex > fromIndex && state.activeIndex <= toIndex {
        state.activeIndex - 1
      } else if state.activeIndex < fromIndex && state.activeIndex >= toIndex {
        state.activeIndex + 1
      } else {
        state.activeIndex
      }

      {...state, scenes: ReducerHelpers.syncSceneNames(newScenes), activeIndex: newActiveIndex}
    | None => state
    }
  } else {
    state
  }
}

let handleSetActiveScene = (
  state: state,
  index: int,
  yaw: float,
  pitch: float,
  transition: option<transition>
): state => {
  if index >= 0 && index < Belt.Array.length(state.scenes) {
    let newTransition = switch transition {
    | Some(t) => t
    | None => {type_: None, targetHotspotIndex: -1, fromSceneName: None}
    }
    {...state, activeIndex: index, activeYaw: yaw, activePitch: pitch, transition: newTransition}
  } else {
    state
  }
}

let handleUpdateSceneMetadata = (state: state, index: int, metaJson): state => {
  ReducerHelpers.handleUpdateSceneMetadata(state, index, metaJson)
}

let handleSyncSceneNames = (state: state): state => {
  {...state, scenes: ReducerHelpers.syncSceneNames(state.scenes)}
}

let handleApplyLazyRename = (state: state, index: int, name: string): state => {
  let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
    if i == index {
      {...s, label: name}
    } else {
      s
    }
  })
  {...state, scenes: ReducerHelpers.syncSceneNames(newScenes)}
}

let reduce = (state: state, action: action): option<state> => {
  switch action {
  | AddScenes(scenesData) => Some(handleAddScenes(state, scenesData))
  | DeleteScene(index) => Some(handleDeleteScene(state, index))
  | ReorderScenes(fromIndex, toIndex) => Some(handleReorderScenes(state, fromIndex, toIndex))
  | SetActiveScene(index, yaw, pitch, transition) => 
      Some(handleSetActiveScene(state, index, yaw, pitch, transition))
  | UpdateSceneMetadata(index, metaJson) => Some(handleUpdateSceneMetadata(state, index, metaJson))
  | SyncSceneNames => Some(handleSyncSceneNames(state))
  | ApplyLazyRename(index, name) => Some(handleApplyLazyRename(state, index, name))
  | _ => None
  }
}
