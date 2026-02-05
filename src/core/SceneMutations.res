open Types

let syncSceneNames = (scenes: array<scene>) => {
  let renameMap = Belt.MutableMap.String.make()

  // 1. Update scene names based on labels
  let updatedScenes = Belt.Array.mapWithIndex(scenes, (index, scene) => {
    if scene.label != "" {
      let oldName = scene.name
      let newName = TourLogic.computeSceneFilename(index, scene.label)
      if newName != oldName {
        let _ = Belt.MutableMap.String.set(renameMap, oldName, newName)
        {...scene, name: newName}
      } else {
        scene
      }
    } else {
      scene
    }
  })

  // 2. Update hotspot targets if renames happened
  if Belt.MutableMap.String.size(renameMap) > 0 {
    Belt.Array.map(updatedScenes, s => {
      let updatedHotspots = Belt.Array.map(s.hotspots, h => {
        switch Belt.MutableMap.String.get(renameMap, h.target) {
        | Some(newName) => {...h, target: newName}
        | None => h
        }
      })
      {...s, hotspots: updatedHotspots}
    })
  } else {
    updatedScenes
  }
}

let calculateActiveIndexAfterDelete = (
  currentIndex: int,
  deletedIndex: int,
  newScenesLength: int,
): int => {
  if newScenesLength == 0 {
    -1
  } else if deletedIndex == currentIndex {
    if deletedIndex < newScenesLength {
      deletedIndex
    } else {
      newScenesLength - 1
    }
  } else if deletedIndex < currentIndex {
    currentIndex - 1
  } else {
    currentIndex
  }
}

let handleDeleteScene = (state: state, index: int): state => {
  switch state.appMode {
  | InteractiveAuthoring(_) => {
      let scenes = state.scenes
      switch Belt.Array.get(scenes, index) {
      | Some(sceneToDelete) =>
        let targetName = sceneToDelete.name

        let newScenes = Belt.Array.keepWithIndex(scenes, (_, i) => i != index)

        // Remove hotspots pointing to deleted scene
        let cleanupScenes = Belt.Array.map(newScenes, s => {
          let newHotspots = Belt.Array.keep(s.hotspots, h => h.target != targetName)
          {...s, hotspots: newHotspots}
        })

        let newDeletedIds = if (
          sceneToDelete.id != "" &&
            !Belt.Array.some(state.deletedSceneIds, id => id == sceneToDelete.id)
        ) {
          Belt.Array.concat(state.deletedSceneIds, [sceneToDelete.id])
        } else {
          state.deletedSceneIds
        }

        // Adjust activeIndex
        let newLen = Belt.Array.length(cleanupScenes)
        let newActiveIndex = calculateActiveIndexAfterDelete(state.activeIndex, index, newLen)

        let baseState = {
          ...state,
          scenes: syncSceneNames(cleanupScenes),
          deletedSceneIds: newDeletedIds,
          activeIndex: newActiveIndex,
        }

        if newLen == 0 {
          {...baseState, activeYaw: 0.0, activePitch: 0.0}
        } else {
          baseState
        }
      | None => state
      }
    }
  | _ => state
  }
}

let handleReorderScenes = (state: state, fromIndex: int, toIndex: int): state => {
  switch state.appMode {
  | InteractiveAuthoring(_) =>
    if fromIndex != toIndex {
      let scenes = state.scenes
      switch Belt.Array.get(scenes, fromIndex) {
      | Some(movedItem) =>
        let rest = Belt.Array.keepWithIndex(scenes, (_, i) => i != fromIndex)
        let newScenes = UiHelpers.insertAt(rest, toIndex, movedItem)

        let newActiveIndex = if state.activeIndex == fromIndex {
          toIndex
        } else if state.activeIndex > fromIndex && state.activeIndex <= toIndex {
          state.activeIndex - 1
        } else if state.activeIndex < fromIndex && state.activeIndex >= toIndex {
          state.activeIndex + 1
        } else {
          state.activeIndex
        }

        {...state, scenes: syncSceneNames(newScenes), activeIndex: newActiveIndex}
      | None => state
      }
    } else {
      state
    }
  | _ => state
  }
}

