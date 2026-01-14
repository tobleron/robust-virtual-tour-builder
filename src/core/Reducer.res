open Types
open Actions

// Helper for array insertion
let insertAt = (arr, index, item) => {
  let before = Belt.Array.slice(arr, ~offset=0, ~len=index)
  let after = Belt.Array.slice(arr, ~offset=index, ~len=Belt.Array.length(arr) - index)
  Belt.Array.concatMany([before, [item], after])
}

let parseHotspots = (json: JSON.t): array<hotspot> => {
  if Array.isArray(json) {
    let hss = (Obj.magic(json): array<JSON.t>)
    Belt.Array.map(hss, hJson => {
      let hs = (Obj.magic(hJson): {..})
      {
        linkId: switch Nullable.toOption(hs["linkId"]) {
        | Some(id) => id
        | None => ""
        },
        yaw: hs["yaw"],
        pitch: hs["pitch"],
        target: hs["target"],
        targetYaw: Nullable.toOption(hs["targetYaw"]),
        targetPitch: Nullable.toOption(hs["targetPitch"]),
        targetHfov: Nullable.toOption(hs["targetHfov"]),
        startYaw: Nullable.toOption(hs["startYaw"]),
        startPitch: Nullable.toOption(hs["startPitch"]),
        startHfov: Nullable.toOption(hs["startHfov"]),
        isReturnLink: Nullable.toOption(hs["isReturnLink"]),
        viewFrame: Nullable.toOption(hs["viewFrame"]),
        returnViewFrame: Nullable.toOption(hs["returnViewFrame"]),
        waypoints: Nullable.toOption(hs["waypoints"]),
        displayPitch: Nullable.toOption(hs["displayPitch"]),
        transition: Nullable.toOption(hs["transition"]),
        duration: Nullable.toOption(hs["duration"]),
      }
    })
  } else {
    []
  }
}

let parseProject = (projectDataJson: JSON.t): state => {
  let pd = (Obj.magic(projectDataJson): {..})
  let tourName = switch Nullable.toOption(pd["tourName"]) {
  | Some(tn) => tn
  | None => "Imported Tour"
  }

  let scenesArrJson = (pd["scenes"]: JSON.t)
  let scenes = if Array.isArray(scenesArrJson) {
    let scenesArr = (Obj.magic(scenesArrJson): array<JSON.t>)
    Belt.Array.map(scenesArr, sJson => {
      let sc = (Obj.magic(sJson): {..})
      {
        id: switch Nullable.toOption(sc["id"]) {
        | Some(id) => id
        | None => "legacy_" ++ sc["name"]
        },
        name: sc["name"],
        file: sc["file"],
        tinyFile: Nullable.toOption(sc["tinyFile"]),
        originalFile: Nullable.toOption(sc["originalFile"]),
        hotspots: switch Nullable.toOption(sc["hotspots"]) {
        | Some(hssJson) => parseHotspots(hssJson)
        | None => []
        },
        category: switch Nullable.toOption(sc["category"]) {
        | Some(c) => c
        | None => "indoor"
        },
        floor: switch Nullable.toOption(sc["floor"]) {
        | Some(f) => f
        | None => "ground"
        },
        label: switch Nullable.toOption(sc["label"]) {
        | Some(l) => l
        | None => ""
        },
        quality: Nullable.toOption(sc["quality"]),
        colorGroup: Nullable.toOption(sc["colorGroup"]),
        _metadataSource: switch Nullable.toOption(sc["_metadataSource"]) {
        | Some(m) => m
        | None => "user"
        },
        categorySet: switch Nullable.toOption(sc["categorySet"]) {
        | Some(cs) => cs
        | None => false
        },
        labelSet: switch Nullable.toOption(sc["labelSet"]) {
        | Some(ls) => ls
        | None => false
        },
        isAutoForward: switch Nullable.toOption(sc["isAutoForward"]) {
        | Some(af) => af
        | None => false
        },
        preCalculatedSnapshot: None,
      }
    })
  } else {
    []
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
  }
}

let parseScene = (dataJson: JSON.t): scene => {
  let data = (Obj.magic(dataJson): {..})
  {
    id: data["id"],
    name: data["name"],
    file: data["preview"],
    tinyFile: Nullable.toOption(data["tiny"]),
    originalFile: Nullable.toOption(data["original"]),
    hotspots: [],
    category: "indoor",
    floor: "ground",
    label: "",
    quality: Nullable.toOption(data["quality"]),
    colorGroup: Nullable.toOption(data["colorGroup"]),
    _metadataSource: "default",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
    preCalculatedSnapshot: None,
  }
}

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

let parseTimelineItem = (json: JSON.t): timelineItem => {
  let item = (Obj.magic(json): {..})
  {
    id: item["id"],
    linkId: item["linkId"],
    sceneId: item["sceneId"],
    targetScene: item["targetScene"],
    transition: item["transition"],
    duration: item["duration"],
  }
}

