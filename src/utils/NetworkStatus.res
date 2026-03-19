/* src/utils/NetworkStatus.res */
include NetworkStatusTypes

@val @scope("navigator") external navigatorOnLine: bool = "onLine"

@val @scope("window")
external addEventListener: (string, unit => unit) => unit = "addEventListener"

@val @scope("window")
external removeEventListener: (string, unit => unit) => unit = "removeEventListener"

let boolSubscribers: ref<array<bool => unit>> = ref([])
let snapshotSubscribers: ref<array<statusSnapshot => unit>> = ref([])

let retryDelaysMs = [2000, 5000, 10000, 15000, 30000]

let phaseAllowsRequests = phase => NetworkStatusTypes.phaseAllowsRequests(phase)

let phaseMessage = phase => NetworkStatusTypes.phaseMessage(phase)

let reasonSignature = reason => NetworkStatusTypes.reasonSignature(reason)

let optionIntEquals = (left: option<int>, right: option<int>): bool =>
  NetworkStatusTypes.optionIntEquals(left, right)

let optionFloatEquals = (left: option<float>, right: option<float>): bool =>
  NetworkStatusTypes.optionFloatEquals(left, right)

let intMax = (left: int, right: int): int => NetworkStatusTypes.intMax(left, right)

let intMin = (left: int, right: int): int => NetworkStatusTypes.intMin(left, right)

let currentPhase: ref<statusPhase> = ref(
  if navigatorOnLine {
    HealthyPhase
  } else {
    BrowserOfflinePhase
  },
)
let currentReason: ref<statusReason> = ref(
  if navigatorOnLine {
    Healthy
  } else {
    BrowserOffline
  },
)
let currentOnline: ref<bool> = ref(phaseAllowsRequests(currentPhase.contents))
let currentAttempt: ref<int> = ref(0)
let currentRetryDelayMs: ref<option<int>> = ref(None)
let currentNextRetryAtMs: ref<option<float>> = ref(None)
let lastHealthyAtMs: ref<option<float>> = ref(
  if navigatorOnLine {
    Some(Date.now())
  } else {
    None
  },
)
let retryTimeoutId: ref<option<int>> = ref(None)
let probeInFlight = ref(false)
let initialized = ref(false)
let skipProbe = ref(false)


let getSnapshot = (): statusSnapshot => {
  let phase = currentPhase.contents
  {
    online: currentOnline.contents,
    phase,
    reason: currentReason.contents,
    message: phaseMessage(phase),
    attempt: currentAttempt.contents,
    retryDelayMs: currentRetryDelayMs.contents,
    nextRetryAtMs: currentNextRetryAtMs.contents,
    lastHealthyAtMs: lastHealthyAtMs.contents,
  }
}

let isOnline = (): bool => currentOnline.contents

let subscribe = (callback: bool => unit): (unit => unit) => {
  Array.push(boolSubscribers.contents, callback)
  () => {
    boolSubscribers := boolSubscribers.contents->Belt.Array.keep(cb => cb !== callback)
  }
}

let subscribeSnapshot = (callback: statusSnapshot => unit): (unit => unit) => {
  Array.push(snapshotSubscribers.contents, callback)
  () => {
    snapshotSubscribers := snapshotSubscribers.contents->Belt.Array.keep(cb => cb !== callback)
  }
}

let notifySubscribers = (~onlineChanged: bool) => {
  let snapshot = getSnapshot()
  if onlineChanged {
    EventBus.dispatch(NetworkStatusChanged(snapshot.online))
  }
  boolSubscribers.contents->Belt.Array.forEach(cb => cb(snapshot.online))
  snapshotSubscribers.contents->Belt.Array.forEach(cb => cb(snapshot))
}

let clearRetryTimer = () => {
  switch retryTimeoutId.contents {
  | Some(id) =>
    ReBindings.Window.clearTimeout(id)
    retryTimeoutId := None
  | None => ()
  }
}

