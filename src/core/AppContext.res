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

// Slices definitions for optimized subscriptions
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

// Default values for initialization
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

// Specialized Contexts
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
let dispatchContext = React.createContext(defaultDispatch)

let isRafBatchableAction = (action: action): bool =>
  switch action {
  | UpdateLinkDraft(_)
  | SetPreloadingScene(_) => true
  | _ => false
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
      switch injectedState {
      | Some(s) => s
      | None =>
        switch SessionStore.loadState() {
        | Some(s) => {
            ...State.initialState,
            activeYaw: s.activeYaw,
            activePitch: s.activePitch,
            isLinking: false,
            isTeasing: false,
          }
        | None => State.initialState
        }
      }
    })

    let (state, dispatchRaw) = React.useReducer(Reducer.reducer, loadedState)

    // Synchronous Bridge Update: Eliminate bridge lag by updating before child hooks run.
    AppStateBridge.updateState(state)

    let rafIdRef = React.useRef(None)
    let queuedActionsRef = React.useRef([])

    let flushQueuedActions = () => {
      let queuedActions = queuedActionsRef.current
      queuedActionsRef.current = []
      rafIdRef.current = None
      switch Belt.Array.length(queuedActions) {
      | 0 => ()
      | 1 => dispatchRaw(queuedActions->Belt.Array.getExn(0))
      | _ => dispatchRaw(Batch(queuedActions))
      }
    }

    let dispatch = (nextAction: action) => {
      // Side-effect resets for module-level state on project load/reset
      switch nextAction {
      | LoadProject(_)
      | Reset =>
        Logger.info(~module_="AppContext", ~message="PERFORMING_MODULE_LEVEL_RESET", ())
        NavigationSupervisor.reset()
        OperationLifecycle.reset()
        ViewerState.resetState()
        StateSnapshot.clear()
      | _ => ()
      }

      if isRafBatchableAction(nextAction) {
        queuedActionsRef.current = Belt.Array.concat(queuedActionsRef.current, [nextAction])
        switch rafIdRef.current {
        | Some(_) => ()
        | None =>
          rafIdRef.current = Some(
            ReBindings.Window.requestAnimationFrame(() => flushQueuedActions()),
          )
        }
      } else {
        // Synchronous Bridge Update: Eliminate lag for non-batchable actions.
        // This ensures that any subsequent getState() calls (e.g. in event handlers or
        // optimistic actions) see the latest state immediately.
        let currentState = AppStateBridge.getState()
        let nextState = Reducer.reducer(currentState, nextAction)
        AppStateBridge.updateState(nextState)

        dispatchRaw(nextAction)
      }
    }

    // Load timeline from session if available
    React.useEffect0(() => {
      switch SessionStore.loadState() {
      | Some(s) =>
        switch s.timeline {
        | Some(t) if Array.length(t) > 0 => dispatch(Actions.SetTimeline(t))
        | _ => ()
        }
        switch s.activeTimelineStepId {
        | Some(id) => dispatch(Actions.SetActiveTimelineStep(Some(id)))
        | _ => ()
        }
      | None => ()
      }
      None
    })

    // Domain-Specific Slices
    let scenes = React.useMemo2(() => {
      SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    }, (state.inventory, state.sceneOrder))

    // Domain-Specific Slices
    let sceneSlice = React.useMemo6(() => {
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

    let uiSlice = React.useMemo7(() => {
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

    let simSlice = React.useMemo4(() => {
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

    let pipelineSlice = React.useMemo5(() => {
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

    let sessionCore = React.useMemo6(() => {
      (
        state.tourName,
        state.activeIndex,
        state.activeYaw,
        state.activePitch,
        state.isLinking,
        state.isTeasing,
      )
    }, (
      state.tourName,
      state.activeIndex,
      state.activeYaw,
      state.activePitch,
      state.isLinking,
      state.isTeasing,
    ))

    let sessionPipeline = React.useMemo2(() => {
      (state.timeline, state.activeTimelineStepId)
    }, (state.timeline, state.activeTimelineStepId))

    let sessionSlice = React.useMemo2(() => {
      let (tourName, activeIndex, activeYaw, activePitch, isLinking, isTeasing) = sessionCore
      let (timeline, activeTimelineStepId) = sessionPipeline

      let s: Types.sessionState = {
        tourName,
        activeIndex,
        activeYaw,
        activePitch,
        isLinking,
        isTeasing,
        timeline: Some(timeline),
        activeTimelineStepId,
      }
      s
    }, (sessionCore, sessionPipeline))

    React.useEffect1(() => {
      let timerId = setTimeout(() => {
        SessionStore.save(sessionSlice)
      }, 500)

      Some(
        () => {
          clearTimeout(timerId)
        },
      )
    }, [sessionSlice])

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
