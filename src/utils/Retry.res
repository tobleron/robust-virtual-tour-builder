/* src/utils/Retry.res */

type config = {
  maxRetries: int,
  initialDelayMs: int,
  maxDelayMs: int,
  backoffMultiplier: float,
  jitter: bool,
}

type retryResult<'a> =
  | Success('a, int)
  | Exhausted(string)

let defaultConfig = {
  maxRetries: 3,
  initialDelayMs: 1000,
  maxDelayMs: 30000,
  backoffMultiplier: 2.0,
  jitter: true,
}

let calculateDelay = (attempt, config) => {
  let baseDelay = Float.toInt(
    Float.fromInt(config.initialDelayMs) *.
    Math.pow(config.backoffMultiplier, ~exp=Float.fromInt(attempt - 1)),
  )
  let capped = Math.Int.min(baseDelay, config.maxDelayMs)

  if config.jitter {
    let jitterRange = Float.fromInt(capped) *. 0.2
    capped + Float.toInt(Math.random() *. jitterRange)
  } else {
    capped
  }
}

let defaultShouldRetry = (error: string) => {
  String.includes(error, "NetworkError") ||
  String.includes(error, "fetch failed") ||
  String.includes(error, "Failed to fetch") ||
  String.includes(error, "Network request failed") ||
  String.includes(error, "connection refused") ||
  String.includes(error, "500") ||
  String.includes(error, "502") ||
  String.includes(error, "503") ||
  String.includes(error, "504")
}

@get external aborted: ReBindings.AbortController.signal => bool = "aborted"

let rec loop = async (fn, signal, config, shouldRetry, onRetry, attempt) => {
  if aborted(signal) {
    Exhausted("Aborted")
  } else {
    let result = await fn(~signal)

    switch result {
    | Ok(val) => Success(val, attempt)
    | Error(err) =>
      if attempt > config.maxRetries {
        Exhausted(err)
      } else if !shouldRetry(err) {
        Exhausted(err)
      } else {
        let delay = calculateDelay(attempt, config)

        switch onRetry {
        | Some(cb) => cb(attempt, err, delay)
        | None => ()
        }

        // Wait for delay
        let _ = await Promise.make((resolve, _) => {
          let _ = ReBindings.Window.setTimeout(() => resolve(), delay)
        })

        await loop(fn, signal, config, shouldRetry, onRetry, attempt + 1)
      }
    }
  }
}

let execute = (~fn, ~signal, ~config=?, ~shouldRetry=?, ~onRetry=?) => {
  let cfg = Option.getOr(config, defaultConfig)
  let should = Option.getOr(shouldRetry, defaultShouldRetry)

  loop(fn, signal, cfg, should, onRetry, 1)
}