let applySnapshot = (
  ~phase: statusPhase,
  ~reason: statusReason,
  ~attempt: int,
  ~retryDelayMs: option<int>,
  ~nextRetryAtMs: option<float>,
) => {
  let nextOnline = phaseAllowsRequests(phase)
  let onlineChanged = currentOnline.contents !== nextOnline
  let changed =
    onlineChanged ||
    currentPhase.contents !== phase ||
    reasonSignature(currentReason.contents) != reasonSignature(reason) ||
    currentAttempt.contents != attempt ||
    !optionIntEquals(currentRetryDelayMs.contents, retryDelayMs) ||
    !optionFloatEquals(currentNextRetryAtMs.contents, nextRetryAtMs)

  currentPhase := phase
  currentReason := reason
  currentOnline := nextOnline
  currentAttempt := attempt
  currentRetryDelayMs := retryDelayMs
  currentNextRetryAtMs := nextRetryAtMs

  if phase === HealthyPhase {
    lastHealthyAtMs := Some(Date.now())
  }

  if changed {
    notifySubscribers(~onlineChanged)
  }
}

let nextDelayForAttempt = (attempt: int): int => {
  let index = intMax(0, attempt - 1)
  retryDelaysMs
  ->Belt.Array.get(intMin(index, Array.length(retryDelaysMs) - 1))
  ->Option.getOr(30000)
}

let rec scheduleRetry = (delayMs: int) => {
  clearRetryTimer()
  let nextRetryAt = Date.now() +. Float.fromInt(delayMs)
  retryTimeoutId := Some(ReBindings.Window.setTimeout(() => {
        retryTimeoutId := None
        let _ = probe()
      }, delayMs))
  (Some(delayMs), Some(nextRetryAt))
}

and enterState = (~phase: statusPhase, ~reason: statusReason, ~retryDelayMs: option<int>=?) => {
  let nextAttempt = if phase === HealthyPhase {
    0
  } else if currentPhase.contents === HealthyPhase {
    1
  } else {
    currentAttempt.contents + 1
  }

  let resolvedRetryDelay = switch retryDelayMs {
  | Some(ms) => ms
  | None => nextDelayForAttempt(nextAttempt)
  }

  switch phase {
  | HealthyPhase =>
    clearRetryTimer()
    applySnapshot(~phase, ~reason, ~attempt=0, ~retryDelayMs=None, ~nextRetryAtMs=None)
  | BrowserOfflinePhase
  | RecoveringPhase
  | RateLimitedPhase =>
    let (retryDelayMsOpt, nextRetryAtMsOpt) = scheduleRetry(resolvedRetryDelay)
    applySnapshot(
      ~phase,
      ~reason,
      ~attempt=nextAttempt,
      ~retryDelayMs=retryDelayMsOpt,
      ~nextRetryAtMs=nextRetryAtMsOpt,
    )
  }
}

and parseRetryAfter = (res: WebApiBindings.Fetch.response): option<int> => {
  let headers = WebApiBindings.Fetch.headers(res)
  let direct = WebApiBindings.Fetch.getHeader(headers, "retry-after")->Nullable.toOption
  let xRate = WebApiBindings.Fetch.getHeader(headers, "x-ratelimit-after")->Nullable.toOption
  let raw = direct->Option.orElse(xRate)
  raw->Option.flatMap(Belt.Int.fromString)
}