let reducer = (state: state, action: action): state => {
  switch action {
  | SetPreloadingScene(index) => {...state, preloadingSceneIndex: index}
  | SetLinkDraft(draft) => {...state, linkDraft: draft}
  | SetIsLinking(val) => {...state, isLinking: val}
  | SetIsTeasing(val) => {...state, isTeasing: val}
  | SetTourName(name) =>
    let sanitized = TourLogic.sanitizeName(name, ~maxLength=100)
    {...state, tourName: sanitized}

  | AddScenes(scenesData) =>
    let newScenes = Belt.Array.reduce(scenesData, state.scenes, (acc, dataJson) => {
      let data = (Obj.magic(dataJson): {..})
      let id = data["id"]
      if Belt.Array.some(acc, s => s.id == id) {
        acc
      } else {
        let newScene = parseScene(dataJson)
        Belt.Array.concat(acc, [newScene])
      }
    })

    let sortedScenes = Js.Array.sortInPlaceWith((a, b) => {
      Float.toInt(String.localeCompare(a.name, b.name))
    }, Array.copy(newScenes)) // Copy to avoid mutation of input if any

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

  | SetActiveScene(index, yaw, pitch, transition) =>
    if index >= 0 && index < Belt.Array.length(state.scenes) {
      let newTransition = switch transition {
      | Some(t) => t
      | None => {type_: None, targetHotspotIndex: -1, fromSceneName: None}
      }
      {...state, activeIndex: index, activeYaw: yaw, activePitch: pitch, transition: newTransition}
    } else {
      state
    }

  | ReorderScenes(fromIndex, toIndex) =>
    if fromIndex != toIndex {
      let scenes = state.scenes
      switch Belt.Array.get(scenes, fromIndex) {
      | Some(movedItem) =>
        let rest = Belt.Array.keepWithIndex(scenes, (_, i) => i != fromIndex)
        let newScenes = insertAt(rest, toIndex, movedItem)

        let newActiveIndex = if state.activeIndex == fromIndex {
          toIndex
        } else if state.activeIndex > fromIndex && state.activeIndex <= toIndex {
          state.activeIndex - 1
        } else if state.activeIndex < fromIndex && state.activeIndex >= toIndex {
          state.activeIndex + 1
        } else {
          state.activeIndex
        }

        // Sync names after reorder since names depend on index if labels are used
        {...state, scenes: syncSceneNames(newScenes), activeIndex: newActiveIndex}
      | None => state
      }
    } else {
      state
    }

  | ClearHotspots(index) =>
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == index {
        {...s, hotspots: []}
      } else {
        s
      }
    })
    {...state, scenes: newScenes}

  | DeleteScene(index) =>
    // Basic implementation
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

  | LoadProject(projectDataJson) => parseProject(projectDataJson)

  | UpdateSceneMetadata(index, metaJson) =>
    let scenes = state.scenes
    let metaObj: {..} = Obj.magic(metaJson)

    let newScenes = Belt.Array.mapWithIndex(scenes, (i, s) => {
      if i == index {
        let newCategory = switch Nullable.toOption(metaObj["category"]) {
        | Some(c) => (Obj.magic(c): string)
        | None => s.category
        }
        let newFloor = switch Nullable.toOption(metaObj["floor"]) {
        | Some(f) => (Obj.magic(f): string)
        | None => s.floor
        }
        {...s, category: newCategory, floor: newFloor}
      } else {
        s
      }
    })
    {...state, scenes: newScenes}

  | Reset => State.initialState

  | SetSimulationMode(val) => {
      ...state,
      isSimulationMode: val,
      autoForwardChain: [],
      incomingLink: None,
      currentJourneyId: state.currentJourneyId + 1,
      navigation: Idle,
    }
  | SetNavigationStatus(status) => {...state, navigation: status}
  | SetIncomingLink(link) => {...state, incomingLink: link}
  | ResetAutoForwardChain => {...state, autoForwardChain: []}
  | AddToAutoForwardChain(idx) => {
      let chain = state.autoForwardChain
      if !Js.Array.includes(idx, chain) {
        {...state, autoForwardChain: Belt.Array.concat(chain, [idx])}
      } else {
        state
      }
    }
  | SetPendingReturnSceneName(name) => {...state, pendingReturnSceneName: name}
  | IncrementJourneyId => {...state, currentJourneyId: state.currentJourneyId + 1}
  | SetCurrentJourneyId(id) => {...state, currentJourneyId: id}
  | NavigationCompleted(journey) => if journey.journeyId == state.currentJourneyId {
      if journey.previewOnly {
        {...state, navigation: Idle}
      } else {
        let incomingLink = Some({
          sceneIndex: journey.sourceIndex,
          hotspotIndex: journey.hotspotIndex,
        })
        let transition = {
          type_: Some("link"),
          targetHotspotIndex: -1,
          fromSceneName: None,
        }
        {
          ...state,
          navigation: Idle,
          incomingLink,
          activeIndex: journey.targetIndex,
          activeYaw: journey.arrivalYaw,
          activePitch: journey.arrivalPitch,
          transition,
        }
      }
    } else {
      state
    }

  | SyncSceneNames => {...state, scenes: syncSceneNames(state.scenes)}

  | AddHotspot(sceneIndex, hotspot) =>
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == sceneIndex {
        {...s, hotspots: Belt.Array.concat(s.hotspots, [hotspot])}
      } else {
        s
      }
    })
    {...state, scenes: newScenes}

  | RemoveHotspot(sceneIndex, hotspotIndex) =>
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == sceneIndex {
        let newHotspots = Belt.Array.keepWithIndex(s.hotspots, (_, hi) => hi != hotspotIndex)
        {...s, hotspots: newHotspots}
      } else {
        s
      }
    })
    {...state, scenes: newScenes}

  | RemoveDeletedSceneId(id) => {
      ...state,
      deletedSceneIds: Belt.Array.keep(state.deletedSceneIds, i => i != id),
    }

  | ApplyLazyRename(index, name) =>
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == index {
        {...s, label: name}
      } else {
        s
      }
    })
    {...state, scenes: syncSceneNames(newScenes)}

  | UpdateHotspotTargetView(sceneIndex, hotspotIndex, yaw, pitch, hfov) =>
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == sceneIndex {
        let newHotspots = Belt.Array.mapWithIndex(s.hotspots, (hi, h) => {
          if hi == hotspotIndex {
            {...h, targetYaw: Some(yaw), targetPitch: Some(pitch), targetHfov: Some(hfov)}
          } else {
            h
          }
        })
        {...s, hotspots: newHotspots}
      } else {
        s
      }
    })
    {...state, scenes: newScenes}

  | UpdateHotspotReturnView(sceneIndex, hotspotIndex, yaw, pitch, hfov) =>
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == sceneIndex {
        let newHotspots = Belt.Array.mapWithIndex(s.hotspots, (hi, h) => {
          if hi == hotspotIndex {
            let vf: viewFrame = {yaw, pitch, hfov}
            {...h, returnViewFrame: Some(vf), isReturnLink: Some(true)}
          } else {
            h
          }
        })
        {...s, hotspots: newHotspots}
      } else {
        s
      }
    })
    {...state, scenes: newScenes}

  | ToggleHotspotReturnLink(sceneIndex, hotspotIndex) =>
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == sceneIndex {
        let newHotspots = Belt.Array.mapWithIndex(s.hotspots, (hi, h) => {
          if hi == hotspotIndex {
            let currentVal = switch h.isReturnLink {
            | Some(b) => b
            | None => false
            }
            let nextVal = !currentVal
            let newReturnViewFrame = if nextVal && h.returnViewFrame == None {
              let vf = switch h.viewFrame {
              | Some(v) => v
              | None => {yaw: 0.0, pitch: 0.0, hfov: 90.0}
              }
              Some({
                yaw: vf.yaw,
                pitch: vf.pitch,
                hfov: vf.hfov,
              })
            } else {
              h.returnViewFrame
            }
            {...h, isReturnLink: Some(nextVal), returnViewFrame: newReturnViewFrame}
          } else {
            h
          }
        })
        {...s, hotspots: newHotspots}
      } else {
        s
      }
    })
    {...state, scenes: newScenes}

  | AddToTimeline(json) =>
    let item = parseTimelineItem(json)
    {...state, timeline: Belt.Array.concat(state.timeline, [item])}

  | SetActiveTimelineStep(idOpt) => {...state, activeTimelineStepId: idOpt}

  | RemoveFromTimeline(id) => {...state, timeline: Belt.Array.keep(state.timeline, t => t.id != id)}

  | ReorderTimeline(fromIdx, toIdx) =>
    if fromIdx != toIdx {
      let itemOpt = Belt.Array.get(state.timeline, fromIdx)
      switch itemOpt {
      | Some(item) =>
        let rest = Belt.Array.keepWithIndex(state.timeline, (_, i) => i != fromIdx)
        let newTimeline = insertAt(rest, toIdx, item)
        {...state, timeline: newTimeline}
      | None => state
      }
    } else {
      state
    }

  | UpdateTimelineStep(id, dataJson) =>
    let data = (Obj.magic(dataJson): {..})
    let newTimeline = Belt.Array.map(state.timeline, t => {
      if t.id == id {
        {
          ...t,
          transition: if Nullable.isNullable(data["transition"]) {
            t.transition
          } else {
            data["transition"]
          },
          duration: if Nullable.isNullable(data["duration"]) {
            t.duration
          } else {
            data["duration"]
          },
        }
      } else {
        t
      }
    })
    {...state, timeline: newTimeline}

  | SetExifReport(report) => {...state, exifReport: Some(report)}
  }
}
