open Types
open UiHelpers

// ============================================================================
// PARSING FUNCTIONS
// ============================================================================

let parseHotspots = (hss: array<JsonTypes.hotspotJson>): array<hotspot> => {
  Belt.Array.map(hss, hs => {
    {
      linkId: switch Nullable.toOption(hs.linkId) {
      | Some(id) => id
      | None => ""
      },
      yaw: hs.yaw,
      pitch: hs.pitch,
      target: hs.target,
      targetYaw: Nullable.toOption(hs.targetYaw),
      targetPitch: Nullable.toOption(hs.targetPitch),
      targetHfov: Nullable.toOption(hs.targetHfov),
      startYaw: Nullable.toOption(hs.startYaw),
      startPitch: Nullable.toOption(hs.startPitch),
      startHfov: Nullable.toOption(hs.startHfov),
      isReturnLink: Nullable.toOption(hs.isReturnLink),
      viewFrame: switch Nullable.toOption(hs.viewFrame) {
      | Some(vf) => Some(({yaw: vf.yaw, pitch: vf.pitch, hfov: vf.hfov}: viewFrame))
      | None => None
      },
      returnViewFrame: switch Nullable.toOption(hs.returnViewFrame) {
      | Some(vf) => Some(({yaw: vf.yaw, pitch: vf.pitch, hfov: vf.hfov}: viewFrame))
      | None => None
      },
      waypoints: switch Nullable.toOption(hs.waypoints) {
      | Some(wps) =>
        Some(Belt.Array.map(wps, (wp): viewFrame => {yaw: wp.yaw, pitch: wp.pitch, hfov: wp.hfov}))
      | None => None
      },
      displayPitch: Nullable.toOption(hs.displayPitch),
      transition: Nullable.toOption(hs.transition),
      duration: switch Nullable.toOption(hs.duration) {
      | Some(d) => Some(Belt.Float.toInt(d))
      | None => None
      },
    }
  })
}

let parseScene = (dataJson: JSON.t): scene => {
  let data = switch JsonTypes.decodeImportScene(dataJson) {
  | Ok(d) => d
  | Error(_) =>
    (
      {
        id: "error_" ++ Float.toString(Date.now()),
        name: "invalid.webp",
        preview: JSON.Encode.null,
        tiny: Nullable.null,
        original: Nullable.null,
        quality: Nullable.null,
        colorGroup: Nullable.null,
      }: JsonTypes.importSceneJson
    )
  }
  {
    id: data.id,
    name: data.name,
    file: decodeFile(data.preview),
    tinyFile: Nullable.toOption(data.tiny)->Option.map(decodeFile),
    originalFile: Nullable.toOption(data.original)->Option.map(decodeFile),
    hotspots: [],
    category: "outdoor",
    floor: "ground",
    label: "",
    quality: Nullable.toOption(data.quality),
    colorGroup: Nullable.toOption(data.colorGroup),
    _metadataSource: "default",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
  }
}

