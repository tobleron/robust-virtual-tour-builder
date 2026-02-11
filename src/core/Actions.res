// @efficiency-role: data-model
open Types

type rec action =
  | SetPreloadingScene(int)
  | StartLinking(option<linkDraft>)
  | StopLinking
  | UpdateLinkDraft(linkDraft)
  | SetIsTeasing(bool)
  | SetTourName(string)
  | AddScenes(array<JSON.t>)
  | SetActiveScene(int, float, float, option<transition>)
  | AddHotspot(int, hotspot)
  | RemoveHotspot(int, int)
  | ReorderScenes(int, int)
  | ClearHotspots(int)
  | DeleteScene(int)
  | RemoveDeletedSceneId(string)
  | SyncSceneNames
  | ApplyLazyRename(int, string)
  | UpdateSceneMetadata(int, JSON.t)
  | UpdateHotspotTargetView(int, int, float, float, float)
  | UpdateHotspotReturnView(int, int, float, float, float)
  | ToggleHotspotReturnLink(int, int)
  | AddToTimeline(JSON.t)
  | SetActiveTimelineStep(option<string>)
  | RemoveFromTimeline(string)
  | ReorderTimeline(int, int)
  | UpdateTimelineStep(string, JSON.t)
  | LoadProject(JSON.t)
  | RestoreState(state)
  | Reset
  | SetSimulationMode(bool)
  | SetNavigationStatus(navigationStatus)
  | SetIncomingLink(option<linkInfo>)
  | ResetAutoForwardChain
  | AddToAutoForwardChain(int)
  | SetPendingReturnSceneName(option<string>)
  | IncrementJourneyId
  | SetCurrentJourneyId(int)
  | NavigationCompleted(journeyData)
  | SetExifReport(JSON.t)
  // Simulation Actions
  | StartAutoPilot(int, bool) // journeyId, skipAutoForward
  | StopAutoPilot
  | AddVisitedScene(int)
  | ClearVisitedScenes
  | SetStoppingOnArrival(bool)
  | SetSkipAutoForward(bool)
  | UpdateAdvanceTime(float)
  | SetPendingAdvance(option<int>)
  | SetSessionId(string)
  | SetNavigationFsmState(NavigationFSM.distinctState)
  | DispatchNavigationFsmEvent(NavigationFSM.event)
  | DispatchAppFsmEvent(AppFSM.event)
  | Batch(array<action>)

let sceneActionToString = (action: action): option<string> =>
  switch action {
  | AddScenes(arr) => Some(`AddScenes(${Belt.Int.toString(Belt.Array.length(arr))})`)
  | SetActiveScene(idx, _, _, _) => Some(`SetActiveScene(${Belt.Int.toString(idx)})`)
  | ReorderScenes(i1, i2) =>
    Some(`ReorderScenes(${Belt.Int.toString(i1)}, ${Belt.Int.toString(i2)})`)
  | DeleteScene(idx) => Some(`DeleteScene(${Belt.Int.toString(idx)})`)
  | RemoveDeletedSceneId(id) => Some(`RemoveDeletedSceneId(${id})`)
  | SyncSceneNames => Some("SyncSceneNames")
  | ApplyLazyRename(idx, name) => Some(`ApplyLazyRename(${Belt.Int.toString(idx)}, ${name})`)
  | UpdateSceneMetadata(idx, _) => Some(`UpdateSceneMetadata(${Belt.Int.toString(idx)})`)
  | _ => None
  }

let hotspotActionToString = (action: action): option<string> =>
  switch action {
  | AddHotspot(idx, _) => Some(`AddHotspot(${Belt.Int.toString(idx)})`)
  | RemoveHotspot(sIdx, hIdx) =>
    Some(`RemoveHotspot(${Belt.Int.toString(sIdx)}, ${Belt.Int.toString(hIdx)})`)
  | ClearHotspots(idx) => Some(`ClearHotspots(${Belt.Int.toString(idx)})`)
  | UpdateHotspotTargetView(sIdx, hIdx, _, _, _) =>
    Some(`UpdateHotspotTargetView(${Belt.Int.toString(sIdx)}, ${Belt.Int.toString(hIdx)})`)
  | UpdateHotspotReturnView(sIdx, hIdx, _, _, _) =>
    Some(`UpdateHotspotReturnView(${Belt.Int.toString(sIdx)}, ${Belt.Int.toString(hIdx)})`)
  | ToggleHotspotReturnLink(sIdx, hIdx) =>
    Some(`ToggleHotspotReturnLink(${Belt.Int.toString(sIdx)}, ${Belt.Int.toString(hIdx)})`)
  | _ => None
  }

