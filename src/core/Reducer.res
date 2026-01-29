/* src/core/Reducer.res - Consolidated Reducers */

open Types
open Actions

module Scene = {
  let handleAddScenes = (state: state, scenesData): state => {
    SceneHelpers.handleAddScenes(state, scenesData)
  }

  let handleDeleteScene = (state: state, index: int): state => {
    SceneHelpers.handleDeleteScene(state, index)
  }

  let handleReorderScenes = (state: state, fromIndex: int, toIndex: int): state => {
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

        {...state, scenes: SceneHelpers.syncSceneNames(newScenes), activeIndex: newActiveIndex}
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
    transition: option<transition>,
  ): state => {
    if index >= 0 && index < Belt.Array.length(state.scenes) {
      let newTransition = switch transition {
      | Some(t) => t
      | None => {type_: Fade, targetHotspotIndex: -1, fromSceneName: None}
      }

      let newScenes = state.scenes->Belt.Array.mapWithIndex((i, s) => {
        if i == index && !s.categorySet {
          {...s, category: state.lastUsedCategory}
        } else {
          s
        }
      })

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

  let handleUpdateSceneMetadata = (state: state, index: int, metaJson): state => {
    SceneHelpers.handleUpdateSceneMetadata(state, index, metaJson)
  }

  let handleSyncSceneNames = (state: state): state => {
    {...state, scenes: SceneHelpers.syncSceneNames(state.scenes)}
  }

  let handleApplyLazyRename = (state: state, index: int, name: string): state => {
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == index {
        {...s, label: name}
      } else {
        s
      }
    })
    {...state, scenes: SceneHelpers.syncSceneNames(newScenes)}
  }

  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | AddScenes(scenesData) => Some(handleAddScenes(state, scenesData))
    | DeleteScene(index) => Some(handleDeleteScene(state, index))
    | ReorderScenes(fromIndex, toIndex) => Some(handleReorderScenes(state, fromIndex, toIndex))
    | SetActiveScene(index, yaw, pitch, transition) =>
      Some(handleSetActiveScene(state, index, yaw, pitch, transition))
    | UpdateSceneMetadata(index, metaJson) =>
      Some(handleUpdateSceneMetadata(state, index, metaJson))
    | SyncSceneNames => Some(handleSyncSceneNames(state))
    | ApplyLazyRename(index, name) => Some(handleApplyLazyRename(state, index, name))
    | _ => None
    }
  }
}

module Hotspot = {
  let calculateNewReturnViewFrame = (hotspot: hotspot, isReturnLink: bool): option<viewFrame> => {
    if isReturnLink && hotspot.returnViewFrame == None {
      let vf = switch hotspot.viewFrame {
      | Some(v) => v
      | None => {yaw: 0.0, pitch: 0.0, hfov: 90.0}
      }
      Some({
        yaw: vf.yaw,
        pitch: vf.pitch,
        hfov: vf.hfov,
      })
    } else {
      hotspot.returnViewFrame
    }
  }

  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | AddHotspot(sceneIndex, hotspot) =>
      let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
        if i == sceneIndex {
          {...s, hotspots: Belt.Array.concat(s.hotspots, [hotspot])}
        } else {
          s
        }
      })
      Some({...state, scenes: newScenes})

    | RemoveHotspot(sceneIndex, hotspotIndex) =>
      Some(SceneHelpers.handleRemoveHotspot(state, sceneIndex, hotspotIndex))

    | ClearHotspots(index) =>
      let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
        if i == index {
          {...s, hotspots: []}
        } else {
          s
        }
      })
      Some({...state, scenes: newScenes})

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
      Some({...state, scenes: newScenes})

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
      Some({...state, scenes: newScenes})

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
              let newReturnViewFrame = calculateNewReturnViewFrame(h, nextVal)
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
      Some({...state, scenes: newScenes})

    | _ => None
    }
  }
}

module Ui = {
  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | SetPreloadingScene(idx) => Some({...state, preloadingSceneIndex: idx})
    | StartLinking(draft) => Some({...state, isLinking: true, linkDraft: draft})
    | StartAutoPilot(_) => Some({...state, isLinking: false, linkDraft: None})
    | StopLinking => Some({...state, isLinking: false, linkDraft: None})
    | UpdateLinkDraft(draft) => Some({...state, linkDraft: Some(draft)})
    | SetIsTeasing(val) => Some({...state, isTeasing: val})
    | _ => None
    }
  }
}

module Navigation = {
  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | SetSimulationMode(_val) =>
      Some({
        ...state,
        autoForwardChain: [],
        incomingLink: None,
        currentJourneyId: state.currentJourneyId + 1,
        navigation: Idle,
      })
    | SetNavigationStatus(status) => Some({...state, navigation: status})
    | SetIncomingLink(link) => Some({...state, incomingLink: link})
    | ResetAutoForwardChain => Some({...state, autoForwardChain: []})
    | AddToAutoForwardChain(idx) =>
      let chain = state.autoForwardChain
      if !Array.includes(chain, idx) {
        Some({...state, autoForwardChain: Belt.Array.concat(chain, [idx])})
      } else {
        Some(state)
      }
    | SetPendingReturnSceneName(name) => Some({...state, pendingReturnSceneName: name})
    | IncrementJourneyId => Some({...state, currentJourneyId: state.currentJourneyId + 1})
    | SetCurrentJourneyId(id) => Some({...state, currentJourneyId: id})
    | NavigationCompleted(journey) =>
      if journey.journeyId == state.currentJourneyId {
        if journey.previewOnly {
          Some({...state, navigation: Idle})
        } else {
          let incomingLinkVal: linkInfo = {
            sceneIndex: journey.sourceIndex,
            hotspotIndex: journey.hotspotIndex,
          }

          let transition = {
            type_: Link,
            targetHotspotIndex: -1,
            fromSceneName: None,
          }
          Some({
            ...state,
            navigation: Idle,
            incomingLink: Some(incomingLinkVal),
            activeIndex: journey.targetIndex,
            activeYaw: journey.arrivalYaw,
            activePitch: journey.arrivalPitch,
            transition,
          })
        }
      } else {
        Some(state)
      }
    | SetNavigationFsmState(fsmState) => Some({...state, navigationFsm: fsmState})
    | DispatchNavigationFsmEvent(event) =>
      let nextFsmState = NavigationFSM.reducer(state.navigationFsm, event)
      if nextFsmState != state.navigationFsm {
        Some({...state, navigationFsm: nextFsmState})
      } else {
        Some(state)
      }
    | _ => None
    }
  }
}

