/* src/utils/Retry.res */

type config = {
  maxRetries: int,
  initialDelayMs: int,
  maxDelayMs: int,
  backoffMultiplier: float,
  jitter: bool,
  totalDeadlineMs: int,
}

type budgetConfig = {
  windowMs: int,
  maxRetriesPerWindow: int,
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
  totalDeadlineMs: 0,
}

let defaultBudgetConfig = {
  windowMs: 60000,
  maxRetriesPerWindow: 100,
}

type budgetState = {windowStartMs: float, usedRetries: int}
let retryBudgets = ref(Belt.Map.String.empty)

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

let parseRetryAfterSeconds: string => option<int> = %raw(`
  (error) => {
    const fromRateLimited = /RateLimited:\s*(\d+)/i.exec(error);
    if (fromRateLimited) {
      const parsed = Number.parseInt(fromRateLimited[1], 10);
      return Number.isNaN(parsed) ? undefined : parsed;
    }
    const fromRetryAfter = /Retry-After:\s*(\d+)/i.exec(error);
    if (fromRetryAfter) {
      const parsed = Number.parseInt(fromRetryAfter[1], 10);
      return Number.isNaN(parsed) ? undefined : parsed;
    }
    return undefined;
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

let hasDeadline = (config: config): bool => config.totalDeadlineMs > 0

let computeDelay = (error, attempt, config, getDelay) => {
  let fromRetryAfter =
    parseRetryAfterSeconds(error)->Option.map(seconds => Math.Int.max(0, seconds * 1000))

  switch fromRetryAfter {
  | Some(delay) => delay
  | None =>
    switch getDelay {
    | Some(f) =>
      switch f(error, attempt) {
      | Some(d) => d
      | None => calculateDelay(attempt, config)
      }
    | None => calculateDelay(attempt, config)
    }
  }
}

let checkAndConsumeBudget = (
  budgetKey: option<string>,
  budgetCfg: budgetConfig,
): bool => {
  switch budgetKey {
  | None => true
  | Some(key) =>
    let now = Date.now()
    switch retryBudgets.contents->Belt.Map.String.get(key) {
    | None =>
      retryBudgets := retryBudgets.contents->Belt.Map.String.set(key, {
        windowStartMs: now,
        usedRetries: 1,
      })
      true
    | Some(state) =>
      let withinWindow = now -. state.windowStartMs <= Int.toFloat(budgetCfg.windowMs)
      if withinWindow {
        if state.usedRetries >= budgetCfg.maxRetriesPerWindow {
          false
        } else {
          retryBudgets := retryBudgets.contents->Belt.Map.String.set(key, {
            ...state,
            usedRetries: state.usedRetries + 1,
          })
          true
        }
      } else {
        retryBudgets := retryBudgets.contents->Belt.Map.String.set(key, {
          windowStartMs: now,
          usedRetries: 1,
        })
        true
      }
    }
  }
}

let rec loop = async (
  fn,
  signal,
  config,
  shouldRetry,
  onRetry,
  getDelay,
  isCircuitOpen,
  budgetKey,
  budgetCfg,
  startedAt,
  attempt,
) => {
  if aborted(signal) {
    Exhausted("AbortError")
  } else if isCircuitOpen->Option.map(cb => cb())->Option.getOr(false) {
    Exhausted("CircuitOpen")
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
      } else if !checkAndConsumeBudget(budgetKey, budgetCfg) {
        Exhausted("RetryBudgetExhausted")
      } else {
        let delay = computeDelay(err, attempt, config, getDelay)

        if hasDeadline(config) {
          let elapsed = Date.now() -. startedAt
          let remaining = config.totalDeadlineMs->Int.toFloat -. elapsed
          if Float.fromInt(delay) > remaining {
            Exhausted("DeadlineExceeded")
          } else {
            switch onRetry {
            | Some(cb) => cb(attempt, err, delay)
            | None => ()
            }

            Logger.debug(
              ~module_="Retry",
              ~message="RETRY_ATTEMPT",
              ~data=Some(Logger.castToJson({
                "attempt": attempt,
                "delayMs": delay,
                "error": err,
                "elapsedMs": elapsed,
                "remainingDeadlineMs": remaining,
              })),
              (),
            )

            // Abort-aware delay wait. Do not retry if cancelled while backing off.
            let canContinue = await waitForDelay(signal, delay)
            if canContinue {
              await loop(
                fn,
                signal,
                config,
                shouldRetry,
                onRetry,
                getDelay,
                isCircuitOpen,
                budgetKey,
                budgetCfg,
                startedAt,
                attempt + 1,
              )
            } else {
              Exhausted("AbortError")
            }
          }
        } else {
          switch onRetry {
          | Some(cb) => cb(attempt, err, delay)
          | None => ()
          }

          Logger.debug(
            ~module_="Retry",
            ~message="RETRY_ATTEMPT",
            ~data=Some(Logger.castToJson({
              "attempt": attempt,
              "delayMs": delay,
              "error": err,
            })),
            (),
          )

          // Abort-aware delay wait. Do not retry if cancelled while backing off.
          let canContinue = await waitForDelay(signal, delay)
          if canContinue {
            await loop(
              fn,
              signal,
              config,
              shouldRetry,
              onRetry,
              getDelay,
              isCircuitOpen,
              budgetKey,
              budgetCfg,
              startedAt,
              attempt + 1,
            )
          } else {
            Exhausted("AbortError")
          }
        }
      }
    }
  }
}

let execute = (
  ~fn,
  ~signal,
  ~config=?,
  ~shouldRetry=?,
  ~onRetry=?,
  ~getDelay=?,
  ~isCircuitOpen=?,
  ~budgetKey=?,
  ~budgetConfig=?,
) => {
  let cfg = Option.getOr(config, defaultConfig)
  let should = Option.getOr(shouldRetry, defaultShouldRetry)
  let retryBudgetCfg = Option.getOr(budgetConfig, defaultBudgetConfig)

  loop(
    fn,
    signal,
    cfg,
    should,
    onRetry,
    getDelay,
    isCircuitOpen,
    budgetKey,
    retryBudgetCfg,
    Date.now(),
    1,
  )
}
