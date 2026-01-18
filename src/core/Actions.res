open Types

type action =
  | SetPreloadingScene(int)
  | StartLinking(linkDraft)
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

let actionToString = (action: action): string =>
  switch action {
  | SetPreloadingScene(idx) => `SetPreloadingScene(${Belt.Int.toString(idx)})`
  | StartLinking(_) => "StartLinking"
  | StopLinking => "StopLinking"
  | UpdateLinkDraft(_) => "UpdateLinkDraft"
  | SetIsTeasing(b) => `SetIsTeasing(${b ? "true" : "false"})`
  | SetTourName(name) => `SetTourName(${name})`
  | AddScenes(arr) => `AddScenes(${Belt.Int.toString(Belt.Array.length(arr))})`
  | SetActiveScene(idx, _, _, _) => `SetActiveScene(${Belt.Int.toString(idx)})`
  | AddHotspot(idx, _) => `AddHotspot(${Belt.Int.toString(idx)})`
  | RemoveHotspot(sIdx, hIdx) =>
    `RemoveHotspot(${Belt.Int.toString(sIdx)}, ${Belt.Int.toString(hIdx)})`
  | ReorderScenes(i1, i2) => `ReorderScenes(${Belt.Int.toString(i1)}, ${Belt.Int.toString(i2)})`
  | ClearHotspots(idx) => `ClearHotspots(${Belt.Int.toString(idx)})`
  | DeleteScene(idx) => `DeleteScene(${Belt.Int.toString(idx)})`
  | RemoveDeletedSceneId(id) => `RemoveDeletedSceneId(${id})`
  | SyncSceneNames => "SyncSceneNames"
  | ApplyLazyRename(idx, name) => `ApplyLazyRename(${Belt.Int.toString(idx)}, ${name})`
  | UpdateSceneMetadata(idx, _) => `UpdateSceneMetadata(${Belt.Int.toString(idx)})`
  | UpdateHotspotTargetView(sIdx, hIdx, _, _, _) =>
    `UpdateHotspotTargetView(${Belt.Int.toString(sIdx)}, ${Belt.Int.toString(hIdx)})`
  | UpdateHotspotReturnView(sIdx, hIdx, _, _, _) =>
    `UpdateHotspotReturnView(${Belt.Int.toString(sIdx)}, ${Belt.Int.toString(hIdx)})`
  | ToggleHotspotReturnLink(sIdx, hIdx) =>
    `ToggleHotspotReturnLink(${Belt.Int.toString(sIdx)}, ${Belt.Int.toString(hIdx)})`
  | AddToTimeline(_) => "AddToTimeline"
  | SetActiveTimelineStep(opt) => `SetActiveTimelineStep(${opt->Option.getOr("None")})`
  | RemoveFromTimeline(id) => `RemoveFromTimeline(${id})`
  | ReorderTimeline(i1, i2) => `ReorderTimeline(${Belt.Int.toString(i1)}, ${Belt.Int.toString(i2)})`
  | UpdateTimelineStep(id, _) => `UpdateTimelineStep(${id})`
  | LoadProject(_) => "LoadProject"
  | Reset => "Reset"
  | SetSimulationMode(b) => `SetSimulationMode(${b ? "true" : "false"})`
  | SetNavigationStatus(_) => "SetNavigationStatus"
  | SetIncomingLink(_) => "SetIncomingLink"
  | ResetAutoForwardChain => "ResetAutoForwardChain"
  | AddToAutoForwardChain(idx) => `AddToAutoForwardChain(${Belt.Int.toString(idx)})`
  | SetPendingReturnSceneName(opt) => `SetPendingReturnSceneName(${opt->Option.getOr("None")})`
  | IncrementJourneyId => "IncrementJourneyId"
  | SetCurrentJourneyId(id) => `SetCurrentJourneyId(${Belt.Int.toString(id)})`
  | NavigationCompleted(_) => "NavigationCompleted"
  | SetExifReport(_) => "SetExifReport"
  | StartAutoPilot(_, _) => "StartAutoPilot"
  | StopAutoPilot => "StopAutoPilot"
  | AddVisitedScene(_) => "AddVisitedScene"
  | ClearVisitedScenes => "ClearVisitedScenes"
  | SetStoppingOnArrival(_) => "SetStoppingOnArrival"
  | SetSkipAutoForward(_) => "SetSkipAutoForward"
  | UpdateAdvanceTime(_) => "UpdateAdvanceTime"
  | SetPendingAdvance(_) => "SetPendingAdvance"
  }
