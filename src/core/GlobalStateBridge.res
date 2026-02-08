/* src/core/GlobalStateBridge.res */

/**
 * GlobalStateBridge - Controlled access to application state
 * 
 * WARNING: This module provides direct access to application state.
 * It should ONLY be used by:
 * - StateInspector (debug builds)
 * - Systems that need read-only state access (AudioManager, SimulationSystem)
 * 
 * DO NOT use this for state mutations. Always dispatch actions via AppContext.
 */
let dispatchRef: ref<Actions.action => unit> = ref(_ => ())
let stateRef = ref(State.initialState)
let listeners: ref<array<Types.state => unit>> = ref([])

let setDispatch = d => dispatchRef := d
let setState = s => {
  stateRef := s
  Belt.Array.forEach(listeners.contents, cb => cb(s))
}

let subscribe = cb => {
  listeners := Belt.Array.concat(listeners.contents, [cb])
  () => {
    listeners := Array.filter(listeners.contents, l => l !== cb)
  }
}

let dispatch = action => {
  dispatchRef.contents(action)
}
let getState = () => stateRef.contents
