# Task 1454: Exporter XHR Network Resilience

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 2.3  
**Phase**: 2 (API Layer)  
**Depends on**: 1449 (NetworkStatus module)  
**Blocks**: None

---

## Objective
Add network resilience to the Exporter's raw XHR upload function, which currently bypasses the entire CircuitBreaker/Retry stack.

## Problem
**Location**: `src/systems/Exporter.res` lines 46-111 (`uploadAndProcessRaw`)

The export function uses raw `XMLHttpRequest` via `%raw` for upload progress tracking. This choice is deliberate (XHR provides upload progress events that `fetch` doesn't natively support), but it completely bypasses:
- `AuthenticatedClient` (no auth header management)
- `CircuitBreaker` (no failure tracking)
- `Retry` module (no retry on transient failures)

If the network drops during export:
- XHR fires `onerror` with generic "Network Error - Check Backend Connection"
- No retry attempt
- No circuit breaker recording
- The export just fails hard

## Implementation

### 1. Add offline pre-check before XHR
Inside the `uploadAndProcessRaw` raw JS function, add a check:

```javascript
// At the top of the function, before creating XHR:
if (!navigator.onLine) {
  return Promise.reject(new Error("NetworkOffline: You appear to be offline"));
}
```

### 2. Record XHR outcomes in CircuitBreaker
In the ReScript wrapper that calls `uploadAndProcessRaw`, record success/failure:

```rescript
// After successful XHR:
CircuitBreaker.recordSuccess(AuthenticatedClient.circuitBreaker)

// After failed XHR:
CircuitBreaker.recordFailure(AuthenticatedClient.circuitBreaker)
```

Note: This requires `AuthenticatedClient.circuitBreaker` to be exposed or a shared circuit breaker instance.

### 3. Improve error classification in XHR `onerror`
Replace the generic error message in the `%raw` block:

```javascript
xhr.onerror = () => {
  if (!navigator.onLine) {
    reject(new Error("NetworkOffline: You appear to be offline. Please check your connection and try again."));
  } else {
    reject(new Error("NetworkError: Export upload failed. The backend may be unreachable."));
  }
};

xhr.ontimeout = () => {
  reject(new Error("TimeoutError: Export upload timed out after 5 minutes. Try with fewer scenes or a faster connection."));
};
```

### 4. Add retry wrapper at the ReScript level
Wrap the `uploadAndProcessRaw` call in the `exportTour` function with a simple retry for transient network errors:

```rescript
// In exportTour, where uploadAndProcessRaw is called:
let uploadWithRetry = async (~maxRetries=2) => {
  let rec attempt = async (retryCount) => {
    try {
      await uploadAndProcessRaw(formData, progress, Constants.backendUrl, ~signal, ~token=finalToken)
    } catch {
    | exn =>
      let (msg, _) = Logger.getErrorDetails(exn)
      if retryCount < maxRetries && !String.includes(msg, "NetworkOffline") && !String.includes(msg, "AbortError") {
        Logger.warn(
          ~module_="Exporter",
          ~message="EXPORT_RETRY",
          ~data=Some(Logger.castToJson({"attempt": retryCount + 1, "error": msg})),
          (),
        )
        progress(0.0, 100.0, "Retrying export upload...")
        // Wait 2 seconds before retry
        let _ = await Promise.make((resolve, _) => {
          let _ = setTimeout(() => resolve(), 2000)
        })
        await attempt(retryCount + 1)
      } else {
        raise(exn) // Re-throw if exhausted
      }
    }
  }
  await attempt(0)
}
```

## Files to Modify

| File | Change |
|------|--------|
| `src/systems/Exporter.res` | Add offline pre-check in `%raw`, improve error messages, add retry wrapper, record CB outcomes |

## Acceptance Criteria

- [ ] XHR pre-checks `navigator.onLine` before starting
- [ ] Distinct error messages for offline vs network error vs timeout
- [ ] XHR success/failure recorded in CircuitBreaker
- [ ] Transient network failures trigger up to 2 retries
- [ ] `NetworkOffline` and `AbortError` errors are NOT retried
- [ ] Progress callback updated during retry ("Retrying export upload...")
- [ ] Zero compiler warnings