and probe = async (~isInitial=false) => {
  let _ = isInitial
  if skipProbe.contents {
    enterState(~phase=HealthyPhase, ~reason=Healthy)
    true
  } else if probeInFlight.contents {
    currentOnline.contents
  } else {
    probeInFlight := true
    try {
      let res = await WebApiBindings.Fetch.fetch(
        "/api/health",
        WebApiBindings.Fetch.requestInit(~method="GET", ()),
      )
      probeInFlight := false
      if WebApiBindings.Fetch.ok(res) {
        enterState(~phase=HealthyPhase, ~reason=Healthy)
        true
      } else if WebApiBindings.Fetch.status(res) == 429 {
        let retryAfter = parseRetryAfter(res)
        let retryAfterMs = retryAfter->Option.map(seconds => seconds * 1000)
        enterState(
          ~phase=RateLimitedPhase,
          ~reason=BackendRateLimited(retryAfter),
          ~retryDelayMs=?retryAfterMs,
        )
        phaseAllowsRequests(RateLimitedPhase)
      } else {
        enterState(
          ~phase=RecoveringPhase,
          ~reason=BackendUnavailable(
            WebApiBindings.Fetch.status(res),
            WebApiBindings.Fetch.statusText(res),
          ),
        )
        false
      }
    } catch {
    | JsExn(error) =>
      probeInFlight := false
      let reason = switch JsExn.message(error)->Option.getOr("") {
      | "" => ProbeNetworkFailure
      | message => TransportFailure(message)
      }
      let phase = switch reason {
      | BrowserOffline => BrowserOfflinePhase
      | _ => RecoveringPhase
      }
      enterState(~phase, ~reason)
      false
    | _ =>
      probeInFlight := false
      enterState(~phase=RecoveringPhase, ~reason=ProbeNetworkFailure)
      false
    }
  }
}

and probeNow = () => {
  clearRetryTimer()
  probe()
}

and reportBackendUnavailable = (~status: int, ~statusText: string) => {
  enterState(~phase=RecoveringPhase, ~reason=BackendUnavailable(status, statusText))
}

and reportProbeFailure = () => {
  enterState(~phase=RecoveringPhase, ~reason=ProbeNetworkFailure)
}

and reportRateLimited = (~retryAfterSeconds: int) => {
  enterState(
    ~phase=RateLimitedPhase,
    ~reason=BackendRateLimited(Some(retryAfterSeconds)),
    ~retryDelayMs=retryAfterSeconds * 1000,
  )
}

and reportTransportFailure = (~message: string) => {
  enterState(~phase=RecoveringPhase, ~reason=TransportFailure(message))
}

and reportRequestSuccess = () => {
  if currentPhase.contents !== HealthyPhase {
    enterState(~phase=HealthyPhase, ~reason=Healthy)
  }
}

let forceStatus = (online: bool) => {
  if online {
    enterState(~phase=HealthyPhase, ~reason=Healthy)
  } else {
    enterState(~phase=BrowserOfflinePhase, ~reason=BrowserOffline)
  }
}

let handleOnline = () => {
  if skipProbe.contents {
    enterState(~phase=HealthyPhase, ~reason=Healthy)
  } else {
    let _ = probeNow()
  }
}

let handleOffline = () => {
  enterState(~phase=BrowserOfflinePhase, ~reason=BrowserOffline)
}

let handleFocus = () => {
  if currentPhase.contents !== HealthyPhase {
    let _ = probeNow()
  }
}

let cleanup = () => {
  initialized := false
  clearRetryTimer()
  probeInFlight := false
  removeEventListener("online", handleOnline)
  removeEventListener("offline", handleOffline)
  removeEventListener("focus", handleFocus)
}

let resetRuntimeState = () => {
  clearRetryTimer()
  currentAttempt := 0
  currentRetryDelayMs := None
  currentNextRetryAtMs := None
  currentPhase := if navigatorOnLine {
      HealthyPhase
    } else {
      BrowserOfflinePhase
    }
  currentReason := if navigatorOnLine {
      Healthy
    } else {
      BrowserOffline
    }
  currentOnline := phaseAllowsRequests(currentPhase.contents)
  lastHealthyAtMs := if navigatorOnLine {
      Some(Date.now())
    } else {
      None
    }
}

let registerEventListeners = () => {
  addEventListener("online", handleOnline)
  addEventListener("offline", handleOffline)
  addEventListener("focus", handleFocus)
}

let bootstrapStartupState = () => {
  if navigatorOnLine {
    let _ = probeNow()
  } else {
    enterState(~phase=BrowserOfflinePhase, ~reason=BrowserOffline)
  }
}

let initialize = () => {
  if initialized.contents {
    cleanup()
  }

  initialized := true
  resetRuntimeState()
  registerEventListeners()
  bootstrapStartupState()
}
