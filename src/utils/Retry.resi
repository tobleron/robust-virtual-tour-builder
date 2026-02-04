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

let execute: (
  ~fn: (~signal: ReBindings.AbortController.signal) => Promise.t<result<'a, string>>,
  ~signal: ReBindings.AbortController.signal,
  ~config: config=?,
  ~shouldRetry: string => bool=?,
  ~onRetry: (int, string, int) => unit=?,
) => Promise.t<retryResult<'a>>
