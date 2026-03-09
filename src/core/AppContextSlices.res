// @efficiency-role: state-hook

open Types

type sceneSlice = {
  scenes: array<scene>,
  activeIndex: int,
  tourName: string,
  activeYaw: float,
  activePitch: float,
  discoveringTitleCount: int,
}

type uiSlice = {
  isLinking: bool,
  isTeasing: bool,
  linkDraft: option<linkDraft>,
  movingHotspot: option<movingHotspot>,
  appMode: appMode,
  logo: option<file>,
  preloadingSceneIndex: int,
}

type simSlice = {
  simulation: simulationState,
  navigation: navigationStatus,
  currentJourneyId: int,
  incomingLink: option<linkInfo>,
}

type pipelineSlice = {
  timeline: array<timelineItem>,
  scenes: array<scene>,
  activeIndex: int,
  activeTimelineStepId: option<string>,
}

type navigationSlice = navigationState

let defaultSceneSlice: sceneSlice = {
  scenes: SceneInventory.getActiveScenes(
    State.initialState.inventory,
    State.initialState.sceneOrder,
  ),
  activeIndex: State.initialState.activeIndex,
  tourName: State.initialState.tourName,
  activeYaw: State.initialState.activeYaw,
  activePitch: State.initialState.activePitch,
  discoveringTitleCount: State.initialState.discoveringTitleCount,
}

let defaultUiSlice: uiSlice = {
  isLinking: State.initialState.isLinking,
  isTeasing: State.initialState.isTeasing,
  linkDraft: State.initialState.linkDraft,
  movingHotspot: State.initialState.movingHotspot,
  appMode: State.initialState.appMode,
  logo: State.initialState.logo,
  preloadingSceneIndex: State.initialState.preloadingSceneIndex,
}

let defaultSimSlice: simSlice = {
  simulation: State.initialState.simulation,
  navigation: State.initialState.navigationState.navigation,
  currentJourneyId: State.initialState.navigationState.currentJourneyId,
  incomingLink: State.initialState.navigationState.incomingLink,
}

let globalContext = React.createContext(State.initialState)
let sceneContext = React.createContext(defaultSceneSlice)
let uiContext = React.createContext(defaultUiSlice)
let simContext = React.createContext(defaultSimSlice)
let navigationContext = React.createContext(NavigationState.initial())
let pipelineContext = React.createContext({
  timeline: State.initialState.timeline,
  scenes: SceneInventory.getActiveScenes(
    State.initialState.inventory,
    State.initialState.sceneOrder,
  ),
  activeIndex: State.initialState.activeIndex,
  activeTimelineStepId: State.initialState.activeTimelineStepId,
})
