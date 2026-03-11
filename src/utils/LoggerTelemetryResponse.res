/* src/utils/LoggerTelemetryResponse.res */

open ReBindings

type responseValidation =
  | TelemetryResponseOk
  | TelemetryResponseRateLimited({status: int, retryMs: float})
  | TelemetryResponseHttpError(int)

let parseRetryAfterSeconds = (raw: option<string>): option<float> =>
  raw->Option.flatMap(raw => {
    switch Belt.Int.fromString(raw) {
    | Some(seconds) if seconds > 0 => Some(Belt.Int.toFloat(seconds) *. 1000.0)
    | _ => None
    }
  })

let headerRetryAfterMs = (headers, key: string): option<float> =>
  WebApiBindings.Fetch.getHeader(headers, key)
  ->Nullable.toOption
  ->parseRetryAfterSeconds

let parseRetryAfterHeaderMs = (res: Fetch.response): option<float> => {
  let headers = WebApiBindings.Fetch.headers(res)
  let direct = headerRetryAfterMs(headers, "retry-after")
  let xRate = headerRetryAfterMs(headers, "x-ratelimit-after")
  direct->Option.orElse(xRate)
}

let classifyTelemetryResponse = (
  ~parseRetryAfterHeaderMs: Fetch.response => option<float>,
  res: Fetch.response,
): responseValidation => {
  let status = WebApiBindings.Fetch.status(res)
  if status == 429 {
    let retryMs = parseRetryAfterHeaderMs(res)->Option.getOr(Constants.Telemetry.suspendDurationMs)
    TelemetryResponseRateLimited({status, retryMs})
  } else if status >= 400 {
    TelemetryResponseHttpError(status)
  } else {
    TelemetryResponseOk
  }
}

let validationToPromise = (
  ~suspendTelemetryForMs: float => unit,
  validation: responseValidation,
): Promise.t<unit> => {
  switch validation {
  | TelemetryResponseRateLimited({status, retryMs}) =>
    suspendTelemetryForMs(retryMs)
    Promise.reject(Failure(`TelemetryRateLimited:${Belt.Int.toString(status)}`))
  | TelemetryResponseHttpError(status) =>
    Promise.reject(Failure(`TelemetryHttpError:${Belt.Int.toString(status)}`))
  | TelemetryResponseOk => Promise.resolve()
  }
}

let validateTelemetryResponse = (
  ~parseRetryAfterHeaderMs: Fetch.response => option<float>,
  ~suspendTelemetryForMs: float => unit,
  res: Fetch.response,
): Promise.t<unit> =>
  validationToPromise(
    ~suspendTelemetryForMs,
    classifyTelemetryResponse(~parseRetryAfterHeaderMs, res),
  )
