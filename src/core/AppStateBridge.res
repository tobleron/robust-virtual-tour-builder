/* src/core/AppStateBridge.res */

open Types

let defaultDispatch = _ => ()

let stateValueRef: ref<state> = ref(State.initialState)
let dispatchRef: ref<Actions.action => unit> = ref(defaultDispatch)
let readyRef: ref<bool> = ref(false)
let emptyUnitCallback: unit => unit = (_: unit) => ()
let emptyStateListener: state => unit = (_: state) => ()

let readyCallbacks: ref<array<unit => unit>> = ref(Belt.Array.make(0, emptyUnitCallback))
let listeners: ref<array<state => unit>> = ref(Belt.Array.make(0, emptyStateListener))

let isReady = () => readyRef.contents

let registerDispatch = (dispatch: Actions.action => unit) => {
  dispatchRef := dispatch
  readyRef := true
  readyCallbacks.contents->Belt.Array.forEach(cb => cb())
  readyCallbacks := Belt.Array.make(0, emptyUnitCallback)
}

let updateState = (state: state) => {
  stateValueRef := state
  listeners.contents->Belt.Array.forEach(cb => cb(state))
}

let getState = () => stateValueRef.contents
let dispatch = action => dispatchRef.contents(action)

let subscribe = (cb: state => unit) => {
  cb(stateValueRef.contents)
  listeners := Belt.Array.concat(listeners.contents, [cb])
  () => {
    listeners := Array.filter(listeners.contents, listener => listener !== cb)
  }
}

let onReady = (cb: unit => unit) => {
  if readyRef.contents {
    cb()
  } else {
    readyCallbacks := Belt.Array.concat(readyCallbacks.contents, [cb])
  }
}
