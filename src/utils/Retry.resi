/* src/utils/Retry.resi */

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

let defaultConfig: config

let defaultShouldRetry: string => bool

let execute: (
  ~fn: (~signal: ReBindings.AbortSignal.t) => Promise.t<result<'a, string>>,
  ~signal: ReBindings.AbortSignal.t,
  ~config: config=?,
  ~shouldRetry: string => bool=?,
  ~onRetry: (int, string, int) => unit=?,
) => Promise.t<retryResult<'a>>
