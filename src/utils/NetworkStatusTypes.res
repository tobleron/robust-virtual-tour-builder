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

let phaseAllowsRequests = (phase: statusPhase): bool =>
  switch phase {
  | HealthyPhase
  | RateLimitedPhase => true
  | BrowserOfflinePhase
  | RecoveringPhase => false
  }

let phaseMessage = (phase: statusPhase): string =>
  switch phase {
  | HealthyPhase => "Connected."
  | BrowserOfflinePhase => "Connection lost. Working locally until the network returns."
  | RecoveringPhase => "Connection lost. Retrying automatically."
  | RateLimitedPhase => "Server busy. Pausing backend requests before retrying."
  }

let backendRateLimitedSignature = (retryAfter: option<int>): string =>
  switch retryAfter {
  | Some(secs) => "backend-rate-limited:" ++ Belt.Int.toString(secs)
  | None => "backend-rate-limited"
  }

let backendUnavailableSignature = (status: int, statusText: string): string =>
  "backend-unavailable:" ++ Belt.Int.toString(status) ++ ":" ++ statusText

let transportFailureSignature = (message: string): string =>
  "transport-failure:" ++ message

let reasonSignature = (reason: statusReason): string =>
  switch reason {
  | Healthy => "healthy"
  | BrowserOffline => "browser-offline"
  | ProbeNetworkFailure => "probe-network-failure"
  | BackendRateLimited(retryAfter) => backendRateLimitedSignature(retryAfter)
  | BackendUnavailable(status, statusText) => backendUnavailableSignature(status, statusText)
  | TransportFailure(message) => transportFailureSignature(message)
  }

let optionIntEquals = (left: option<int>, right: option<int>): bool =>
  switch (left, right) {
  | (Some(a), Some(b)) => a == b
  | (None, None) => true
  | _ => false
  }

let optionFloatEquals = (left: option<float>, right: option<float>): bool =>
  switch (left, right) {
  | (Some(a), Some(b)) => a == b
  | (None, None) => true
  | _ => false
  }

let intMax = (left: int, right: int): int =>
  if left > right {
    left
  } else {
    right
  }

let intMin = (left: int, right: int): int =>
  if left < right {
    left
  } else {
    right
  }
