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

let handleOnline = () => {
  if !currentStatus.contents {
    currentStatus := true
    Logger.info(~module_="NetworkStatus", ~message="NETWORK_ONLINE", ())
    EventBus.dispatch(NetworkStatusChanged(true))
    notifySubscribers(true)
  }
}

let handleOffline = () => {
  if currentStatus.contents {
    currentStatus := false
    Logger.warn(~module_="NetworkStatus", ~message="NETWORK_OFFLINE", ())
    EventBus.dispatch(NetworkStatusChanged(false))
    notifySubscribers(false)
  }
}

let initialize = () => {
  currentStatus := navigatorOnLine
  addEventListener("online", handleOnline)
  addEventListener("offline", handleOffline)
  Logger.info(
    ~module_="NetworkStatus",
    ~message="INITIALIZED",
    ~data=Some(Logger.castToJson({"online": navigatorOnLine})),
    (),
  )
}

let cleanup = () => {
  removeEventListener("online", handleOnline)
  removeEventListener("offline", handleOffline)
  subscribers := []
}
