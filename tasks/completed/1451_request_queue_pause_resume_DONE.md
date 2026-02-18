# Task 1451: Add RequestQueue Pause/Resume/Drain Mechanism

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 1.3  
**Phase**: 1 (Critical Foundation)  
**Depends on**: 1449 (NetworkStatus module)  
**Blocks**: None

---

## Objective
Add pause, resume, and drain capabilities to the `RequestQueue` module, and integrate with `NetworkStatus` for automatic offline pausing.

## Problem
**Location**: `src/utils/RequestQueue.res`

When the browser goes offline, the queue continues processing all queued requests. They all fail, produce error noise, and may trip the circuit breaker. There's no way to:
1. Pause processing when offline
2. Resume processing when back online
3. Drain/cancel all queued items
4. Inspect queue length

## Implementation

### Add state refs
```rescript
let paused = ref(false)

let length = (): int => Array.length(queue)
```

### Modify `process()`
```rescript
let rec process = () => {
  // Don't process if paused
  if paused.contents {
    ()
  } else if activeCount.contents < maxConcurrent && Array.length(queue) > 0 {
    // ... existing logic ...
  }
}
```

### Add `pause()`, `resume()`, `drain()`
```rescript
let pause = () => {
  paused := true
  Logger.debug(
    ~module_="RequestQueue",
    ~message="PAUSED",
    ~data=Some(Logger.castToJson({"queued": Array.length(queue)})),
    (),
  )
}

let resume = () => {
  paused := false
  Logger.debug(
    ~module_="RequestQueue",
    ~message="RESUMED",
    ~data=Some(Logger.castToJson({"queued": Array.length(queue)})),
    (),
  )
  process() // Kick off processing
}

let drain = (): int => {
  let count = Array.length(queue)
  // Reject all queued items
  // Note: We can't easily reject promises already in the queue without
  // refactoring the queue item type. For now, just clear the array.
  let _ = Array.splice(queue, ~start=0, ~remove=count, ~insert=[])
  Logger.info(
    ~module_="RequestQueue",
    ~message="DRAINED",
    ~data=Some(Logger.castToJson({"drainedCount": count})),
    (),
  )
  count
}
```

### Integrate with NetworkStatus
```rescript
let initializeNetworkListener = () => {
  let _unsubscribe = NetworkStatus.subscribe(online => {
    if online {
      resume()
    } else {
      pause()
    }
  })
}
```

Call `initializeNetworkListener()` from `Main.res` after `NetworkStatus.initialize()`.

## Files to Modify

| File | Change |
|------|--------|
| `src/utils/RequestQueue.res` | Add `paused` ref, `pause()`, `resume()`, `drain()`, `length()`, modify `process()`, add `initializeNetworkListener` |
| `src/Main.res` | Call `RequestQueue.initializeNetworkListener()` after `NetworkStatus.initialize()` |

## Acceptance Criteria

- [ ] `RequestQueue.pause()` stops processing new items from the queue
- [ ] `RequestQueue.resume()` re-enables processing and kicks off the processor
- [ ] `RequestQueue.drain()` clears all queued items and returns count
- [ ] `RequestQueue.length()` returns current queue depth
- [ ] Queue auto-pauses when `NetworkStatus` reports offline
- [ ] Queue auto-resumes when `NetworkStatus` reports online
- [ ] Items added while paused are still enqueued (not rejected)
- [ ] Active (in-flight) requests are NOT affected by pause (only new processing is stopped)
- [ ] Zero compiler warnings
