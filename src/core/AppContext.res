open Types
open Actions

type dispatch = action => unit

let defaultDispatch: dispatch = _ => ()

let stateBridgeRef: ref<state> = ref(State.initialState)
let dispatchBridgeRef: ref<dispatch> = ref(defaultDispatch)

let getBridgeState = () => stateBridgeRef.contents
let getBridgeDispatch = () => dispatchBridgeRef.contents
let restoreState = (nextState: state) => dispatchBridgeRef.contents(Actions.RestoreState(nextState))

// Slices definitions for optimized subscriptions
type sceneSlice = {
  scenes: array<scene>,
  activeIndex: int,
  tourName: string,
}

type uiSlice = {
  isLinking: bool,
  isTeasing: bool,
  linkDraft: option<linkDraft>,
  appMode: appMode,
}

type simSlice = {
  simulation: simulationState,
  navigation: navigationStatus,
  currentJourneyId: int,
  incomingLink: option<linkInfo>,
}

// Default values for initialization
let defaultSceneSlice: sceneSlice = {
  scenes: State.initialState.scenes,
  activeIndex: State.initialState.activeIndex,
  tourName: State.initialState.tourName,
}

let defaultUiSlice: uiSlice = {
  isLinking: State.initialState.isLinking,
  isTeasing: State.initialState.isTeasing,
  linkDraft: State.initialState.linkDraft,
  appMode: State.initialState.appMode,
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
let dispatchContext = React.createContext(defaultDispatch)

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

    let (state, dispatch) = React.useReducer(Reducer.reducer, loadedState)

    // Domain-Specific Slices
    let sceneSlice = React.useMemo3(() => {
      {
        scenes: state.scenes,
        activeIndex: state.activeIndex,
        tourName: state.tourName,
      }
    }, (state.scenes, state.activeIndex, state.tourName))

    let uiSlice = React.useMemo4(() => {
      {
        isLinking: state.isLinking,
        isTeasing: state.isTeasing,
        linkDraft: state.linkDraft,
        appMode: state.appMode,
      }
    }, (state.isLinking, state.isTeasing, state.linkDraft, state.appMode))

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

    React.useEffect1(() => {
      stateBridgeRef := state
      AppStateBridge.updateState(state)
      None
    }, [state])

    React.useEffect1(() => {
      dispatchBridgeRef := dispatch
      None
    }, [dispatch])

    React.useEffect0(() => {
      AppStateBridge.registerDispatch(dispatch)
      None
    })

    React.useEffect1(() => {
      let timerId = setTimeout(() => {
        SessionStore.saveState(state)
      }, 500)

      Some(
        () => {
          clearTimeout(timerId)
        },
      )
    }, [state])

    <DispatchProvider value=dispatch>
      <GlobalProvider value=state>
        <SceneSliceProvider value=sceneSlice>
          <UiSliceProvider value=uiSlice>
            <SimSliceProvider value=simSlice> children </SimSliceProvider>
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

// Legacy compatibility hooks - return global state but encouraged to use slices
let useSceneState = () => React.useContext(globalContext) // Temporary fallback
let useUiState = () => React.useContext(globalContext) // Temporary fallback
let useSimState = () => React.useContext(globalContext) // Temporary fallback

// Phase 1: Navigation State Slice
let useNavigationState = () => {
  let state = React.useContext(globalContext)
  state.navigationState
}

let useNavigationFsm = () => {
  let state = React.useContext(globalContext)
  state.navigationState.navigationFsm
}

// Interaction Queue Hook

let useIsSystemLocked = () => {
  let uiSlice = useUiSlice()
  switch uiSlice.appMode {
  | Initializing => true
  | SystemBlocking(Uploading(_)) => false // Now Ambient in Interactive, but still handled for compatibility if triggered
  | SystemBlocking(ProjectLoading(_))
  | SystemBlocking(Exporting(_)) => true
  | SystemBlocking(Summary(_))
  | SystemBlocking(CriticalError(_)) => false
  | Interactive(_) => false
  }
}
