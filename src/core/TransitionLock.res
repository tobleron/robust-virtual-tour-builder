/* src/core/TransitionLock.res */

type phase =
  | Idle
  | Loading(string)
  | Swapping(string)
  | Cleanup(string)

let current = ref(Idle)
let onIdleCallbacks = ref([])
let lockTimeoutId: ref<option<timeoutId>> = ref(None)
let listeners = ref([])
let acquiredAt: ref<option<float>> = ref(None)
let recoveryListeners = ref([])

let notifyListeners = () => {
  listeners.contents->Belt.Array.forEach(cb => cb(current.contents))
}

let addChangeListener = cb => {
  listeners := Belt.Array.concat(listeners.contents, [cb])
  () => {
    listeners := listeners.contents->Belt.Array.keep(x => x !== cb)
  }
}

let addRecoveryListener = (cb: unit => unit) => {
  recoveryListeners := Belt.Array.concat(recoveryListeners.contents, [cb])
  () => {
    recoveryListeners := recoveryListeners.contents->Belt.Array.keep(x => x !== cb)
  }
}

let notifyRecoveryListeners = () => {
  recoveryListeners.contents->Belt.Array.forEach(cb => cb())
}

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

let clearLockTimeout = () => {
  switch lockTimeoutId.contents {
  | Some(id) => clearTimeout(id)
  | None => ()
  }
  lockTimeoutId := None
}

let getTimeoutForPhase = (phase: phase): float => {
  switch phase {
  | Idle => 0.0
  | Loading(_) => 15000.0 // Scene loading can be slow (multi-resolution download)
  | Swapping(_) => 8000.0 // CSS fade is ~500ms, add buffer
  | Cleanup(_) => 3000.0 // Cleanup is ~500ms, prevent long waits
  }
}

let getRemainingMs = (): int => {
  switch acquiredAt.contents {
  | Some(startTime) =>
    let totalTimeoutMs = getTimeoutForPhase(current.contents)
    let elapsedMs = Date.now() -. startTime
    let remainingMs = totalTimeoutMs -. elapsedMs
    Math.max(0.0, remainingMs)->Float.toInt
  | None => 0
  }
}

let getTotalTimeoutMs = (): int => {
  getTimeoutForPhase(current.contents)->Float.toInt
}

let release = (requester: string, ~isTimeout=false) => {
  let prev = current.contents
  current := Idle
  clearLockTimeout()
  acquiredAt := None
  notifyListeners()

  Logger.debug(
    ~module_="TransitionLock",
    ~message="LOCK_RELEASED",
    ~data=Some({
      "requester": requester,
      "prev": phaseToString(prev),
      "isTimeout": isTimeout,
    }),
    (),
  )

  /* Notify recovery if timeout-triggered */
  if isTimeout {
    notifyRecoveryListeners()
  }

  /* Flush callbacks */
  let callbacks = onIdleCallbacks.contents
  onIdleCallbacks := []
  callbacks->Belt.Array.forEach(cb => cb())
}

let forceRelease = () => {
  Logger.error(
    ~module_="TransitionLock",
    ~message="LOCK_TIMEOUT_FORCED_RELEASE",
    ~data=Some({
      "phase": phaseToString(current.contents),
    }),
    (),
  )
  release("TransitionLock_Timeout_System", ~isTimeout=true)
}

let acquire = (requester: string, newPhase: phase): result<unit, string> => {
  if isIdle() {
    current := newPhase
    acquiredAt := Some(Date.now())

    let timeoutMs = getTimeoutForPhase(newPhase)->Float.toInt
    // Set a safety timeout based on phase type
    // If the transition isn't done by then, something is critically wrong.
    lockTimeoutId := Some(setTimeout(forceRelease, timeoutMs))
    notifyListeners()

    Logger.debug(
      ~module_="TransitionLock",
      ~message="LOCK_ACQUIRED",
      ~data=Some({
        "requester": requester,
        "newPhase": phaseToString(newPhase),
        "timeoutMs": timeoutMs,
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
  notifyListeners()

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

Logger.initialized(~module_="TransitionLock")
