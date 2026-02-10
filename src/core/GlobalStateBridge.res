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
let noopDispatch = _ => ()
let dispatchRef: ref<Actions.action => unit> = ref(noopDispatch)
let stateRef = ref(State.initialState)
let listeners: ref<array<Types.state => unit>> = ref([])

let setDispatch = d => {
  Logger.info(~module_="GlobalStateBridge", ~message="DISPATCH_FUNCTION_SET", ())
  dispatchRef := d
}
let setState = s => {
  stateRef := s
  %raw(`window.__RE_STATE__ = s`)->ignore
  // Logger.debug(~module_="GlobalStateBridge", ~message="STATE_UPDATED", ())
  Belt.Array.forEach(listeners.contents, cb => cb(s))
}

let subscribe = cb => {
  listeners := Belt.Array.concat(listeners.contents, [cb])
  () => {
    listeners := Array.filter(listeners.contents, l => l !== cb)
  }
}

let dispatch = action => {
  if (dispatchRef.contents === noopDispatch) {
    Logger.warn(~module_="GlobalStateBridge", ~message="DISPATCH_CALLED_BEFORE_READY", ())
  }
  // Logger.debug(~module_="GlobalStateBridge", ~message="DISPATCH_CALLED: " ++ Actions.actionToString(action), ())
  dispatchRef.contents(action)
}
let getState = () => stateRef.contents
