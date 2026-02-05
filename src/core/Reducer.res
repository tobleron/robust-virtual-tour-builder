/* src/core/Reducer.res - Consolidated Reducers */

open Types
open Actions

module Scene = {
  let handleAddScenes = (state: state, scenesData): state => {
    SceneMutations.handleAddScenes(state, scenesData)
  }

  let handleDeleteScene = (state: state, index: int): state => {
    SceneMutations.handleDeleteScene(state, index)
  }

  let handleReorderScenes = (state: state, fromIndex: int, toIndex: int): state => {
    SceneMutations.handleReorderScenes(state, fromIndex, toIndex)
  }

  let handleSetActiveScene = (
    state: state,
    index: int,
    yaw: float,
    pitch: float,
    transition: option<transition>,
  ): state => {
    SceneMutations.handleSetActiveScene(state, index, yaw, pitch, transition)
  }

  let handleUpdateSceneMetadata = (state: state, index: int, metaJson): state => {
    SceneMutations.handleUpdateSceneMetadata(state, index, metaJson)
  }

  let handleSyncSceneNames = (state: state): state => {
    {...state, scenes: SceneMutations.syncSceneNames(state.scenes)}
  }

  let handleApplyLazyRename = (state: state, index: int, name: string): state => {
    SceneMutations.handleApplyLazyRename(state, index, name)
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
  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | AddHotspot(sceneIndex, hotspot) =>
      Some(HotspotHelpers.handleAddHotspot(state, sceneIndex, hotspot))

    | RemoveHotspot(sceneIndex, hotspotIndex) =>
      Some(HotspotHelpers.handleRemoveHotspot(state, sceneIndex, hotspotIndex))

    | ClearHotspots(index) => Some(HotspotHelpers.handleClearHotspots(state, index))

    | UpdateHotspotTargetView(sceneIndex, hotspotIndex, yaw, pitch, hfov) =>
      Some(
        HotspotHelpers.handleUpdateHotspotTargetView(
          state,
          sceneIndex,
          hotspotIndex,
          yaw,
          pitch,
          hfov,
        ),
      )

    | UpdateHotspotReturnView(sceneIndex, hotspotIndex, yaw, pitch, hfov) =>
      Some(
        HotspotHelpers.handleUpdateHotspotReturnView(
          state,
          sceneIndex,
          hotspotIndex,
          yaw,
          pitch,
          hfov,
        ),
      )

    | ToggleHotspotReturnLink(sceneIndex, hotspotIndex) =>
      Some(HotspotHelpers.handleToggleHotspotReturnLink(state, sceneIndex, hotspotIndex))

    | _ => None
    }
  }
}

module Ui = {
  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | SetPreloadingScene(idx) => Some({...state, preloadingSceneIndex: idx})
    | StartLinking(draft) =>
      Some({
        ...state,
        isLinking: true,
        linkDraft: draft,
        appMode: AppFSM.transition(state.appMode, StartAuthoring),
      })
    | StartAutoPilot(_) =>
      Some({
        ...state,
        isLinking: false,
        linkDraft: None,
        // Simulation handles its own appMode transition via handleStartAutoPilot
      })
    | StopLinking =>
      Some({
        ...state,
        isLinking: false,
        linkDraft: None,
        appMode: AppFSM.transition(state.appMode, StopAuthoring),
      })
    | UpdateLinkDraft(draft) => Some({...state, linkDraft: Some(draft)})
    | SetIsTeasing(val) =>
      Some({
        ...state,
        isTeasing: val,
        appMode: AppFSM.transition(state.appMode, val ? StartTeasing : StopTeasing),
      })
    | _ => None
    }
  }
}

module AppFsm = {
  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | DispatchAppFsmEvent(event) =>
      Some({...state, appMode: AppFSM.transition(state.appMode, event)})
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
    | SetNavigationStatus(status) =>
      Some({
        ...state,
        navigation: status,
        appMode: switch state.appMode {
        | InteractiveTouring(_) => InteractiveTouring(status)
        | _ => state.appMode
        },
      })
    | SetIncomingLink(link) => Some({...state, incomingLink: link})
    | ResetAutoForwardChain => Some({...state, autoForwardChain: []})
    | AddToAutoForwardChain(idx) => Some(NavigationHelpers.handleAddToAutoForwardChain(state, idx))
    | SetPendingReturnSceneName(name) => Some({...state, pendingReturnSceneName: name})
    | IncrementJourneyId => Some({...state, currentJourneyId: state.currentJourneyId + 1})
    | SetCurrentJourneyId(id) => Some({...state, currentJourneyId: id})
    | NavigationCompleted(journey) =>
      Some(NavigationHelpers.handleNavigationCompleted(state, journey))
    | SetNavigationFsmState(fsmState) => Some({...state, navigationFsm: fsmState})
    | DispatchNavigationFsmEvent(event) =>
      Some(NavigationHelpers.handleDispatchNavigationFsmEvent(state, event))
    | _ => None
    }
  }
}

module Simulation = {
  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | StartAutoPilot(journeyId, skip) =>
      Some(SimulationHelpers.handleStartAutoPilot(state, journeyId, skip))
    | StartLinking(draft) => Some(SimulationHelpers.handleStartLinking(state, draft))
    | StopAutoPilot => Some(SimulationHelpers.handleStopAutoPilot(state))
    | AddVisitedScene(sceneIdx) => Some(SimulationHelpers.handleAddVisitedScene(state, sceneIdx))
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
      switch SceneHelpers.parseProject(projectDataJson) {
      | Ok(pd) =>
        Some({
          ...state,
          tourName: pd.tourName,
          scenes: pd.scenes,
          lastUsedCategory: pd.lastUsedCategory,
          exifReport: pd.exifReport,
          sessionId: switch pd.sessionId {
          | Some(id) => Some(id)
          | None => state.sessionId
          },
          deletedSceneIds: pd.deletedSceneIds,
          timeline: pd.timeline,
          activeIndex: if Belt.Array.length(pd.scenes) > 0 {
            0
          } else {
            -1
          },
          // Important: Reset views when loading new project
          activeYaw: 0.0,
          activePitch: 0.0,
          navigation: Idle,
          simulation: State.initialState.simulation,
          isTeasing: false,
          isLinking: false,
          linkDraft: None,
        })
      | Error(_) => Some(state)
      }

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
  ->apply(action, AppFsm.reduce)
  ->apply(action, Scene.reduce)
  ->apply(action, Hotspot.reduce)
  ->apply(action, Ui.reduce)
  ->apply(action, Navigation.reduce)
  ->apply(action, Simulation.reduce)
  ->apply(action, Timeline.reduce)
  ->apply(action, Project.reduce)
}
