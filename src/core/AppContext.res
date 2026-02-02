open Types
open Actions

type dispatch = action => unit

let defaultDispatch: dispatch = _ => ()

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
}

let defaultSimSlice: simSlice = {
  simulation: State.initialState.simulation,
  navigation: State.initialState.navigation,
  currentJourneyId: State.initialState.currentJourneyId,
  incomingLink: State.initialState.incomingLink,
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
            isLinking: s.isLinking,
            isTeasing: s.isTeasing,
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

    let uiSlice = React.useMemo3(() => {
      {
        isLinking: state.isLinking,
        isTeasing: state.isTeasing,
        linkDraft: state.linkDraft,
      }
    }, (state.isLinking, state.isTeasing, state.linkDraft))

    let simSlice = React.useMemo4(() => {
      {
        simulation: state.simulation,
        navigation: state.navigation,
        currentJourneyId: state.currentJourneyId,
        incomingLink: state.incomingLink,
      }
    }, (state.simulation, state.navigation, state.currentJourneyId, state.incomingLink))

    React.useLayoutEffect1(() => {
      GlobalStateBridge.setDispatch(dispatch)
      GlobalStateBridge.setState(state)
      None
    }, [state])

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

// Interaction Queue Hook
type interactionQueue = {
  dispatch: action => unit,
  enqueueThunk: (unit => Promise.t<unit>) => unit,
}

let useInteractionQueue = (): interactionQueue => {
  {
    dispatch: action => InteractionQueue.enqueue(Action(action)),
    enqueueThunk: fn => InteractionQueue.enqueue(Thunk(fn)),
  }
}
