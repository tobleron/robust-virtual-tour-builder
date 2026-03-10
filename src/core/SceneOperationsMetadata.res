// @efficiency-role: domain-logic

open Types

let emptySceneMetadataUpdate = () => {
  category: None,
  floor: None,
  label: None,
  isAutoForward: None,
}

let decodeSceneMetadataUpdate = metaJson => {
  switch JsonCombinators.Json.decode(metaJson, JsonParsers.Domain.updateMetadata) {
  | Ok(meta) => meta
  | Error(_) => emptySceneMetadataUpdate()
  }
}

let handleUpdateSceneMetadata = (state: state, index: int, metaJson: JSON.t): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, index) {
    | Some(targetId) =>
      switch state.inventory->Belt.Map.String.get(targetId) {
      | Some({scene} as entry) =>
        let meta = decodeSceneMetadataUpdate(metaJson)

        let newCategory = switch meta.category {
        | Some(category) => category
        | None => scene.category
        }
        let newFloor = switch meta.floor {
        | Some(floor) => floor
        | None => scene.floor
        }
        let newLabel = switch meta.label {
        | Some(label) => label
        | None => scene.label
        }
        let newIsAutoForward = switch meta.isAutoForward {
        | Some(isAutoForward) => isAutoForward
        | None => scene.isAutoForward
        }
        let categorySet = switch meta.category {
        | Some(_) => true
        | None => scene.categorySet
        }

        let manualBaseName = switch JSON.Decode.object(metaJson) {
        | Some(obj) =>
          switch Dict.get(obj, "_baseName") {
          | Some(value) => JSON.Decode.string(value)
          | None => None
          }
        | None => None
        }

        let updatedScene = {
          ...scene,
          category: newCategory,
          floor: newFloor,
          label: newLabel,
          isAutoForward: newIsAutoForward,
          categorySet,
        }

        let finalScene = switch manualBaseName {
        | Some(base) if base != "" =>
          let newName = TourLogic.computeSceneFilename(scene.sequenceId, newLabel, base)
          {...updatedScene, name: newName}
        | _ => updatedScene
        }

        let updatedInventory =
          state.inventory->Belt.Map.String.set(targetId, {...entry, scene: finalScene})
        let finalizedInventory = SceneNaming.syncInventoryNames(updatedInventory, state.sceneOrder)

        {
          ...state,
          inventory: finalizedInventory,
          lastUsedCategory: switch meta.category {
          | Some(category) => category
          | None => state.lastUsedCategory
          },
        }
      | None => state
      }
    | None => state
    }
  | _ => state
  }
}

let handleSetActiveScene = (
  state: state,
  index: int,
  yaw: float,
  pitch: float,
  transition: option<transition>,
): state => {
  if index >= 0 && index < Belt.Array.length(state.sceneOrder) {
    let newTransition = SceneInventory.calculateTransition(transition)
    let updatedInventory = SceneInventory.updateSceneCategories(
      state.inventory,
      state.sceneOrder,
      index,
      state.lastUsedCategory,
    )

    {
      ...state,
      inventory: updatedInventory,
      activeIndex: index,
      activeYaw: yaw,
      activePitch: pitch,
      transition: newTransition,
      isLinking: false,
      linkDraft: None,
      movingHotspot: None,
    }
  } else {
    state
  }
}

let handleApplyLazyRename = (state: state, index: int, name: string): state => {
  switch Belt.Array.get(state.sceneOrder, index) {
  | Some(id) =>
    switch state.inventory->Belt.Map.String.get(id) {
    | Some({scene} as entry) =>
      let updatedInventory =
        state.inventory->Belt.Map.String.set(id, {...entry, scene: {...scene, label: name}})
      let finalizedInventory = SceneNaming.syncInventoryNames(updatedInventory, state.sceneOrder)
      {...state, inventory: finalizedInventory}
    | None => state
    }
  | None => state
  }
}

let handlePatchSceneThumbnail = (state: state, id: string, file: file): state => {
  switch state.inventory->Belt.Map.String.get(id) {
  | Some(entry) =>
    let updatedScene = {...entry.scene, tinyFile: Some(file)}
    let updatedInventory = state.inventory->Belt.Map.String.set(id, {...entry, scene: updatedScene})
    SceneCache.clearThumbUrl(id)
    SceneCache.clearThumbUrl(id ++ "_tiny")
    {...state, inventory: updatedInventory}
  | None => state
  }
}
