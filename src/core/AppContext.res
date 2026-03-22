open Types
open! Actions

type dispatch = action => unit

let defaultDispatch: dispatch = _ => ()

let stateBridgeRef: ref<state> = ref(State.initialState)
let dispatchBridgeRef: ref<dispatch> = ref(defaultDispatch)

let getBridgeState = AppStateBridge.getState
let setBridgeState = AppStateBridge.updateState
let getBridgeDispatch = () => AppStateBridge.dispatch
let restoreState = (nextState: state) => AppStateBridge.dispatch(Actions.RestoreState(nextState))

type sceneSlice = AppContextSlices.sceneSlice
type uiSlice = AppContextSlices.uiSlice
type simSlice = AppContextSlices.simSlice
type pipelineSlice = AppContextSlices.pipelineSlice
type navigationSlice = AppContextSlices.navigationSlice

let defaultSceneSlice: sceneSlice = {
  scenes: AppContextSlices.defaultSceneSlice.scenes,
  activeIndex: AppContextSlices.defaultSceneSlice.activeIndex,
  tourName: AppContextSlices.defaultSceneSlice.tourName,
  activeYaw: AppContextSlices.defaultSceneSlice.activeYaw,
  activePitch: AppContextSlices.defaultSceneSlice.activePitch,
  discoveringTitleCount: AppContextSlices.defaultSceneSlice.discoveringTitleCount,
}

let defaultUiSlice: uiSlice = {
  isLinking: AppContextSlices.defaultUiSlice.isLinking,
  isTeasing: AppContextSlices.defaultUiSlice.isTeasing,
  linkDraft: AppContextSlices.defaultUiSlice.linkDraft,
  movingHotspot: AppContextSlices.defaultUiSlice.movingHotspot,
  appMode: AppContextSlices.defaultUiSlice.appMode,
  logo: AppContextSlices.defaultUiSlice.logo,
  preloadingSceneIndex: AppContextSlices.defaultUiSlice.preloadingSceneIndex,
}

let defaultSimSlice: simSlice = {
  simulation: AppContextSlices.defaultSimSlice.simulation,
  navigation: AppContextSlices.defaultSimSlice.navigation,
  currentJourneyId: AppContextSlices.defaultSimSlice.currentJourneyId,
  incomingLink: AppContextSlices.defaultSimSlice.incomingLink,
}

let defaultPipelineSlice: pipelineSlice = {
  timeline: State.initialState.timeline,
  scenes: SceneInventory.getActiveScenes(
    State.initialState.inventory,
    State.initialState.sceneOrder,
  ),
  activeIndex: State.initialState.activeIndex,
  activeTimelineStepId: State.initialState.activeTimelineStepId,
}

let globalContext = React.createContext(State.initialState)
let sceneContext = React.createContext(defaultSceneSlice)
let uiContext = React.createContext(defaultUiSlice)
let simContext = React.createContext(defaultSimSlice)
let navigationContext = React.createContext(NavigationState.initial())
let pipelineContext = React.createContext({
  ...defaultPipelineSlice,
  activeIndex: defaultPipelineSlice.activeIndex,
})
let dispatchContext = React.createContext(defaultDispatch)

let isRafBatchableAction = (action: action): bool => {
  AppContextProviderHooks.isRafBatchableAction(action)
}

module GlobalProvider = {
  let make = React.Context.provider(globalContext)
}
module SceneSliceProvider = {
  let make = React.Context.provider(sceneContext)
}
module UiSliceProvider = {
  let make = React.Context.provider(uiContext)
}
module SimSliceProvider = {
  let make = React.Context.provider(simContext)
}
module NavigationSliceProvider = {
  let make = React.Context.provider(navigationContext)
}
module PipelineSliceProvider = {
  let make = React.Context.provider(pipelineContext)
}

// Aliases for compatibility with existing tests
module SceneProvider = SceneSliceProvider
module UiProvider = UiSliceProvider
module SimProvider = SimSliceProvider

module DispatchProvider = {
  let make = React.Context.provider(dispatchContext)
}

