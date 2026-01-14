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
    let (state, dispatch) = React.useReducer(Reducer.reducer, initialState)

    React.useEffect1(() => {
      GlobalStateBridge.setDispatch(dispatch)
      GlobalStateBridge.setState(state)
      None
    }, [state])

    <DispatchProvider value=dispatch>
      <StateProvider value=state> children </StateProvider>
    </DispatchProvider>
  }
}

let useAppState = () => React.useContext(stateContext)
let useAppDispatch = () => React.useContext(dispatchContext)
