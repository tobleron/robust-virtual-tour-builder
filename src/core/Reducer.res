open Types
open Actions

// Helper for array insertion
let insertAt = (arr, index, item) => {
  let before = Belt.Array.slice(arr, ~offset=0, ~len=index)
  let after = Belt.Array.slice(arr, ~offset=index, ~len=Belt.Array.length(arr) - index)
  Belt.Array.concatMany([before, [item], after])
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

  | AddScenes(scenesData) => ReducerHelpers.handleAddScenes(state, scenesData)

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

        {...state, scenes: ReducerHelpers.syncSceneNames(newScenes), activeIndex: newActiveIndex}
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

  | DeleteScene(index) => ReducerHelpers.handleDeleteScene(state, index)

  | LoadProject(projectDataJson) => ReducerHelpers.parseProject(projectDataJson)

  | UpdateSceneMetadata(index, metaJson) => ReducerHelpers.handleUpdateSceneMetadata(state, index, metaJson)

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

  | SyncSceneNames => {...state, scenes: ReducerHelpers.syncSceneNames(state.scenes)}

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
    {...state, scenes: ReducerHelpers.syncSceneNames(newScenes)}

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
    let item = ReducerHelpers.parseTimelineItem(json)
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
