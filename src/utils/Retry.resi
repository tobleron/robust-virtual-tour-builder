/* src/utils/Retry.resi */

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

let defaultConfig: config

let defaultShouldRetry: string => bool

let execute: (
  ~fn: (~signal: ReBindings.AbortSignal.t) => Promise.t<result<'a, string>>,
  ~signal: ReBindings.AbortSignal.t,
  ~config: config=?,
  ~shouldRetry: string => bool=?,
  ~onRetry: (int, string, int) => unit=?,
  ~getDelay: (string, int) => option<int>=?,
  ~isCircuitOpen: (unit => bool)=?,
  ~budgetKey: string=?,
  ~budgetConfig: budgetConfig=?,
) => Promise.t<retryResult<'a>>
