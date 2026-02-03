# TASK: Implement Circuit Breaker Pattern for Backend API Calls

**Priority**: 🟡 Medium
**Estimated Effort**: Medium (2-3 hours)
**Dependencies**: None
**Related Tasks**: 1200, 1202

---

## 1. Problem Statement

Currently, backend API calls in `src/systems/Api/AuthenticatedClient.res` and `src/systems/BackendApi.res` do not implement circuit breaker patterns. This means:

- **Cascading Failures**: If the backend is down, every user action triggers a failed request.
- **Resource Exhaustion**: Browser's connection pool can be saturated with pending failed requests.
- **Poor UX**: Users keep clicking, unaware the backend is unavailable.

---

## 2. Technical Requirements

### A. Create Circuit Breaker Module

**File**: `src/utils/CircuitBreaker.res` (new)

```rescript
type state = Closed | Open | HalfOpen

type config = {
  failureThreshold: int,      // Default: 5
  successThreshold: int,      // Default: 2 (for half-open recovery)
  timeout: int,               // Default: 30000ms (open state duration)
}

type t = {
  mutable state: state,
  mutable failureCount: int,
  mutable successCount: int,
  mutable lastFailureTime: option<float>,
  config: config,
}

let make: (~config: config=?) => t
let canExecute: t => bool
let recordSuccess: t => unit
let recordFailure: t => unit
let getState: t => state
```

**Logic**:
- `Closed`: Normal operation, requests pass through.
- `Open`: After `failureThreshold` consecutive failures, reject all requests immediately for `timeout` ms.
- `HalfOpen`: After timeout expires, allow one request to test recovery.

### B. Integrate with Authenticated Client

**File**: `src/systems/Api/AuthenticatedClient.res`

1. Create a module-level circuit breaker instance:
   ```rescript
   let circuitBreaker = CircuitBreaker.make(~config={
     failureThreshold: 5,
     successThreshold: 2,
     timeout: 30000,
   })
   ```

2. Wrap all `fetch` calls:
   ```rescript
   let fetchWithCircuitBreaker = (url, init) => {
     if !CircuitBreaker.canExecute(circuitBreaker) {
       Logger.warn(~module_="AuthenticatedClient", ~message="CIRCUIT_OPEN", ())
       Promise.resolve(Error("Service temporarily unavailable"))
     } else {
       Fetch.fetch(url, init)
       ->Promise.then(response => {
         if response.ok {
           CircuitBreaker.recordSuccess(circuitBreaker)
         } else if response.status >= 500 {
           CircuitBreaker.recordFailure(circuitBreaker)
         }
         Promise.resolve(Ok(response))
       })
       ->Promise.catch(err => {
         CircuitBreaker.recordFailure(circuitBreaker)
         Promise.resolve(Error(getErrorMessage(err)))
       })
     }
   }
   ```

### C. User Notification on Circuit Open

When circuit opens, dispatch a user-visible notification:

```rescript
if CircuitBreaker.getState(circuitBreaker) == Open {
  EventBus.dispatch(ShowNotification(
    "Connection issues detected. Retrying automatically...",
    #Warning,
    None
  ))
}
```

---

## 3. JSON Encoding Standard

All logging data MUST use `rescript-json-combinators`:

```rescript
// ✅ REQUIRED
Logger.warn(
  ~module_="CircuitBreaker",
  ~message="CIRCUIT_OPENED",
  ~data=Logger.castToJson({
    "failureCount": cb.failureCount,
    "state": stateToString(cb.state),
  }),
  ()
)
```

---

## 4. Verification Criteria

- [ ] Circuit breaker opens after 5 consecutive 5xx errors.
- [ ] Circuit breaker enters half-open state after 30 seconds.
- [ ] Circuit breaker closes after 2 successful requests in half-open state.
- [ ] UI shows warning notification when circuit opens.
- [ ] Requests are immediately rejected (no network call) when circuit is open.
- [ ] All JSON encoding uses `rescript-json-combinators`.
- [ ] `npm run build` completes with zero warnings.

---

## 5. File Checklist

- [ ] `src/utils/CircuitBreaker.res` - New module
- [ ] `src/utils/CircuitBreaker.resi` - Interface file
- [ ] `src/systems/Api/AuthenticatedClient.res` - Integration
- [ ] `tests/unit/CircuitBreaker_v.test.res` - Unit tests
- [ ] `MAP.md` - Add new module entry

---

## 6. References

- [Circuit Breaker Pattern (Martin Fowler)](https://martinfowler.com/bliki/CircuitBreaker.html)
- `src/systems/Api/AuthenticatedClient.res`
- `src/systems/EventBus.res`
