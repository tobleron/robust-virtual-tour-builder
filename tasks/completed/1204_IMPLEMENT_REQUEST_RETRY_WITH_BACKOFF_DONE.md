# TASK: Implement Request Retry with Exponential Backoff

**Priority**: 🟢 Low
**Estimated Effort**: Small (1-2 hours)
**Dependencies**: 1201 (Circuit Breaker)
**Related Tasks**: 1201, 1203

---

## 1. Problem Statement

The current `RequestQueue.res` does not retry failed requests:

- **Transient Failures**: Network hiccups cause permanent failures.
- **No Recovery**: Users must manually retry failed operations.
- **Server Overload**: Without backoff, retries can overwhelm recovering servers.

---

## 2. Technical Requirements

### A. Create Retry Utility

**File**: `src/utils/Retry.res` (new)

```rescript
type config = {
  maxRetries: int,           // Default: 3
  initialDelayMs: int,       // Default: 1000
  maxDelayMs: int,           // Default: 30000
  backoffMultiplier: float,  // Default: 2.0
  jitter: bool,              // Default: true (add randomness)
}

type retryResult<'a> =
  | Success('a, int)         // Result and attempt count
  | Exhausted(string)        // Final error after all retries

let execute: (
  ~fn: (~signal: BrowserBindings.AbortController.signal) => Promise.t<result<'a, string>>,
  ~signal: BrowserBindings.AbortController.signal,
  ~config: config=?,
  ~shouldRetry: string => bool=?,  // Optional: decide if error is retryable
  ~onRetry: (int, string, int) => unit=?,  // (attempt, error, nextDelayMs)
) => Promise.t<retryResult<'a>>
```

### B. Retry Logic

```rescript
let defaultShouldRetry = (error: string) => {
  // Retry on network errors and 5xx, but not 4xx
  String.includes(error, "NetworkError") ||
  String.includes(error, "fetch failed") ||
  String.includes(error, "500") ||
  String.includes(error, "502") ||
  String.includes(error, "503") ||
  String.includes(error, "504")
}

let calculateDelay = (attempt, config) => {
  let baseDelay = Float.toInt(
    Float.fromInt(config.initialDelayMs) *. 
    Math.pow(config.backoffMultiplier, Float.fromInt(attempt - 1))
  )
  let capped = Math.Int.min(baseDelay, config.maxDelayMs)
  
  if config.jitter {
    // Add 0-20% jitter
    let jitterRange = Float.fromInt(capped) *. 0.2
    capped + Float.toInt(Math.random() *. jitterRange)
  } else {
    capped
  }
}
```

### C. Integration with RequestQueue

**File**: `src/utils/RequestQueue.res`

Update `schedule` to optionally retry:

```rescript
let scheduleWithRetry = (
  ~task: unit => Promise.t<result<'a, string>>,
  ~retryConfig: Retry.config=?,
) => {
  schedule(() => {
    Retry.execute(
      ~fn=task,
      ~config=?retryConfig,
      ~onRetry=(attempt, error, delay) => {
        Logger.debug(
          ~module_="RequestQueue",
          ~message="RETRY_SCHEDULED",
          ~data=Logger.castToJson({
            "attempt": attempt,
            "error": error,
            "delayMs": delay,
          }),
          ()
        )
      },
    )
  })
}
```

### D. User Feedback During Retry

```rescript
~onRetry=(attempt, error, delay) => {
  if attempt > 1 {
    EventBus.dispatch(ShowNotification(
      `Retrying... (attempt ${Belt.Int.toString(attempt)})`,
      #Info,
      None
    ))
  }
}
```

---

## 3. JSON Encoding Standard

All logging MUST use `rescript-json-combinators`:

```rescript
Logger.debug(
  ~module_="Retry",
  ~message="RETRY_ATTEMPT",
  ~data=Logger.castToJson({
    "attempt": attempt,
    "maxRetries": config.maxRetries,
    "delayMs": delay,
    "error": truncateError(error, 100),
  }),
  ()
)
```

---

## 4. Verification Criteria

- [ ] Failed request retries up to 3 times with exponential backoff.
- [ ] Delay doubles between retries (1s → 2s → 4s).
- [ ] Jitter adds randomness to prevent thundering herd.
- [ ] 4xx errors do not trigger retry (client error).
- [ ] User sees retry notification on attempt 2+.
- [ ] All JSON encoding uses `rescript-json-combinators`.
- [ ] `npm run build` completes with zero warnings.

---

## 5. File Checklist

- [ ] `src/utils/Retry.res` - New module
- [ ] `src/utils/Retry.resi` - Interface file
- [ ] `src/utils/RequestQueue.res` - Add `scheduleWithRetry`
- [ ] `src/systems/Api/AuthenticatedClient.res` - Use retry for critical calls
- [ ] `tests/unit/Retry_v.test.res` - Unit tests
- [ ] `MAP.md` - Add new module entry

---

## 6. References

- [Exponential Backoff (AWS)](https://docs.aws.amazon.com/general/latest/gr/api-retries.html)
- `src/utils/RequestQueue.res`
- `src/systems/Api/AuthenticatedClient.res`
