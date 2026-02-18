# Task 1450: Fix CircuitBreaker HalfOpen Recovery Logic

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 1.2  
**Phase**: 1 (Critical Foundation)  
**Depends on**: None  
**Blocks**: None (independent fix)

---

## Objective
Fix the CircuitBreaker's HalfOpen state to support graduated recovery instead of reverting to Open on a single probe failure.

## Problem
**Location**: `src/utils/CircuitBreaker.res` lines 47-56

Current behavior in HalfOpen state:
1. First call: `probing=false` → sets `probing=true`, returns `true` (allows probe)
2. If probe succeeds: increments `successCount`, sets `probing=false`
3. If probe fails: **immediately reverts to Open state** (`recordFailure` → `OpenState`)
4. Only ONE probe attempt before failure resets the whole recovery

This means a single transient error during recovery (e.g., one packet loss out of many) completely resets the circuit breaker timeout. Network recovery after outages is typically noisy — the first few requests may still fail even though connectivity is restored.

## Fix

### Modified `internalState` type
```rescript
| HalfOpenState({successCount: int, failureCount: int, probing: bool})
```

### Modified `recordFailure` for HalfOpen
```rescript
| HalfOpenState({failureCount}) =>
  let newFailureCount = failureCount + 1
  // Allow up to 2 probe failures before reverting to Open
  // (configurable via config.halfOpenFailureTolerance or hardcoded)
  if newFailureCount >= 2 {
    t.internalState = OpenState({startTime: now})
  } else {
    t.internalState = HalfOpenState({
      successCount: 0, // Reset successes on failure
      failureCount: newFailureCount,
      probing: false, // Allow next probe
    })
  }
```

### Modified `canExecute` for HalfOpen
```rescript
| HalfOpenState({probing, successCount, failureCount}) =>
  if probing {
    false
  } else {
    t.internalState = HalfOpenState({successCount, failureCount, probing: true})
    true
  }
```

### Modified `recordSuccess` for HalfOpen
```rescript
| HalfOpenState({successCount, failureCount}) =>
  let newSuccessCount = successCount + 1
  if newSuccessCount >= t.config.successThreshold {
    t.internalState = ClosedState({failureCount: 0})
  } else {
    t.internalState = HalfOpenState({
      successCount: newSuccessCount,
      failureCount, // Preserve failure count
      probing: false,
    })
  }
```

## Files to Modify

| File | Change |
|------|--------|
| `src/utils/CircuitBreaker.res` | Update `internalState` type, modify `canExecute`, `recordSuccess`, `recordFailure` |

## Acceptance Criteria

- [ ] HalfOpen state includes `failureCount` field
- [ ] Single probe failure in HalfOpen does NOT revert to Open
- [ ] Two consecutive probe failures revert to Open (or configurable threshold)
- [ ] Successful probes still transition to Closed after `successThreshold` reached
- [ ] `getState` still returns correct `HalfOpen` for the HalfOpen internal state
- [ ] Zero compiler warnings
