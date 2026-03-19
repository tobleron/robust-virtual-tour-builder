open ReBindings

type healthSample = {
  capturedAtMs: float,
  snapshot: HealthApi.healthSnapshot,
}

let maxSamples = 12

let pushSample = (samples: array<healthSample>, sample: healthSample): array<healthSample> => {
  let next = Belt.Array.concat(samples, [sample])
  let len = next->Array.length
  if len > maxSamples {
    Belt.Array.slice(next, ~offset=len - maxSamples, ~len=maxSamples)
  } else {
    next
  }
}

let statusClass = (status: string) => {
  switch status {
  | "ok" => "settings-health-pill settings-health-pill-ok"
  | "degraded" => "settings-health-pill settings-health-pill-warn"
  | _ => "settings-health-pill settings-health-pill-error"
  }
}

@react.component
let make = () => {
  let (samples, setSamples) = React.useState(_ => [])
  let (isLoading, setIsLoading) = React.useState(_ => false)
  let (errorMsg, setErrorMsg) = React.useState(_ => None)

  let refresh = React.useCallback0(() => {
    setIsLoading(_ => true)
    HealthApi.fetchHealth()
    ->Promise.then(result => {
      switch result {
      | Ok(snapshot) =>
        setErrorMsg(_ => None)
        setSamples(prev => pushSample(prev, {capturedAtMs: Date.now(), snapshot}))
      | Error(msg) => setErrorMsg(_ => Some(msg))
      }
      setIsLoading(_ => false)
      Promise.resolve()
    })
    ->ignore
  })

  React.useEffect0(() => {
    refresh()
    let intervalId = Window.setInterval(() => refresh(), 10000)
    Some(() => Window.clearInterval(intervalId))
  })

  let latest = samples->Belt.Array.getBy(_ => true)
  let activeTrend =
    samples
    ->Belt.Array.map(sample => sample.snapshot.runtime.activeSessions->Belt.Int.toString)
    ->Array.joinUnsafe("  ")
  let cacheTrend =
    samples
    ->Belt.Array.map(sample => Float.toFixed(sample.snapshot.cache.hitRate, ~digits=0) ++ "%")
    ->Array.joinUnsafe("  ")

  <div className="settings-health-wrap">
    <div className="settings-health-head">
      <div className="settings-field-label"> {React.string("System Health")} </div>
      <button
        className="modal-btn-premium settings-health-refresh"
        disabled={isLoading}
        onClick={_ => refresh()}
      >
        <span>
          {React.string(
            if isLoading {
              "Refreshing..."
            } else {
              "Refresh"
            },
          )}
        </span>
      </button>
    </div>

    {switch latest {
    | Some(sample) =>
      <div className="settings-health-grid">
        <div className="settings-health-card">
          <div className="settings-health-card-label"> {React.string("Overall")} </div>
          <div className={statusClass(sample.snapshot.status)}>
            {React.string(sample.snapshot.status->String.toUpperCase)}
          </div>
          {switch sample.snapshot.details {
          | Some(details) => <div className="settings-health-note"> {React.string(details)} </div>
          | None => React.null
          }}
        </div>

        <div className="settings-health-card">
          <div className="settings-health-card-label"> {React.string("Runtime")} </div>
          <div className="settings-health-value">
            {React.string(Belt.Int.toString(sample.snapshot.runtime.activeSessions))}
          </div>
          <div className="settings-health-note"> {React.string("active sessions")} </div>
        </div>

        <div className="settings-health-card">
          <div className="settings-health-card-label"> {React.string("Cache")} </div>
          <div className="settings-health-value">
            {React.string(Float.toFixed(sample.snapshot.cache.hitRate, ~digits=1) ++ "%")}
          </div>
          <div className="settings-health-note">
            {React.string(
              "hits " ++
              Belt.Int.toString(sample.snapshot.cache.hits) ++
              " / misses " ++
              Belt.Int.toString(sample.snapshot.cache.misses),
            )}
          </div>
        </div>

        <div className="settings-health-card settings-health-card-full">
          <div className="settings-health-card-label"> {React.string("Storage")} </div>
          <div className="settings-health-note">
            {React.string("DB: " ++ sample.snapshot.disk.databaseDir)}
          </div>
          <div className="settings-health-note">
            {React.string("Cache: " ++ sample.snapshot.disk.cacheDir)}
          </div>
        </div>
      </div>
    | None =>
      <div className="settings-health-empty">
        {React.string(
          if isLoading {
            "Collecting health sample..."
          } else {
            "No health data yet."
          },
        )}
      </div>
    }}

    {switch errorMsg {
    | Some(msg) => <div className="settings-health-error"> {React.string(msg)} </div>
    | None => React.null
    }}

    <div className="settings-health-trends-grid">
      <div className="settings-health-trend-card">
        <span className="settings-health-trend-label"> {React.string("Active sessions")} </span>
        <span className="settings-health-trend-values"> {React.string(activeTrend)} </span>
      </div>
      <div className="settings-health-trend-card">
        <span className="settings-health-trend-label"> {React.string("Cache hit rate")} </span>
        <span className="settings-health-trend-values"> {React.string(cacheTrend)} </span>
      </div>
    </div>
  </div>
}
