/* src/core/GlobalStateBridge.res */

/**
 * @deprecated Compatibility shim.
 * Use AppStateBridge directly for all new code.
 */
open Types

let setDispatch = (d: Actions.action => unit) => {
  AppStateBridge.registerDispatch(d)
}

let setState = (s: state) => {
  AppStateBridge.updateState(s)
}

let subscribe = (cb: state => unit) => {
  AppStateBridge.subscribe(cb)
}

let dispatch = (action: Actions.action) => {
  AppStateBridge.dispatch(action)
}

let getState = () => {
  AppStateBridge.getState()
}
