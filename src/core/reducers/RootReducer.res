open Types
open Actions

/**
 * RootReducer - Combines all domain-specific reducers
 * 
 * This follows the "reducer composition" pattern where each domain
 * reducer handles its own slice of actions and returns None for
 * actions it doesn't handle.
 */

let reducer = (state: state, action: action): state => {
  // Try each domain reducer in sequence
  // First one to return Some(newState) wins
  
  switch SceneReducer.reduce(state, action) {
  | Some(newState) => newState
  | None =>
    switch HotspotReducer.reduce(state, action) {
    | Some(newState) => newState
    | None =>
      switch UiReducer.reduce(state, action) {
      | Some(newState) => newState
      | None =>
        switch NavigationReducer.reduce(state, action) {
        | Some(newState) => newState
        | None =>
          switch TimelineReducer.reduce(state, action) {
          | Some(newState) => newState
          | None =>
            switch ProjectReducer.reduce(state, action) {
            | Some(newState) => newState
            | None =>
              // No reducer handled this action - return state unchanged
              // Only warn if it's not a known no-op or handled elsewhere (which shouldn't happen here)
              Logger.warn(
                ~module_="RootReducer",
                ~message="Unhandled action",
                ~data=Some({"action": Actions.actionToString(action)}),
                ()
              )
              state
            }
          }
        }
      }
    }
  }
}
