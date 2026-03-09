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
  RetryTiming.calculateDelay(
    ~attempt,
    ~initialDelayMs=config.initialDelayMs,
    ~maxDelayMs=config.maxDelayMs,
    ~backoffMultiplier=config.backoffMultiplier,
    ~jitter=config.jitter,
  )
}

type retryClass = RetryClassification.retryClass =
  | Retryable
  | NonRetryable
  | Aborted

@warning("-32")
let extractCaptureInt = (error: string, pattern): option<int> =>
  RetryClassification.extractCaptureInt(error, pattern)

@warning("-32")
let parseHttpStatusCode = (error: string): option<int> =>
  extractCaptureInt(error, /HttpError:\s*Status\s*(\d+)/i)

let isAbortError = (error: string): bool => {
  RetryClassification.isAbortError(error)
}

@warning("-32")
let isRetryableStatus = (status: int): bool => {
  RetryClassification.isRetryableStatus(status)
}

@warning("-32")
let classifyError = (error: string): retryClass => {
  RetryClassification.classifyError(error)
}

let defaultShouldRetry = (error: string) => {
  RetryClassification.defaultShouldRetry(error)
}

@get external aborted: ReBindings.AbortSignal.t => bool = "aborted"

let waitForDelay = (signal: ReBindings.AbortSignal.t, delay: int): Promise.t<bool> =>
  RetryDelay.waitForDelay(signal, delay)

let hasDeadline = (config: config): bool => config.totalDeadlineMs > 0

let computeDelay = (error, attempt, config, getDelay) => {
  RetryTiming.computeDelay(
    ~error,
    ~attempt,
    ~getDelay,
    ~calculateDelay=attempt => calculateDelay(attempt, config),
  )
}

let checkAndConsumeBudget = (budgetKey: option<string>, budgetCfg: budgetConfig): bool => {
  switch budgetKey {
  | None => true
  | Some(key) =>
    let now = Date.now()
    switch retryBudgets.contents->Belt.Map.String.get(key) {
    | None =>
      retryBudgets :=
        retryBudgets.contents->Belt.Map.String.set(
          key,
          {
            windowStartMs: now,
            usedRetries: 1,
          },
        )
      true
    | Some(state) =>
      let withinWindow = now -. state.windowStartMs <= Int.toFloat(budgetCfg.windowMs)
      if withinWindow {
        if state.usedRetries >= budgetCfg.maxRetriesPerWindow {
          false
        } else {
          retryBudgets :=
            retryBudgets.contents->Belt.Map.String.set(
              key,
              {
                ...state,
                usedRetries: state.usedRetries + 1,
              },
            )
          true
        }
      } else {
        retryBudgets :=
          retryBudgets.contents->Belt.Map.String.set(
            key,
            {
              windowStartMs: now,
              usedRetries: 1,
            },
          )
        true
      }
    }
  }
}

let getRemainingBudget = (budgetKey: option<string>, budgetCfg: budgetConfig): option<int> => {
  switch budgetKey {
  | None => None
  | Some(key) =>
    let now = Date.now()
    switch retryBudgets.contents->Belt.Map.String.get(key) {
    | None => Some(budgetCfg.maxRetriesPerWindow)
    | Some(state) =>
      let withinWindow = now -. state.windowStartMs <= Int.toFloat(budgetCfg.windowMs)
      if withinWindow {
        Some(Math.Int.max(0, budgetCfg.maxRetriesPerWindow - state.usedRetries))
      } else {
        Some(budgetCfg.maxRetriesPerWindow)
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
          let remainingBudget = getRemainingBudget(budgetKey, budgetCfg)
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
              ~data=Some(
                Logger.castToJson({
                  "attempt": attempt,
                  "delayMs": delay,
                  "error": err,
                  "elapsedMs": elapsed,
                  "remainingDeadlineMs": remaining,
                  "remainingBudget": remainingBudget,
                }),
              ),
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
          let elapsed = Date.now() -. startedAt
          let remainingBudget = getRemainingBudget(budgetKey, budgetCfg)
          switch onRetry {
          | Some(cb) => cb(attempt, err, delay)
          | None => ()
          }

          Logger.debug(
            ~module_="Retry",
            ~message="RETRY_ATTEMPT",
            ~data=Some(
              Logger.castToJson({
                "attempt": attempt,
                "delayMs": delay,
                "error": err,
                "elapsedMs": elapsed,
                "remainingBudget": remainingBudget,
              }),
            ),
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
