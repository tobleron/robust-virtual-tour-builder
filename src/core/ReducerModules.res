/* src/core/ReducerModules.res - Reducer Sub-modules */

open Types
open Actions

module Helpers = {
  let updateInteractive = (state: state, updater: interactiveState => interactiveState): state => {
    switch state.appMode {
    | Interactive(s) => {...state, appMode: Interactive(updater(s))}
    | _ => state
    }
  }

  let updateUiMode = (state: state, mode: uiMode): state => {
    updateInteractive(state, s => {...s, uiMode: mode})
  }

  let updateNavigation = (state: state, nav: NavigationFSM.distinctState): state => {
    updateInteractive(state, s => {...s, navigation: nav})
  }

  let updateBackgroundTask = (state: state, task: option<backgroundTask>): state => {
    updateInteractive(state, s => {...s, backgroundTask: task})
  }
}

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
    | DispatchAppFsmEvent(event) => {
        Logger.info(
          ~module_="ReducerAppFsm",
          ~message="Processing Event: " ++
          AppFSM.eventToString(event) ++
          " in Mode: " ++
          AppFSM.toString(state.appMode),
          (),
        )
        let nextAppMode = AppFSM.transition(state.appMode, event)
        let nextState = {...state, appMode: nextAppMode}

        // Unify navigation state: sync internal FSM state to navigationState for components that depend on it
        switch nextAppMode {
        | Interactive(s) =>
          Some({
            ...nextState,
            navigationState: {...state.navigationState, navigationFsm: s.navigation},
          })
        | _ => Some(nextState)
        }
      }
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
