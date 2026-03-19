/* src/core/Reducer.res - Consolidated Reducers */

open Types
// open Actions -- Removed to prevent shadowing Reset

// Delegate to sub-modules
module Helpers = ReducerModules.Helpers
module Scene = ReducerModules.Scene
module Hotspot = ReducerModules.Hotspot
module Ui = ReducerModules.Ui
module AppFsm = ReducerModules.AppFsm
module Navigation = NavigationProjectReducer.Navigation
module Simulation = ReducerModules.Simulation
module Timeline = ReducerModules.Timeline
module Project = NavigationProjectReducer.Project

let apply = (
  state: state,
  action: Actions.action,
  reducerFn: (state, Actions.action) => option<state>,
): state => {
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

let isStructuralMutation = (action: Actions.action): bool => {
  switch action {
  | Actions.SetTourName(_)
  | Actions.AddScenes(_)
  | Actions.AddHotspot(_, _)
  | Actions.RemoveHotspot(_, _)
  | Actions.ReorderScenes(_, _)
  | Actions.ClearHotspots(_)
  | Actions.DeleteScene(_)
  | Actions.RemoveDeletedSceneId(_)
  | Actions.SyncSceneNames
  | Actions.ApplyLazyRename(_, _)
  | Actions.UpdateSceneMetadata(_, _)
  | Actions.UpdateHotspotMetadata(_, _, _)
  | Actions.UpdateHotspotTargetView(_, _, _, _, _)
  | Actions.CommitHotspotMove(_, _, _, _)
  | Actions.AddToTimeline(_)
  | Actions.SetTimeline(_)
  | Actions.RemoveFromTimeline(_)
  | Actions.ReorderTimeline(_, _)
  | Actions.UpdateTimelineStep(_, _)
  | Actions.LoadProject(_)
  | Actions.Reset
  | Actions.SetExifReport(_)
  | Actions.SetLogo(_)
  | Actions.SetMarketingSettings(_, _, _, _, _)
  | Actions.PatchSceneThumbnail(_, _) => true
  | _ => false
  }
}

let maxBatchDepth = 3

let applyUiOnly = (state: state, action: Actions.action): state => state->apply(action, Ui.reduce)
let applySceneOnly = (state: state, action: Actions.action): state =>
  state->apply(action, Scene.reduce)
let applyHotspotOnly = (state: state, action: Actions.action): state =>
  state->apply(action, Hotspot.reduce)
let applyNavigationOnly = (state: state, action: Actions.action): state =>
  state->apply(action, Navigation.reduce)
let applySimulationOnly = (state: state, action: Actions.action): state =>
  state->apply(action, Simulation.reduce)
let applyTimelineOnly = (state: state, action: Actions.action): state =>
  state->apply(action, Timeline.reduce)
let applyProjectOnly = (state: state, action: Actions.action): state =>
  state->apply(action, Project.reduce)
let applyAppFsmThenNavigation = (state: state, action: Actions.action): state =>
  state->apply(action, AppFsm.reduce)->apply(action, Navigation.reduce)
let applyUiThenSimulation = (state: state, action: Actions.action): state =>
  state->apply(action, Ui.reduce)->apply(action, Simulation.reduce)
let applyFullPipeline = (state: state, action: Actions.action): state => {
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

let applyRoutedPipeline = (state: state, action: Actions.action): state => {
  switch action {
  | Actions.DispatchAppFsmEvent(_) => applyNavigationOnly(state, action)

  | Actions.AddScenes(_)
  | Actions.SetActiveScene(_, _, _, _)
  | Actions.ReorderScenes(_, _)
  | Actions.DeleteScene(_)
  | Actions.SyncSceneNames
  | Actions.ApplyLazyRename(_, _)
  | Actions.UpdateSceneMetadata(_, _)
  | Actions.PatchSceneThumbnail(_, _) =>
    applySceneOnly(state, action)

  | Actions.AddHotspot(_, _)
  | Actions.RemoveHotspot(_, _)
  | Actions.StartMovingHotspot(_, _)
  | Actions.StopMovingHotspot
  | Actions.CommitHotspotMove(_, _, _, _)
  | Actions.ClearHotspots(_)
  | Actions.UpdateHotspotMetadata(_, _, _)
  | Actions.UpdateHotspotTargetView(_, _, _, _, _) =>
    applyHotspotOnly(state, action)

  | Actions.SetPreloadingScene(_)
  | Actions.StopLinking
  | Actions.UpdateLinkDraft(_)
  | Actions.SetIsTeasing(_)
  | Actions.MarkSceneVisited(_) =>
    applyUiOnly(state, action)

  | Actions.StartLinking(_)
  | Actions.StartAutoPilot(_, _) =>
    applyUiThenSimulation(state, action)

  | Actions.StopAutoPilot
  | Actions.AddVisitedLink(_)
  | Actions.ClearVisitedLinks
  | Actions.SetStoppingOnArrival(_)
  | Actions.SetSkipAutoForward(_)
  | Actions.UpdateAdvanceTime(_)
  | Actions.SetPendingAdvance(_) =>
    applySimulationOnly(state, action)

  | Actions.SetSimulationMode(_)
  | Actions.SetNavigationStatus(_)
  | Actions.SetIncomingLink(_)
  | Actions.ResetAutoForwardChain
  | Actions.AddToAutoForwardChain(_)
  | Actions.IncrementJourneyId
  | Actions.SetCurrentJourneyId(_)
  | Actions.NavigationCompleted(_)
  | Actions.SetNavigationFsmState(_)
  | Actions.DispatchNavigationFsmEvent(_) =>
    applyNavigationOnly(state, action)

  | Actions.AddToTimeline(_)
  | Actions.SetTimeline(_)
  | Actions.SetActiveTimelineStep(_)
  | Actions.RemoveFromTimeline(_)
  | Actions.ReorderTimeline(_, _)
  | Actions.UpdateTimelineStep(_, _)
  | Actions.CleanupTimeline =>
    applyTimelineOnly(state, action)

  | Actions.SetTourName(_)
  | Actions.LoadProject(_)
  | Actions.RemoveDeletedSceneId(_)
  | Actions.SetExifReport(_)
  | Actions.SetSessionId(_)
  | Actions.SetLogo(_)
  | Actions.SetMarketingSettings(_, _, _, _, _)
  | Actions.SetTripodDeadZoneEnabled(_)
  | Actions.Reset =>
    applyProjectOnly(state, action)

  | _ => applyFullPipeline(state, action)
  }
}

let rec reduceWithDepth = (state: state, action: Actions.action, depth: int): state => {
  switch action {
  | Actions.RestoreState(nextState) => nextState
  | Actions.Batch(actions) =>
    if depth >= maxBatchDepth {
      Logger.error(
        ~module_="Reducer",
        ~message="Max batch recursion depth exceeded; dropping nested batch",
        ~data=Logger.castToJson({"depth": depth, "maxDepth": maxBatchDepth}),
        (),
      )
      state
    } else {
      Belt.Array.reduce(actions, state, (s, a) => reduceWithDepth(s, a, depth + 1))
    }
  | _ =>
    let nextState = applyRoutedPipeline(state, action)

    if isStructuralMutation(action) && nextState !== state {
      {...nextState, structuralRevision: nextState.structuralRevision + 1}
    } else {
      nextState
    }
  }
}

let reducer = (state: state, action: Actions.action): state => reduceWithDepth(state, action, 0)
