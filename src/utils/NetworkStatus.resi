/* src/utils/NetworkStatus.resi */

type statusPhase =
  | HealthyPhase
  | BrowserOfflinePhase
  | RecoveringPhase
  | RateLimitedPhase

type statusReason =
  | BrowserOffline
  | ProbeNetworkFailure
  | BackendRateLimited(option<int>)
  | BackendUnavailable(int, string)
  | TransportFailure(string)
  | Healthy

type statusSnapshot = {
  online: bool,
  phase: statusPhase,
  reason: statusReason,
  message: string,
  attempt: int,
  retryDelayMs: option<int>,
  nextRetryAtMs: option<float>,
  lastHealthyAtMs: option<float>,
}

let isOnline: unit => bool
let getSnapshot: unit => statusSnapshot
let probe: (~isInitial: bool=?) => Promise.t<bool>
let probeNow: unit => Promise.t<bool>
let subscribe: (bool => unit) => unit => unit
let subscribeSnapshot: (statusSnapshot => unit) => unit => unit
let forceStatus: bool => unit
let reportBackendUnavailable: (~status: int, ~statusText: string) => unit
let reportProbeFailure: unit => unit
let reportRateLimited: (~retryAfterSeconds: int) => unit
let reportTransportFailure: (~message: string) => unit
let reportRequestSuccess: unit => unit
let skipProbe: ref<bool>
let initialize: unit => unit
let cleanup: unit => unit
