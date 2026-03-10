let calculateDelay = (
  ~attempt: int,
  ~initialDelayMs: int,
  ~maxDelayMs: int,
  ~backoffMultiplier: float,
  ~jitter: bool,
): int => {
  let baseDelay = Float.toInt(
    Float.fromInt(initialDelayMs) *. Math.pow(backoffMultiplier, ~exp=Float.fromInt(attempt - 1)),
  )
  let cappedBase = Math.Int.min(baseDelay, maxDelayMs)

  if jitter {
    let jitterFactor = 0.8 +. Math.random() *. 0.4
    let jittered = Float.toInt(Float.fromInt(cappedBase) *. jitterFactor)
    let nonNegative = if jittered < 0 {
      0
    } else {
      jittered
    }
    Math.Int.min(nonNegative, maxDelayMs)
  } else {
    cappedBase
  }
}

let computeDelay = (
  ~error: string,
  ~attempt: int,
  ~getDelay: option<(string, int) => option<int>>,
  ~calculateDelay: int => int,
): int => {
  let fromRetryAfter = RetryClassification.retryAfterDelayMs(error)

  switch fromRetryAfter {
  | Some(delay) => delay
  | None =>
    switch getDelay {
    | Some(f) =>
      switch f(error, attempt) {
      | Some(delay) => delay
      | None => calculateDelay(attempt)
      }
    | None => calculateDelay(attempt)
    }
  }
}
