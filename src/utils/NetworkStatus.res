/* src/utils/NetworkStatus.res */

// --- Bindings ---
@val @scope("navigator") external navigatorOnLine: bool = "onLine"

@val @scope("window")
external addEventListener: (string, unit => unit) => unit = "addEventListener"

@val @scope("window")
external removeEventListener: (string, unit => unit) => unit = "removeEventListener"

// --- State ---
let currentStatus: ref<bool> = ref(navigatorOnLine)
let subscribers: ref<array<bool => unit>> = ref([])

type statusReason =
  | BrowserOffline
  | ProbeNetworkFailure
  | BackendRateLimited(option<int>)
  | BackendUnavailable(int, string)
  | Healthy

let currentReason: ref<statusReason> = ref(navigatorOnLine ? Healthy : BrowserOffline)

let reasonToMessage = (reason: statusReason): string =>
  switch reason {
  | Healthy => "Connected."
  | BrowserOffline => "Browser reports no network connection."
  | ProbeNetworkFailure => "Cannot reach backend health endpoint."
  | BackendRateLimited(Some(secs)) =>
    "Backend is rate-limiting requests. Retry in " ++ Belt.Int.toString(secs) ++ "s."
  | BackendRateLimited(None) => "Backend is rate-limiting requests."
  | BackendUnavailable(status, statusText) =>
    "Backend health check failed (" ++ Belt.Int.toString(status) ++ " " ++ statusText ++ ")."
  }

type statusSnapshot = {
  online: bool,
  reason: statusReason,
  message: string,
}

// --- Public API ---
let isOnline = (): bool => currentStatus.contents

let getSnapshot = (): statusSnapshot => {
  let reason = currentReason.contents
  {online: currentStatus.contents, reason, message: reasonToMessage(reason)}
}

let subscribe = (callback: bool => unit): (unit => unit) => {
  Array.push(subscribers.contents, callback)
  () => {
    subscribers := subscribers.contents->Belt.Array.keep(cb => cb !== callback)
  }
}

// --- Internal ---
let notifySubscribers = (online: bool) => {
  subscribers.contents->Belt.Array.forEach(cb => cb(online))
}

let updateStatus = (online: bool, ~reason: statusReason) => {
  let changedOnline = currentStatus.contents !== online
  let changedReason = currentReason.contents !== reason

  if changedOnline || changedReason {
    currentStatus := online
    currentReason := reason

    switch reason {
    | Healthy => Console.info("NetworkStatus: NETWORK_ONLINE")
    | BrowserOffline => Console.warn("NetworkStatus: BROWSER_OFFLINE")
    | ProbeNetworkFailure => Console.warn("NetworkStatus: BACKEND_UNREACHABLE")
    | BackendRateLimited(Some(secs)) =>
      Console.warn2("NetworkStatus: BACKEND_RATE_LIMITED", {"retryAfterSec": secs})
    | BackendRateLimited(None) => Console.warn("NetworkStatus: BACKEND_RATE_LIMITED")
    | BackendUnavailable(status, statusText) =>
      Console.warn2(
        "NetworkStatus: BACKEND_UNAVAILABLE",
        {"status": status, "statusText": statusText},
      )
    }

    if changedOnline {
      EventBus.dispatch(NetworkStatusChanged(online))
    }
    notifySubscribers(online)
  }
}

let parseRetryAfter = (res: WebApiBindings.Fetch.response): option<int> => {
  let headers = WebApiBindings.Fetch.headers(res)
  let direct = WebApiBindings.Fetch.getHeader(headers, "retry-after")->Nullable.toOption
  let xRate = WebApiBindings.Fetch.getHeader(headers, "x-ratelimit-after")->Nullable.toOption
  let raw = direct->Option.orElse(xRate)
  raw->Option.flatMap(Belt.Int.fromString)
}

let probe = async () => {
  try {
    // We use a simple fetch to a known health endpoint.
    // We use a cache-busting or no-cache strategy to ensure we aren't getting a local response.
    let res = await WebApiBindings.Fetch.fetch(
      "/api/health",
      WebApiBindings.Fetch.requestInit(
        ~method="GET",
        // cache: "no-store" is not in the binding yet, but we can usually rely on health endpoint being non-cacheable on backend
        (),
      ),
    )
    if WebApiBindings.Fetch.ok(res) {
      updateStatus(true, ~reason=Healthy)
      true
    } else if WebApiBindings.Fetch.status(res) == 429 {
      let retryAfter = parseRetryAfter(res)
      updateStatus(false, ~reason=BackendRateLimited(retryAfter))
      false
    } else {
      updateStatus(
        false,
        ~reason=BackendUnavailable(
          WebApiBindings.Fetch.status(res),
          WebApiBindings.Fetch.statusText(res),
        ),
      )
      false
    }
  } catch {
  | _ =>
    // If navigator says we are online but fetch fails, we ARE offline (from app perspective)
    updateStatus(false, ~reason=ProbeNetworkFailure)
    false
  }
}

let forceStatus = (online: bool) => {
  if online {
    updateStatus(true, ~reason=Healthy)
  } else {
    updateStatus(false, ~reason=BrowserOffline)
  }
}

let skipProbe = ref(false)

let handleOnline = () => {
  if skipProbe.contents {
    updateStatus(true, ~reason=Healthy)
  } else {
    Console.info("NetworkStatus: Browser reported ONLINE, probing...")
    let _ = probe()
  }
}

let handleOffline = () => {
  // If browser says we are offline, we usually trust it for immediate UI fallback,
  // but we might want to double check if we are on a weird LAN.
  // For now, we trust the browser's "offline" event as a fast-path.
  updateStatus(false, ~reason=BrowserOffline)
}

let intervalId: ref<option<int>> = ref(None)

let initialize = () => {
  currentStatus := navigatorOnLine
  addEventListener("online", handleOnline)
  addEventListener("offline", handleOffline)

  // Initial probe to verify true status
  let _ = probe()

  // Periodic probe if we are offline to recover automatically
  intervalId := Some(ReBindings.Window.setInterval(() => {
        if !currentStatus.contents {
          let _ = probe()
        }
      }, 30000)) // Every 30 seconds if offline

  Console.info2("NetworkStatus: INITIALIZED", {"online": navigatorOnLine})
}

let cleanup = () => {
  removeEventListener("online", handleOnline)
  removeEventListener("offline", handleOffline)
  switch intervalId.contents {
  | Some(id) => ReBindings.Window.clearInterval(id)
  | None => ()
  }
  subscribers := []
}
