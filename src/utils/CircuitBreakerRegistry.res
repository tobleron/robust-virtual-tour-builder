/* @efficiency-role: infra-adapter */

type domain =
  | Default
  | Upload
  | Export
  | Geocoding
  | Project
  | Telemetry

type breakerEntry = {
  breaker: CircuitBreaker.t,
  bulkheadLimit: int,
}

type snapshot = {
  domain: string,
  state: string,
  inFlight: int,
  bulkheadLimit: int,
}

let domainToKey = d =>
  switch d {
  | Default => "default"
  | Upload => "upload"
  | Export => "export"
  | Geocoding => "geocoding"
  | Project => "project"
  | Telemetry => "telemetry"
  }

let keyToDomain = key =>
  switch key {
  | "upload" => Upload
  | "export" => Export
  | "geocoding" => Geocoding
  | "project" => Project
  | "telemetry" => Telemetry
  | _ => Default
  }

let registry: Dict.t<breakerEntry> = Dict.make()
let inFlightByDomain: Dict.t<int> = Dict.make()

type domainConfig = (CircuitBreaker.config, int)

let defaultConfigForDomain = (d: domain): domainConfig =>
  switch d {
  | Upload =>
    ({failureThreshold: 6, successThreshold: 2, timeout: 30000, onStateTransition: None, onCircuitOpen: None}: CircuitBreaker.config, 4)
  | Export =>
    ({failureThreshold: 4, successThreshold: 2, timeout: 45000, onStateTransition: None, onCircuitOpen: None}: CircuitBreaker.config, 2)
  | Geocoding =>
    ({failureThreshold: 3, successThreshold: 1, timeout: 20000, onStateTransition: None, onCircuitOpen: None}: CircuitBreaker.config, 2)
  | Project =>
    ({failureThreshold: 8, successThreshold: 2, timeout: 30000, onStateTransition: None, onCircuitOpen: None}: CircuitBreaker.config, 3)
  | Telemetry =>
    ({failureThreshold: 8, successThreshold: 1, timeout: 10000, onStateTransition: None, onCircuitOpen: None}: CircuitBreaker.config, 2)
  | Default =>
    ({failureThreshold: 5, successThreshold: 2, timeout: 30000, onStateTransition: None, onCircuitOpen: None}: CircuitBreaker.config, 6)
  }

let ensureDomainEntry = (d: domain): breakerEntry => {
  let key = domainToKey(d)
  switch Dict.get(registry, key) {
  | Some(entry) => entry
  | None =>
    let (config, bulkheadLimit) = defaultConfigForDomain(d)
    let key = domainToKey(d)
    let instrumentedConfig: CircuitBreaker.config = {
      ...config,
      onStateTransition: Some((fromState, toState) => {
        Logger.info(
          ~module_="CircuitBreakerRegistry",
          ~message="CIRCUIT_STATE_TRANSITION",
          ~data=Logger.castToJson({
            "domain": key,
            "from": CircuitBreaker.stateToString(fromState),
            "to": CircuitBreaker.stateToString(toState),
          }),
          (),
        )
      }),
      onCircuitOpen: Some(() => {
        NotificationManager.dispatch({
          id: "circuit-open-" ++ key,
          importance: Warning,
          context: Operation("network"),
          message: "Service temporarily unavailable.",
          details: Some("Circuit opened for " ++ key ++ " domain."),
          action: None,
          duration: 8000,
          dismissible: true,
          createdAt: Date.now(),
        })
      }),
    }
    let entry: breakerEntry = {breaker: CircuitBreaker.make(~config=instrumentedConfig), bulkheadLimit}
    Dict.set(registry, key, entry)
    Dict.set(inFlightByDomain, key, 0)
    entry
  }
}

let getBreaker = (d: domain): CircuitBreaker.t => ensureDomainEntry(d).breaker

let getBulkheadLimit = (d: domain): int => ensureDomainEntry(d).bulkheadLimit

let tryAcquireBulkhead = (d: domain): bool => {
  let key = domainToKey(d)
  let entry = ensureDomainEntry(d)
  let current = Dict.get(inFlightByDomain, key)->Option.getOr(0)
  if current >= entry.bulkheadLimit {
    false
  } else {
    Dict.set(inFlightByDomain, key, current + 1)
    true
  }
}

let releaseBulkhead = (d: domain) => {
  let key = domainToKey(d)
  let current = Dict.get(inFlightByDomain, key)->Option.getOr(0)
  Dict.set(inFlightByDomain, key, if current > 0 {current - 1} else {0})
}

let getDomainState = (d: domain): CircuitBreaker.state => {
  let breaker = getBreaker(d)
  CircuitBreaker.getState(breaker)
}

let getSnapshots = (): array<snapshot> => {
  Dict.toArray(registry)
  ->Belt.Array.map(((key, entry)) => {
    let inFlight = Dict.get(inFlightByDomain, key)->Option.getOr(0)
    {
      domain: key,
      state: CircuitBreaker.getState(entry.breaker)->CircuitBreaker.stateToString,
      inFlight,
      bulkheadLimit: entry.bulkheadLimit,
    }
  })
}

let resolveDomainForUrl = (url: string): domain => {
  if String.includes(url, "/api/geocoding") {
    Geocoding
  } else if String.includes(url, "/api/media") {
    Upload
  } else if String.includes(url, "/api/project/create-tour-package") {
    Export
  } else if String.includes(url, "/api/project") {
    Project
  } else if String.includes(url, "/api/telemetry") {
    Telemetry
  } else {
    Default
  }
}