let timelineActionToString = (action: action): option<string> =>
  switch action {
  | AddToTimeline(_) => Some("AddToTimeline")
  | SetActiveTimelineStep(opt) => Some(`SetActiveTimelineStep(${opt->Option.getOr("None")})`)
  | RemoveFromTimeline(id) => Some(`RemoveFromTimeline(${id})`)
  | ReorderTimeline(i1, i2) =>
    Some(`ReorderTimeline(${Belt.Int.toString(i1)}, ${Belt.Int.toString(i2)})`)
  | UpdateTimelineStep(id, _) => Some(`UpdateTimelineStep(${id})`)
  | _ => None
  }

let navigationActionToString = (action: action): option<string> =>
  switch action {
  | SetNavigationStatus(_) => Some("SetNavigationStatus")
  | SetIncomingLink(_) => Some("SetIncomingLink")
  | ResetAutoForwardChain => Some("ResetAutoForwardChain")
  | AddToAutoForwardChain(idx) => Some(`AddToAutoForwardChain(${Belt.Int.toString(idx)})`)
  | SetPendingReturnSceneName(opt) =>
    Some(`SetPendingReturnSceneName(${opt->Option.getOr("None")})`)
  | IncrementJourneyId => Some("IncrementJourneyId")
  | SetCurrentJourneyId(id) => Some(`SetCurrentJourneyId(${Belt.Int.toString(id)})`)
  | NavigationCompleted(_) => Some("NavigationCompleted")
  | SetNavigationFsmState(state) => Some(`SetNavigationFsmState(${NavigationFSM.toString(state)})`)
  | DispatchNavigationFsmEvent(_) => Some(`DispatchNavigationFsmEvent`)
  | _ => None
  }

let simulationActionToString = (action: action): option<string> =>
  switch action {
  | SetSimulationMode(b) => Some(`SetSimulationMode(${b ? "true" : "false"})`)
  | StartAutoPilot(_, _) => Some("StartAutoPilot")
  | StopAutoPilot => Some("StopAutoPilot")
  | AddVisitedScene(_) => Some("AddVisitedScene")
  | ClearVisitedScenes => Some("ClearVisitedScenes")
  | SetStoppingOnArrival(_) => Some("SetStoppingOnArrival")
  | SetSkipAutoForward(_) => Some("SetSkipAutoForward")
  | UpdateAdvanceTime(_) => Some("UpdateAdvanceTime")
  | SetPendingAdvance(_) => Some("SetPendingAdvance")
  | _ => None
  }

let uiActionToString = (action: action): option<string> =>
  switch action {
  | SetPreloadingScene(idx) => Some(`SetPreloadingScene(${Belt.Int.toString(idx)})`)
  | StartLinking(_) => Some("StartLinking")
  | StopLinking => Some("StopLinking")
  | UpdateLinkDraft(_) => Some("UpdateLinkDraft")
  | SetIsTeasing(b) => Some(`SetIsTeasing(${b ? "true" : "false"})`)
  | SetTourName(name) => Some(`SetTourName(${name})`)
  | LoadProject(_) => Some("LoadProject")
  | RestoreState(_) => Some("RestoreState")
  | Reset => Some("Reset")
  | SetExifReport(_) => Some("SetExifReport")
  | SetSessionId(id) => Some(`SetSessionId(${id})`)
  | DispatchAppFsmEvent(_) => Some("DispatchAppFsmEvent")
  | _ => None
  }

let rec actionToString = (action: action): string => {
  switch action {
  | Batch(actions) =>
    "Batch([" ++ actions->Belt.Array.map(actionToString)->Belt.Array.joinWith(", ", x => x) ++ "])"
  | _ =>
    switch sceneActionToString(action) {
    | Some(s) => s
    | None =>
      switch hotspotActionToString(action) {
      | Some(s) => s
      | None =>
        switch timelineActionToString(action) {
        | Some(s) => s
        | None =>
          switch navigationActionToString(action) {
          | Some(s) => s
          | None =>
            switch simulationActionToString(action) {
            | Some(s) => s
            | None =>
              switch uiActionToString(action) {
              | Some(s) => s
              | None => "UnknownAction"
              }
            }
          }
        }
      }
    }
  }
}
