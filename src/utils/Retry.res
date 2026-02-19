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
  let cappedBase = Math.Int.min(baseDelay, config.maxDelayMs)

  if config.jitter {
    // Bound jitter to +/-20% while never exceeding maxDelayMs.
    let jitterFactor = 0.8 +. Math.random() *. 0.4
    let jittered = Float.toInt(Float.fromInt(cappedBase) *. jitterFactor)
    let nonNegative = if jittered < 0 {
      0
    } else {
      jittered
    }
    Math.Int.min(nonNegative, config.maxDelayMs)
  } else {
    cappedBase
  }
}

type retryClass =
  | Retryable
  | NonRetryable
  | Aborted

let parseHttpStatusCode: string => option<int> = %raw(`
  (error) => {
    const match = /HttpError:\s*Status\s*(\d+)/i.exec(error);
    if (!match) return undefined;
    const parsed = Number.parseInt(match[1], 10);
    return Number.isNaN(parsed) ? undefined : parsed;
  }
`)

let isAbortError = (error: string): bool => {
  String.includes(error, "AbortError") || String.includes(error, "aborted")
}

let isRetryableStatus = (status: int): bool => {
  switch status {
  | 408
  | 425
  | 429
  | 500
  | 502
  | 503
  | 504 => true
  | _ => false
  }
}

let classifyError = (error: string): retryClass => {
  if isAbortError(error) {
    Aborted
  } else {
    switch parseHttpStatusCode(error) {
    | Some(status) =>
      if isRetryableStatus(status) {
        Retryable
      } else {
        NonRetryable
      }
    | None =>
      if (
        String.includes(error, "NetworkError") ||
        String.includes(error, "fetch failed") ||
        String.includes(error, "Failed to fetch") ||
        String.includes(error, "Network request failed") ||
        String.includes(error, "connection refused") ||
        String.includes(error, "ETIMEDOUT") ||
        String.includes(error, "TimeoutError")
      ) {
        Retryable
      } else {
        NonRetryable
      }
    }
  }
}

let defaultShouldRetry = (error: string) => {
  switch classifyError(error) {
  | Retryable => true
  | NonRetryable
  | Aborted => false
  }
}

@get external aborted: ReBindings.AbortSignal.t => bool = "aborted"

let waitForDelay = (signal: ReBindings.AbortSignal.t, delay: int): Promise.t<bool> => {
  Promise.make((resolve, _reject) => {
    if aborted(signal) {
      resolve(false)
    } else {
      let timeoutId = ref(None)
      let done = ref(false)

      let rec onAbort = () => {
        if !done.contents {
          done := true
          switch timeoutId.contents {
          | Some(id) => ReBindings.Window.clearTimeout(id)
          | None => ()
          }
          signal->ReBindings.AbortSignal.removeEventListener("abort", onAbort)
          resolve(false)
        }
      }

      signal->ReBindings.AbortSignal.addEventListener("abort", onAbort)
      let tid = ReBindings.Window.setTimeout(() => {
        if !done.contents {
          done := true
          signal->ReBindings.AbortSignal.removeEventListener("abort", onAbort)
          resolve(true)
        }
      }, delay)

      timeoutId := Some(tid)
    }
  })
}

let rec loop = async (fn, signal, config, shouldRetry, onRetry, getDelay, attempt) => {
  if aborted(signal) {
    Exhausted("AbortError")
  } else {
    let result = await fn(~signal)

    switch result {
    | Ok(val) => Success(val, attempt)
    | Error(err) =>
      if isAbortError(err) {
        Exhausted("AbortError")
      } else if attempt > config.maxRetries {
        Exhausted(err)
      } else if !shouldRetry(err) {
        Exhausted(err)
      } else {
        let delay = switch getDelay {
        | Some(f) =>
          switch f(err, attempt) {
          | Some(d) => d
          | None => calculateDelay(attempt, config)
          }
        | None => calculateDelay(attempt, config)
        }

        switch onRetry {
        | Some(cb) => cb(attempt, err, delay)
        | None => ()
        }

        // Abort-aware delay wait. Do not retry if cancelled while backing off.
        let canContinue = await waitForDelay(signal, delay)
        if canContinue {
          await loop(fn, signal, config, shouldRetry, onRetry, getDelay, attempt + 1)
        } else {
          Exhausted("AbortError")
        }
      }
    }
  }
}

let execute = (~fn, ~signal, ~config=?, ~shouldRetry=?, ~onRetry=?, ~getDelay=?) => {
  let cfg = Option.getOr(config, defaultConfig)
  let should = Option.getOr(shouldRetry, defaultShouldRetry)

  loop(fn, signal, cfg, should, onRetry, getDelay, 1)
}
