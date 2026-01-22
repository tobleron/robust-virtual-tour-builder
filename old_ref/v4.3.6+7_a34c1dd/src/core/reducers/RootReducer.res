open Types
open Actions

/**
 * RootReducer - Combines all domain-specific reducers using a Pipeline Pattern
 * 
 * Unlike the previous short-circuit pattern, this passes the state through
 * EVERY reducer sequentially. This allows multiple reducers to react to
 * the same action (e.g. SetIsLinking updates UI state AND Scene state).
 */
let // Helper to apply a reducer that returns option<state>
apply = (state: state, action: action, reducerFn: (state, action) => option<state>): state => {
  switch reducerFn(state, action) {
  | Some(newState) => newState
  | None => state
  }
}

let reducer = (state: state, action: action): state => {
  state
  ->apply(action, SceneReducer.reduce)
  ->apply(action, HotspotReducer.reduce)
  ->apply(action, UiReducer.reduce)
  ->apply(action, NavigationReducer.reduce)
  ->apply(action, SimulationReducer.reduce)
  ->apply(action, TimelineReducer.reduce)
  ->apply(action, ProjectReducer.reduce)
}
