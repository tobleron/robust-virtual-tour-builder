open JsonTypes
open Types

// Helper for array insertion
let insertAt = (arr, index, item) => {
  let before = Belt.Array.slice(arr, ~offset=0, ~len=index)
  let after = Belt.Array.slice(arr, ~offset=index, ~len=Belt.Array.length(arr) - index)
  Belt.Array.concatMany([before, [item], after])
}

// ============================================================================
// PARSING FUNCTIONS
// ============================================================================

let parseHotspots = (hss: array<hotspotJson>): array<hotspot> => {
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
      | Some(vf) => Some({yaw: vf.yaw, pitch: vf.pitch, hfov: vf.hfov})
      | None => None
      },
      returnViewFrame: switch Nullable.toOption(hs.returnViewFrame) {
      | Some(vf) => Some({yaw: vf.yaw, pitch: vf.pitch, hfov: vf.hfov})
      | None => None
      },
      waypoints: switch Nullable.toOption(hs.waypoints) {
      | Some(wps) => Some(Belt.Array.map(wps, wp => {yaw: wp.yaw, pitch: wp.pitch, hfov: wp.hfov}))
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
  let data = switch decodeImportScene(dataJson) {
  | Ok(d) => d
  | Error(_) => 
      // Fallback/Default for invalid data
      {
        id: "error_" ++ Float.toString(Date.now()),
        name: "invalid.webp",
        preview: JSON.Encode.null,
        tiny: Nullable.null,
        original: Nullable.null,
        quality: Nullable.null,
        colorGroup: Nullable.null,
      }
  }
  {
    id: data.id,
    name: data.name,
    file: data.preview,
    tinyFile: Nullable.toOption(data.tiny),
    originalFile: Nullable.toOption(data.original),
    hotspots: [],
    category: "indoor",
    floor: "ground",
    label: "",
    quality: Nullable.toOption(data.quality),
    colorGroup: Nullable.toOption(data.colorGroup),
    _metadataSource: "default",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
    preCalculatedSnapshot: None,
  }
}

let parseProject = (projectDataJson: JSON.t): state => {
  let pd = switch decodeProject(projectDataJson) {
  | Ok(p) => p
  | Error(_) => {tourName: Nullable.null, scenes: []}
  }
  let tourName = switch Nullable.toOption(pd.tourName) {
  | Some(tn) => tn
  | None => "Imported Tour"
  }

  let scenes = Belt.Array.map(pd.scenes, sc => {
      {
        id: switch Nullable.toOption(sc.id) {
        | Some(id) => id
        | None => "legacy_" ++ sc.name
        },
        name: sc.name,
        file: sc.file,
        tinyFile: Nullable.toOption(sc.tinyFile),
        originalFile: Nullable.toOption(sc.originalFile),
        hotspots: switch Nullable.toOption(sc.hotspots) {
        | Some(hss) => parseHotspots(hss)
        | None => []
        },
        category: switch Nullable.toOption(sc.category) {
        | Some(c) => c
        | None => "indoor"
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
        preCalculatedSnapshot: None,
      }
    })

  {
    ...State.initialState,
    tourName,
    scenes,
    activeIndex: if Array.length(scenes) > 0 {
      0
    } else {
      -1
    },
  }
}

let parseTimelineItem = (json: JSON.t): timelineItem => {
  let item = switch decodeTimelineItem(json) {
  | Ok(i) => i
  | Error(_) => 
      {
        id: "",
        linkId: "",
        sceneId: "",
        targetScene: "",
        transition: "fade",
        duration: 1000,
      }
  }
  {
    id: item.id,
    linkId: item.linkId,
    sceneId: item.sceneId,
    targetScene: item.targetScene,
    transition: item.transition,
    duration: item.duration,
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

    {
      ...state,
      scenes: syncSceneNames(cleanupScenes),
      deletedSceneIds: newDeletedIds,
      activeIndex: newActiveIndex,
    }

  | None => state
  }
}

let handleAddScenes = (state: state, scenesData: array<JSON.t>): state => {
  let newScenes = Belt.Array.reduce(scenesData, state.scenes, (acc, dataJson) => {
    let id = switch decodeImportScene(dataJson) {
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

  let sortedScenes = Js.Array.sortInPlaceWith((a, b) => {
    Float.toInt(String.localeCompare(a.name, b.name))
  }, Array.copy(newScenes))

  let finalScenes = syncSceneNames(sortedScenes)

  let activeIndex = if (
    (state.activeIndex == -1 || state.activeIndex >= Belt.Array.length(finalScenes)) &&
      Belt.Array.length(finalScenes) > 0
  ) {
    0
  } else {
    state.activeIndex
  }

  {...state, scenes: finalScenes, activeIndex}
}

let handleUpdateSceneMetadata = (state: state, index: int, metaJson: JSON.t): state => {
  let scenes = state.scenes
  let metaObj = castToUpdateMetadata(metaJson)

  let newScenes = Belt.Array.mapWithIndex(scenes, (i, s) => {
    if i == index {
      let newCategory = switch Nullable.toOption(metaObj.category) {
      | Some(c) => c
      | None => s.category
      }
      let newFloor = switch Nullable.toOption(metaObj.floor) {
      | Some(f) => f
      | None => s.floor
      }
      {...s, category: newCategory, floor: newFloor}
    } else {
      s
    }
  })
  {...state, scenes: newScenes}
}

let handleUpdateTimelineStep = (state: state, id: string, dataJson: JSON.t): state => {
  let data = castToTimelineUpdate(dataJson)
  let newTimeline = Belt.Array.map(state.timeline, t => {
    if t.id == id {
      {
        ...t,
        transition: switch Nullable.toOption(data.transition) {
        | Some(tr) => tr
        | None => t.transition
        },
        duration: switch Nullable.toOption(data.duration) {
        | Some(d) => d
        | None => t.duration
        },
      }
    } else {
      t
    }
  })
  {...state, timeline: newTimeline}
}
