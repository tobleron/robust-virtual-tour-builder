open State
open Actions

type dispatch = action => unit

let defaultDispatch: dispatch = _ => ()

let stateContext = React.createContext(initialState)
let dispatchContext = React.createContext(defaultDispatch)

module StateProvider = {
  let make = React.Context.provider(stateContext)
}

module DispatchProvider = {
  let make = React.Context.provider(dispatchContext)
}

module Provider = {
  @react.component
  let make = (~children) => {
    let loadedState = React.useMemo0(() => {
      switch SessionStore.loadState() {
      | Some(s) => {
          ...initialState,
          tourName: TourLogic.isUnknownName(s.tourName) ? initialState.tourName : s.tourName,
          activeIndex: s.activeIndex == -1 ? initialState.activeIndex : s.activeIndex,
          activeYaw: s.activeYaw,
          activePitch: s.activePitch,
          isLinking: s.isLinking,
          isTeasing: s.isTeasing,
        }
      | None => initialState
      }
    })

    let (state, dispatch) = React.useReducer(Reducer.reducer, loadedState)

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
      <StateProvider value=state> children </StateProvider>
    </DispatchProvider>
  }
}

let useAppState = () => React.useContext(stateContext)
let useAppDispatch = () => React.useContext(dispatchContext)
