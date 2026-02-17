# Task 1452: AuthenticatedClient Offline Pre-Check

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 2.1  
**Phase**: 2 (API Layer)  
**Depends on**: 1449 (NetworkStatus module)  
**Blocks**: None

---

## Objective
Add an offline pre-check to `AuthenticatedClient.request()` and `requestWithRetry()` to fast-fail when the browser is offline, preventing wasted retries and unnecessary circuit breaker trips.

## Problem
**Location**: `src/systems/Api/AuthenticatedClient.res` line ~125+

The `request` function checks the CircuitBreaker state but never checks `NetworkStatus.isOnline()`. When offline:
1. `fetch()` is attempted → `TypeError: Failed to fetch`
2. CircuitBreaker records a failure
3. Retry logic kicks in with backoff
4. More fetch attempts, more failures
5. Circuit breaker trips to Open
6. User sees "Connection issues: Circuit breaker activated"

All of this is wasted work when `navigator.onLine === false`.

## Implementation

### In `request()` — Add offline check before CircuitBreaker check

```rescript
// Add BEFORE the CircuitBreaker state check (line ~125)
if !NetworkStatus.isOnline() {
  Logger.warn(
    ~module_="AuthenticatedClient",
    ~message="REQUEST_SKIPPED_OFFLINE",
    ~data=Some(Logger.castToJson({"url": url, "method": method})),
    (),
  )
  signalScope.cleanup()
  Error("NetworkOffline")
} else if lastState === CircuitBreaker.Open {
  // ... existing circuit breaker logic ...
```

### In `requestWithRetry()` — Add offline check in `shouldRetry`

The existing `shouldRetry` callback in `requestWithRetry` should also check for the `"NetworkOffline"` error string and classify it as `NonRetryable`:

```rescript
// In the shouldRetry logic within requestWithRetry
if error == "NetworkOffline" {
  false // Don't retry offline errors
} else {
  // ... existing retry classification ...
}
```

### Update notification for offline errors

When `request()` returns `Error("NetworkOffline")`, callers should see a distinct notification rather than the generic "Connection issues" message. The `OfflineBanner` (from Task 1449) already handles the persistent banner, so individual API calls should NOT dispatch redundant notifications for offline state.

## Files to Modify

| File | Change |
|------|--------|
| `src/systems/Api/AuthenticatedClient.res` | Add `NetworkStatus.isOnline()` check in `request()`, update `shouldRetry` in `requestWithRetry()` |

## Acceptance Criteria

- [ ] `request()` returns `Error("NetworkOffline")` immediately when `NetworkStatus.isOnline()` is false
- [ ] No `fetch()` call is made when offline
- [ ] CircuitBreaker is NOT affected by offline state (no `recordFailure` called)
- [ ] `requestWithRetry()` does NOT retry `"NetworkOffline"` errors
- [ ] Logger output is `warn` level (offline is expected state, not error)
- [ ] No redundant notifications dispatched for offline (banner handles it)
- [ ] Zero compiler warnings