module Provider = {
  @react.component
  let make = (~children, ~initialState as injectedState=?) => {
    let loadedState = React.useMemo0(() => {
      AppContextProviderHooks.loadInitialState(injectedState)
    })

    let reducerWithBridge = React.useCallback((state, action) => {
      Reducer.reducer(state, action)
    }, ())

    let (state, dispatchRaw) = React.useReducer(reducerWithBridge, loadedState)

    // Synchronous Bridge Update: Eliminate bridge lag by updating before child hooks run.
    // This is the sole authoritative write, avoiding redundant side-effects inside the reducer.
    AppStateBridge.updateState(state)

    let dispatch = AppContextProviderHooks.useManagedDispatch(dispatchRaw)

    AppContextProviderHooks.useLoadSessionTimeline(dispatch)

    // Domain-Specific Slices
    let scenes = React.useMemo2(() => {
      SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    }, (state.inventory, state.sceneOrder))

    // Domain-Specific Slices
    let sceneSlice: sceneSlice = React.useMemo6((): AppContextSlices.sceneSlice => {
      {
        scenes,
        activeIndex: state.activeIndex,
        tourName: state.tourName,
        activeYaw: state.activeYaw,
        activePitch: state.activePitch,
        discoveringTitleCount: state.discoveringTitleCount,
      }
    }, (
      scenes,
      state.activeIndex,
      state.tourName,
      state.activeYaw,
      state.activePitch,
      state.discoveringTitleCount,
    ))

    let uiSlice: uiSlice = React.useMemo7((): AppContextSlices.uiSlice => {
      {
        isLinking: state.isLinking,
        isTeasing: state.isTeasing,
        linkDraft: state.linkDraft,
        movingHotspot: state.movingHotspot,
        appMode: state.appMode,
        logo: state.logo,
        preloadingSceneIndex: state.preloadingSceneIndex,
      }
    }, (
      state.isLinking,
      state.isTeasing,
      state.linkDraft,
      state.movingHotspot,
      state.appMode,
      state.logo,
      state.preloadingSceneIndex,
    ))

    let simSlice: simSlice = React.useMemo4((): AppContextSlices.simSlice => {
      {
        simulation: state.simulation,
        navigation: state.navigationState.navigation,
        currentJourneyId: state.navigationState.currentJourneyId,
        incomingLink: state.navigationState.incomingLink,
      }
    }, (
      state.simulation,
      state.navigationState.navigation,
      state.navigationState.currentJourneyId,
      state.navigationState.incomingLink,
    ))

    let pipelineSlice: pipelineSlice = React.useMemo5((): AppContextSlices.pipelineSlice => {
      {
        timeline: state.timeline,
        scenes: SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
        activeIndex: state.activeIndex,
        activeTimelineStepId: state.activeTimelineStepId,
      }
    }, (
      state.timeline,
      state.inventory,
      state.sceneOrder,
      state.activeIndex,
      state.activeTimelineStepId,
    ))

    let navigationSlice = React.useMemo1(() => state.navigationState, [state.navigationState])

    React.useEffect1(() => {
      StateDensityMonitor.observe(state)
      None
    }, [state.structuralRevision])

    React.useEffect1(() => {
      dispatchBridgeRef := dispatch
      None
    }, [dispatch])

    React.useEffect0(() => {
      AppStateBridge.registerDispatch(dispatch)
      None
    })

    let sessionSlice = AppContextProviderHooks.useSessionSlice(state)

    AppContextProviderHooks.usePersistSessionSlice(sessionSlice)

    <DispatchProvider value=dispatch>
      <GlobalProvider value=state>
        <SceneSliceProvider value=sceneSlice>
          <UiSliceProvider value=uiSlice>
            <SimSliceProvider value=simSlice>
              <NavigationSliceProvider value=navigationSlice>
                <PipelineSliceProvider value=pipelineSlice> children </PipelineSliceProvider>
              </NavigationSliceProvider>
            </SimSliceProvider>
          </UiSliceProvider>
        </SceneSliceProvider>
      </GlobalProvider>
    </DispatchProvider>
  }
}

// Global hook (subscribes to everything - use for logic systems/controllers)
let useAppState = () => React.useContext(globalContext)
let useAppDispatch = () => React.useContext(dispatchContext)

// Specialized Hooks (return slices)
let useSceneSlice = () => React.useContext(sceneContext)
let useUiSlice = () => React.useContext(uiContext)
let useSimSlice = () => React.useContext(simContext)
let useNavigationSlice = () => React.useContext(navigationContext)
let usePipelineSlice = () => React.useContext(pipelineContext)

// Phase 1: Navigation State Slice
let useNavigationState = useNavigationSlice

let useNavigationFsm = () => {
  let nav = useNavigationSlice()
  nav.navigationFsm
}

let useAppSelector = (
  ~selector: state => 'slice,
  ~isEqual: ('slice, 'slice) => bool=(a, b) => a === b,
) => {
  let eq = isEqual
  let (selected, setSelected) = React.useState(() => selector(getBridgeState()))
  let selectedRef = React.useRef(selected)
  selectedRef.current = selected

  React.useEffect1(() => {
    let unsubscribe = AppStateBridge.subscribe(nextState => {
      let nextSelected = selector(nextState)
      if !eq(selectedRef.current, nextSelected) {
        selectedRef.current = nextSelected
        setSelected(_ => nextSelected)
      }
    })
    Some(() => unsubscribe())
  }, [selector])

  selected
}
