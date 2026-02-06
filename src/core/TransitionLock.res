/* src/core/TransitionLock.res */

type phase =
  | Idle
  | Loading(string)
  | Swapping(string)
  | Cleanup(string)

let current = ref(Idle)
let onIdleCallbacks = ref([])

let isIdle = () => {
  current.contents == Idle
}

let isSwapping = () => {
  switch current.contents {
  | Swapping(_) => true
  | _ => false
  }
}

let onIdle = (cb: unit => unit) => {
  if isIdle() {
    cb()
  } else {
    onIdleCallbacks := Belt.Array.concat(onIdleCallbacks.contents, [cb])
  }
}

let phaseToString = (p: phase): string => {
  switch p {
  | Idle => "Idle"
  | Loading(id) => "Loading(" ++ id ++ ")"
  | Swapping(id) => "Swapping(" ++ id ++ ")"
  | Cleanup(id) => "Cleanup(" ++ id ++ ")"
  }
}

let acquire = (requester: string, newPhase: phase): result<unit, string> => {
  if isIdle() {
    current := newPhase
    Logger.debug(
      ~module_="TransitionLock",
      ~message="LOCK_ACQUIRED",
      ~data=Some({
        "requester": requester,
        "newPhase": phaseToString(newPhase),
      }),
      (),
    )
    Ok()
  } else {
    Logger.warn(
      ~module_="TransitionLock",
      ~message="LOCK_REJECTED",
      ~data=Some({
        "requester": requester,
        "currentPhase": phaseToString(current.contents),
        "requestedPhase": phaseToString(newPhase),
      }),
      (),
    )
    Error("Transition lock occupied by " ++ phaseToString(current.contents))
  }
}

let transition = (requester: string, newPhase: phase) => {
  let prev = current.contents
  current := newPhase
  Logger.debug(
    ~module_="TransitionLock",
    ~message="LOCK_TRANSITION",
    ~data=Some({
      "requester": requester,
      "prev": phaseToString(prev),
      "next": phaseToString(newPhase),
    }),
    (),
  )
}

let release = (requester: string) => {
  let prev = current.contents
  current := Idle
  Logger.debug(
    ~module_="TransitionLock",
    ~message="LOCK_RELEASED",
    ~data=Some({
      "requester": requester,
      "prev": phaseToString(prev),
    }),
    (),
  )

  /* Flush callbacks */
  let callbacks = onIdleCallbacks.contents
  onIdleCallbacks := []
  callbacks->Belt.Array.forEach(cb => cb())
}

Logger.initialized(~module_="TransitionLock")