let parseProject = (projectDataJson: JSON.t): state => {
  let pd = switch JsonTypes.decodeProject(projectDataJson) {
  | Ok(p) => p
  | Error(_) =>
    (
      {
        tourName: Nullable.null,
        scenes: [],
        lastUsedCategory: Nullable.null,
        exifReport: Nullable.null,
        sessionId: Nullable.null,
      }: JsonTypes.projectJson
    )
  }
  let tourName = switch Nullable.toOption(pd.tourName) {
  | Some(tn) if !TourLogic.isUnknownName(tn) => tn
  | _ => "Tour Name"
  }

  let scenes = Belt.Array.map(pd.scenes, sc => {
    {
      id: switch Nullable.toOption(sc.id) {
      | Some(id) => id
      | None => "legacy_" ++ sc.name
      },
      name: sc.name,
      file: decodeFile(sc.file),
      tinyFile: Nullable.toOption(sc.tinyFile)->Option.map(decodeFile),
      originalFile: Nullable.toOption(sc.originalFile)->Option.map(decodeFile),
      hotspots: switch Nullable.toOption(sc.hotspots) {
      | Some(hss) => parseHotspots(hss)
      | None => []
      },
      category: switch Nullable.toOption(sc.category) {
      | Some(c) => c
      | None => "outdoor"
      },
      floor: switch Nullable.toOption(sc.floor) {
      | Some(f) => f
      | None => "ground"
      },
      label: switch Nullable.toOption(sc.label) {
      | Some(l) => l
      | None => ""
      },
      quality: Nullable.toOption(sc.quality),
      colorGroup: Nullable.toOption(sc.colorGroup),
      _metadataSource: switch Nullable.toOption(sc.metadataSource) {
      | Some(m) => m
      | None => "user"
      },
      categorySet: switch Nullable.toOption(sc.categorySet) {
      | Some(cs) => cs
      | None => false
      },
      labelSet: switch Nullable.toOption(sc.labelSet) {
      | Some(ls) => ls
      | None => false
      },
      isAutoForward: switch Nullable.toOption(sc.isAutoForward) {
      | Some(af) => af
      | None => false
      },
    }
  })

  let lastUsedCategory = switch Nullable.toOption(pd.lastUsedCategory) {
  | Some(c) => c
  | None => "outdoor"
  }
  let exifReport = switch Nullable.toOption(pd.exifReport) {
  | Some(er) => Some(er)
  | None => None
  }

  {
    ...State.initialState,
    tourName,
    scenes,
    activeIndex: if Array.length(scenes) > 0 {
      0
    } else {
      -1
    },
    lastUsedCategory,
    exifReport,
  }
}

// ============================================================================
// SCENE NAME SYNCHRONIZATION
// ============================================================================

let syncSceneNames = (scenes: array<scene>) => {
  let renameMap = Belt.MutableMap.String.make()

  // 1. Update scene names based on labels
  let updatedScenes = Belt.Array.mapWithIndex(scenes, (index, scene) => {
    if scene.label != "" {
      let oldName = scene.name
      let newName = TourLogic.computeSceneFilename(index, scene.label)
      if newName != oldName {
        Belt.MutableMap.String.set(renameMap, oldName, newName)
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

// ============================================================================
// COMPLEX ACTION HANDLERS
// ============================================================================

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
    let newActiveIndex = if newLen == 0 {
      -1
    } else if index == state.activeIndex {
      if index < newLen {
        index
      } else {
        newLen - 1
      }
    } else if index < state.activeIndex {
      state.activeIndex - 1
    } else {
      state.activeIndex
    }

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
    let id = switch JsonTypes.decodeImportScene(dataJson) {
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
  let metaObj = switch JsonTypes.decodeUpdateMetadata(metaJson) {
  | Ok(m) => m
  | Error(_) =>
    (
      {
        category: Nullable.null,
        floor: Nullable.null,
        label: Nullable.null,
        isAutoForward: Nullable.null,
      }: JsonTypes.updateMetadataJson
    )
  }

  let updatedLastUsedCategory = ref(state.lastUsedCategory)

  let newScenes = Belt.Array.mapWithIndex(scenes, (i, s) => {
    if i == index {
      let newCategory = switch Nullable.toOption(metaObj.category) {
      | Some(c) =>
        updatedLastUsedCategory.contents = c
        c
      | None => s.category
      }
      let newFloor = switch Nullable.toOption(metaObj.floor) {
      | Some(f) => f
      | None => s.floor
      }
      let newLabel = switch Nullable.toOption(metaObj.label) {
      | Some(l) => l
      | None => s.label
      }
      let newIsAutoForward = switch Nullable.toOption(metaObj.isAutoForward) {
      | Some(af) => af
      | None => s.isAutoForward
      }
      let categorySet = switch Nullable.toOption(metaObj.category) {
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
