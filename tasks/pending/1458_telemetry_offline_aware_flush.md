# Task 1458: LoggerTelemetry Offline-Aware Flush

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 4.1  
**Phase**: 4 (Polish)  
**Depends on**: 1449 (NetworkStatus module)  
**Blocks**: None

---

## Objective
Skip telemetry flush attempts when the browser is offline. Trigger an immediate flush when connectivity returns.

## Problem
**Location**: `src/utils/LoggerTelemetry.res`

The telemetry batch flusher attempts network requests even when offline. It has an internal suspension mechanism (`maxConsecutiveFailures`), but it takes several failed attempts before suspension kicks in. These failures are wasted work and noisy logs.

## Implementation

### 1. Check online before flush

In the flush function, add a pre-check:
```rescript
// At the top of the flush/send function:
if !NetworkStatus.isOnline() {
  Logger.debug(
    ~module_="LoggerTelemetry",
    ~message="FLUSH_SKIPPED_OFFLINE",
    ~data=Some(Logger.castToJson({"queuedCount": Array.length(queue)})),
    (),
  )
  // Don't reset the timer, just skip this flush cycle
  () 
} else {
  // ... existing flush logic ...
}
```

### 2. Flush on reconnect

Subscribe to `NetworkStatus` changes and trigger a flush when coming back online:
```rescript
let initializeNetworkListener = () => {
  let _unsubscribe = NetworkStatus.subscribe(online => {
    if online {
      Logger.debug(
        ~module_="LoggerTelemetry",
        ~message="FLUSH_ON_RECONNECT",
        (),
      )
      flush() // Immediate flush of queued telemetry
    }
  })
}
```

### 3. Reset consecutive failure count on reconnect

When coming back online, reset the failure counter so telemetry isn't stuck in suspended state:
```rescript
// In the network listener callback:
if online {
  consecutiveFailures := 0
  suspended := false
  flush()
}
```

## Files to Modify

| File | Change |
|------|--------|
| `src/utils/LoggerTelemetry.res` | Add online pre-check in flush, add network listener, reset failures on reconnect |

## Acceptance Criteria

- [ ] Flush is skipped when `NetworkStatus.isOnline()` returns false
- [ ] Timer continues running (not reset) so flush retries next cycle
- [ ] Immediate flush triggered when coming back online
- [ ] Consecutive failure counter reset on reconnect
- [ ] Suspended state cleared on reconnect
- [ ] Zero compiler warnings
