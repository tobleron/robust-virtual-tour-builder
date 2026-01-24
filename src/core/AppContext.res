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
  let make = (~children, ~initialState as injectedState=?) => {
    let loadedState = React.useMemo0(() => {
      switch injectedState {
      | Some(s) => s
      | None =>
        switch SessionStore.loadState() {
        | Some(s) => {
            ...initialState,
            // DO NOT restore tourName or activeIndex on first load (requested behavior)
            // These should only come from a fresh upload or a project import
            activeYaw: s.activeYaw,
            activePitch: s.activePitch,
            isLinking: s.isLinking,
            isTeasing: s.isTeasing,
          }
        | None => initialState
        }
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
