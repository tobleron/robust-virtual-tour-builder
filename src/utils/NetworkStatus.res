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

// --- Public API ---
let isOnline = (): bool => currentStatus.contents

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

let forceStatus = (online: bool) => {
  if currentStatus.contents !== online {
    currentStatus := online
    if online {
      Console.info("NetworkStatus: NETWORK_ONLINE")
      EventBus.dispatch(NetworkStatusChanged(true))
    } else {
      Console.warn("NetworkStatus: NETWORK_OFFLINE")
      EventBus.dispatch(NetworkStatusChanged(false))
    }
    notifySubscribers(online)
  }
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
    let online = WebApiBindings.Fetch.ok(res)
    forceStatus(online)
    online
  } catch {
  | _ =>
    // If navigator says we are online but fetch fails, we ARE offline (from app perspective)
    forceStatus(false)
    false
  }
}

let handleOnline = () => {
  Console.info("NetworkStatus: Browser reported ONLINE, probing...")
  let _ = probe()
}

let handleOffline = () => {
  // If browser says we are offline, we usually trust it for immediate UI fallback,
  // but we might want to double check if we are on a weird LAN.
  // For now, we trust the browser's "offline" event as a fast-path.
  forceStatus(false)
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
