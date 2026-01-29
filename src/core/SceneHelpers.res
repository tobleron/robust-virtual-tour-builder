/* src/core/SceneHelpers.res */

open Types

// --- Parser ---

let sanitizeScene = (s: scene): scene => {
  if s.id == "" {
    {...s, id: "legacy_" ++ s.name}
  } else {
    s
  }
}

let parseScene = (dataJson: JSON.t): scene => {
  switch Schemas.parse(dataJson, Schemas.Domain.scene) {
  | Ok(data) => sanitizeScene(data)
  | Error(msg) =>
    Logger.error(
      ~module_="SceneHelpersParser",
      ~message="SCHEMA_PARSE_ERROR_SCENE",
      ~data=Logger.castToJson({"error": msg}),
      (),
    )
    {
      id: "error_" ++ Float.toString(Date.now()),
      name: "invalid",
      file: Types.Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "outdoor",
      floor: "ground",
      label: "",
      quality: None,
      colorGroup: None,
      _metadataSource: "default",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }
  }
}

let parseProject = (projectDataJson: JSON.t): state => {
  switch Schemas.parse(projectDataJson, Schemas.Domain.project) {
  | Ok(pd) => {
      let scenes = pd.scenes->Belt.Array.map(sanitizeScene)
      {
        ...State.initialState,
        tourName: pd.tourName,
        scenes,
        activeIndex: if Array.length(scenes) > 0 {
          0
        } else {
          -1
        },
        lastUsedCategory: pd.lastUsedCategory,
        exifReport: pd.exifReport,
        sessionId: pd.sessionId,
        deletedSceneIds: pd.deletedSceneIds,
        timeline: pd.timeline,
      }
    }
  | Error(msg) =>
    Logger.error(
      ~module_="SceneHelpersParser",
      ~message="SCHEMA_PARSE_ERROR_PROJECT",
      ~data=Logger.castToJson({"error": msg}),
      (),
    )
    State.initialState
  }
}

// --- Logic ---

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

let handleRemoveHotspot = (state: state, sceneIndex: int, hotspotIndex: int): state => {
  let scenes = state.scenes
  switch Belt.Array.get(scenes, sceneIndex) {
  | Some(sourceScene) =>
    switch Belt.Array.get(sourceScene.hotspots, hotspotIndex) {
    | Some(hotspotToDelete) =>
      let targetName = hotspotToDelete.target

      // 1. Remove the hotspot
      let newSourceHotspots = Belt.Array.keepWithIndex(sourceScene.hotspots, (_, i) =>
        i != hotspotIndex
      )
      let scenesWithRemovedHotspot = Belt.Array.mapWithIndex(scenes, (i, s) => {
        if i == sceneIndex {
          {...s, hotspots: newSourceHotspots}
        } else {
          s
        }
      })

      // 2. Check if anything else still points to targetName
      let stillReferenced = Belt.Array.some(scenesWithRemovedHotspot, s => {
        Belt.Array.some(s.hotspots, h => h.target == targetName)
      })

      // 3. If no longer referenced, reset target scene's isAutoForward
      let finalScenes = if !stillReferenced {
        Belt.Array.map(scenesWithRemovedHotspot, s => {
          if s.name == targetName {
            {...s, isAutoForward: false}
          } else {
            s
          }
        })
      } else {
        scenesWithRemovedHotspot
      }

      {...state, scenes: finalScenes}
    | None => state
    }
  | None => state
  }
}

let handleAddScenes = (state: state, scenesData: array<JSON.t>): state => {
  let wasEmpty = Belt.Array.length(state.scenes) == 0

  let newScenes = Belt.Array.reduce(scenesData, state.scenes, (acc, dataJson) => {
    let id = switch Schemas.parse(dataJson, Schemas.Domain.scene) {
    | Ok(data) => data.id
    | Error(_) => "error_" ++ Float.toString(Date.now())
    }
    if Belt.Array.some(acc, s => s.id == id) {
      acc
    } else {
      let newScene = parseScene(dataJson)
      Belt.Array.concat(acc, [newScene])
    }
  })

  let sortedScenes = Array.copy(newScenes)
  Array.sort(sortedScenes, (a, b) => {
    String.localeCompare(a.name, b.name)
  })

  let finalScenes = syncSceneNames(sortedScenes)

  let activeIndex = if (
    (wasEmpty || state.activeIndex == -1 || state.activeIndex >= Belt.Array.length(finalScenes)) &&
      Belt.Array.length(finalScenes) > 0
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

let handleUpdateSceneMetadata = (state: state, index: int, metaJson: JSON.t): state => {
  let scenes = state.scenes
  let meta = switch Schemas.parse(metaJson, Schemas.Domain.updateMetadata) {
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