module Simulation = {
  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | StartAutoPilot(journeyId, skip) =>
      Some({
        ...state,
        simulation: {
          ...state.simulation,
          status: Running,
          autoPilotJourneyId: journeyId,
          visitedScenes: [],
          skipAutoForwardGlobal: skip,
          stoppingOnArrival: false,
        },
      })
    | StartLinking(_) =>
      Some({
        ...state,
        navigation: Idle,
        simulation: {
          ...state.simulation,
          status: Idle,
          pendingAdvanceId: None,
          visitedScenes: [],
          stoppingOnArrival: false,
          skipAutoForwardGlobal: false,
        },
      })
    | StopAutoPilot =>
      Some({
        ...state,
        navigation: Idle,
        currentJourneyId: state.currentJourneyId + 1,
        simulation: {
          ...state.simulation,
          status: Idle,
          pendingAdvanceId: None,
          visitedScenes: [],
          stoppingOnArrival: false,
          skipAutoForwardGlobal: false,
        },
      })
    | AddVisitedScene(sceneIdx) =>
      Some({
        ...state,
        simulation: {
          ...state.simulation,
          visitedScenes: Belt.Array.concat(state.simulation.visitedScenes, [sceneIdx]),
        },
      })
    | ClearVisitedScenes =>
      Some({
        ...state,
        simulation: {
          ...state.simulation,
          visitedScenes: [],
        },
      })
    | SetStoppingOnArrival(value) =>
      Some({
        ...state,
        simulation: {
          ...state.simulation,
          stoppingOnArrival: value,
        },
      })
    | SetSkipAutoForward(value) =>
      Some({
        ...state,
        simulation: {
          ...state.simulation,
          skipAutoForwardGlobal: value,
        },
      })
    | UpdateAdvanceTime(time) =>
      Some({
        ...state,
        simulation: {
          ...state.simulation,
          lastAdvanceTime: time,
        },
      })
    | SetPendingAdvance(id) =>
      Some({
        ...state,
        simulation: {
          ...state.simulation,
          pendingAdvanceId: id,
        },
      })
    | _ => None
    }
  }
}

module Timeline = {
  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | AddToTimeline(json) =>
      let item = SimHelpers.parseTimelineItem(json)
      Some({...state, timeline: Belt.Array.concat(state.timeline, [item])})

    | SetActiveTimelineStep(idOpt) => Some({...state, activeTimelineStepId: idOpt})

    | RemoveFromTimeline(id) =>
      Some({...state, timeline: Belt.Array.keep(state.timeline, t => t.id != id)})

    | ReorderTimeline(fromIdx, toIdx) =>
      if fromIdx != toIdx {
        let itemOpt = Belt.Array.get(state.timeline, fromIdx)
        switch itemOpt {
        | Some(item) =>
          let rest = Belt.Array.keepWithIndex(state.timeline, (_, i) => i != fromIdx)
          let newTimeline = UiHelpers.insertAt(rest, toIdx, item)
          Some({...state, timeline: newTimeline})
        | None => Some(state)
        }
      } else {
        Some(state)
      }

    | UpdateTimelineStep(id, dataJson) =>
      Some(SimHelpers.handleUpdateTimelineStep(state, id, dataJson))

    | _ => None
    }
  }
}

module Project = {
  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | SetTourName(name) => Some({...state, tourName: TourLogic.sanitizeName(name)})

    | LoadProject(projectDataJson) =>
      Some({...SceneHelpers.parseProject(projectDataJson), sessionId: state.sessionId})

    | Reset => Some(State.initialState)

    | SetExifReport(report) => Some({...state, exifReport: Some(report)})

    | RemoveDeletedSceneId(id) =>
      Some({
        ...state,
        deletedSceneIds: Belt.Array.keep(state.deletedSceneIds, i => i != id),
      })

    | SetSessionId(id) => Some({...state, sessionId: Some(id)})
    | _ => None
    }
  }
}

let apply = (state: state, action: action, reducerFn: (state, action) => option<state>): state => {
  switch reducerFn(state, action) {
  | Some(newState) => newState
  | None => state
  }
}

// --- COMPATIBILITY ALIASES ---
module Mod = {
  module Scene = Scene
  module Hotspot = Hotspot
  module Ui = Ui
  module Navigation = Navigation
  module Simulation = Simulation
  module Timeline = Timeline
  module Project = Project
}

let reducer = (state: state, action: action): state => {
  state
  ->apply(action, Scene.reduce)
  ->apply(action, Hotspot.reduce)
  ->apply(action, Ui.reduce)
  ->apply(action, Navigation.reduce)
  ->apply(action, Simulation.reduce)
  ->apply(action, Timeline.reduce)
  ->apply(action, Project.reduce)
}