let updateSceneCategories = (
  scenes: array<scene>,
  targetIndex: int,
  lastUsedCategory: string,
): array<scene> => {
  scenes->Belt.Array.mapWithIndex((i, s) => {
    if i == targetIndex && !s.categorySet {
      {...s, category: lastUsedCategory}
    } else {
      s
    }
  })
}

let handleAddScenes = (state: state, scenesData: array<JSON.t>): state => {
  switch state.appMode {
  | InteractiveAuthoring(_)
  | InteractiveTouring(_)
  | SystemBlocking(Uploading(_)) => {
      let wasEmpty = Belt.Array.length(state.scenes) == 0

      let newScenes = Belt.Array.reduce(scenesData, state.scenes, (acc, dataJson) => {
        let id = switch JsonCombinators.Json.decode(dataJson, JsonParsers.Domain.scene) {
        | Ok(data) => data.id
        | Error(_) => "error_" ++ Float.toString(Date.now())
        }
        if Belt.Array.some(acc, s => s.id == id) {
          acc
        } else {
          let newScene = SceneHelpers.parseScene(dataJson)
          Belt.Array.concat(acc, [newScene])
        }
      })

      let sortedScenes = Array.copy(newScenes)
      Array.sort(sortedScenes, (a, b) => {
        String.localeCompare(a.name, b.name)
      })

      let finalScenes = syncSceneNames(sortedScenes)

      let activeIndex = if (
        (wasEmpty ||
        state.activeIndex == -1 ||
        state.activeIndex >= Belt.Array.length(finalScenes)) && Belt.Array.length(finalScenes) > 0
      ) {
        0
      } else {
        state.activeIndex
      }

      if wasEmpty && activeIndex == 0 {
        {...state, scenes: finalScenes, activeIndex, activeYaw: 0.0, activePitch: 0.0}
      } else {
        {...state, scenes: finalScenes, activeIndex}
      }
    }
  | _ => state
  }
}

let handleUpdateSceneMetadata = (state: state, index: int, metaJson: JSON.t): state => {
  switch state.appMode {
  | InteractiveAuthoring(_)
  | InteractiveTouring(_) => {
      let scenes = state.scenes
      let meta = switch JsonCombinators.Json.decode(metaJson, JsonParsers.Domain.updateMetadata) {
      | Ok(m) => m
      | Error(_) => {
          category: None,
          floor: None,
          label: None,
          isAutoForward: None,
        }
      }

      let updatedLastUsedCategory = ref(state.lastUsedCategory)

      let newScenes = Belt.Array.mapWithIndex(scenes, (i, s) => {
        if i == index {
          let newCategory = switch meta.category {
          | Some(c) =>
            updatedLastUsedCategory.contents = c
            c
          | None => s.category
          }
          let newFloor = switch meta.floor {
          | Some(f) => f
          | None => s.floor
          }
          let newLabel = switch meta.label {
          | Some(l) => l
          | None => s.label
          }
          let newIsAutoForward = switch meta.isAutoForward {
          | Some(af) => af
          | None => s.isAutoForward
          }
          let categorySet = switch meta.category {
          | Some(_) => true
          | None => s.categorySet
          }
          {
            ...s,
            category: newCategory,
            floor: newFloor,
            label: newLabel,
            isAutoForward: newIsAutoForward,
            categorySet,
          }
        } else {
          s
        }
      })
      {...state, scenes: newScenes, lastUsedCategory: updatedLastUsedCategory.contents}
    }
  | _ => state
  }
}

let calculateTransition = (transition: option<transition>): transition => {
  switch transition {
  | Some(t) => t
  | None => {type_: Fade, targetHotspotIndex: -1, fromSceneName: None}
  }
}

let handleSetActiveScene = (
  state: state,
  index: int,
  yaw: float,
  pitch: float,
  transition: option<transition>,
): state => {
  if index >= 0 && index < Belt.Array.length(state.scenes) {
    let newTransition = calculateTransition(transition)
    let newScenes = updateSceneCategories(state.scenes, index, state.lastUsedCategory)

    {
      ...state,
      scenes: newScenes,
      activeIndex: index,
      activeYaw: yaw,
      activePitch: pitch,
      transition: newTransition,
    }
  } else {
    state
  }
}

let handleApplyLazyRename = (state: state, index: int, name: string): state => {
  let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
    if i == index {
      {...s, label: name}
    } else {
      s
    }
  })
  {...state, scenes: syncSceneNames(newScenes)}
}
