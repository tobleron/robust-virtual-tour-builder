/* src/utils/NetworkStatus.resi */

type statusReason =
  | BrowserOffline
  | ProbeNetworkFailure
  | BackendRateLimited(option<int>)
  | BackendUnavailable(int, string)
  | Healthy

type statusSnapshot = {
  online: bool,
  reason: statusReason,
  message: string,
}

let isOnline: unit => bool
let getSnapshot: unit => statusSnapshot
let probe: unit => Promise.t<bool>
let subscribe: (bool => unit) => unit => unit
let forceStatus: bool => unit
let skipProbe: ref<bool>
let initialize: unit => unit
let cleanup: unit => unit
