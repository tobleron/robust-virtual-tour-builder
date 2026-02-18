# Task 1453: Fix AuthenticatedClient prepareRequestSignal Listener Leak

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 2.2  
**Phase**: 2 (API Layer)  
**Depends on**: None  
**Blocks**: None

---

## Objective
Fix the event listener memory leak in `AuthenticatedClient.prepareRequestSignal()` where `removeEventListener` receives an anonymous function instead of the actual listener reference.

## Problem
**Location**: `src/systems/Api/AuthenticatedClient.res` lines ~85-120

Two issues:

### Issue A: Orphaned event listener
```rescript
// Current code (line ~113):
Option.forEach(parentSignal, s =>
  s->ReBindings.AbortSignal.removeEventListener("abort", () => ())
  //                                                     ^^^^^^^^
  // This is a NEW anonymous function, NOT the listener that was added!
)
```

The `abort` event listener added on line ~102 is a closure, but the `removeEventListener` on line ~113 passes `() => ()` — a completely different function reference. The actual listener is **never removed**.

In a long session with many API calls, this accumulates orphaned `abort` listeners on parent `AbortSignal` objects.

### Issue B: setTimeout not cleared

The timeout handle from `setTimeout` (line ~117) is never stored or cleared during cleanup. If the request completes before timeout, the timer still fires and calls `cleanup()` again (though the `cleaned` ref prevents double-abort, the timer still runs).

## Implementation

### Fix A: Store and remove the actual listener

```rescript
let prepareRequestSignal = (
  ~parentSignal: option<ReBindings.AbortSignal.t>,
  ~timeoutMs: int,
): requestSignalScope => {
  let controller = ReBindings.AbortController.make()
  let requestSignal = ReBindings.AbortController.signal(controller)
  let timedOut = ref(false)
  let cleaned = ref(false)
  let timeoutId = ref(None) // Store timeout handle

  // Named listener for proper cleanup
  let onParentAbort = () => {
    timedOut := true
    if !cleaned.contents {
      cleaned := true
      // Clear the timeout since parent aborted
      switch timeoutId.contents {
      | Some(id) => clearTimeout(id)
      | None => ()
      }
      ReBindings.AbortController.abort(controller)
    }
  }

  let cleanup = () => {
    if !cleaned.contents {
      cleaned := true
      // Clear timeout
      switch timeoutId.contents {
      | Some(id) => clearTimeout(id)
      | None => ()
      }
      // Remove the ACTUAL listener (not an anonymous () => ())
      Option.forEach(parentSignal, s =>
        s->ReBindings.AbortSignal.removeEventListener("abort", onParentAbort)
      )
    }
  }

  // Attach parent signal listener
  switch parentSignal {
  | Some(s) =>
    s->ReBindings.AbortSignal.addEventListener("abort", onParentAbort)
  | None => ()
  }

  // Store timeout handle
  timeoutId := Some(
    setTimeout(() => {
      if !cleaned.contents {
        timedOut := true
        cleaned := true
        ReBindings.AbortController.abort(controller)
        // Remove parent listener on timeout too
        Option.forEach(parentSignal, s =>
          s->ReBindings.AbortSignal.removeEventListener("abort", onParentAbort)
        )
      }
    }, timeoutMs)
  )

  {signal: requestSignal, cleanup, wasTimedOut: () => timedOut.contents}
}
```

## Files to Modify

| File | Change |
|------|--------|
| `src/systems/Api/AuthenticatedClient.res` | Rewrite `prepareRequestSignal` to store listener reference and timeout handle |

## Acceptance Criteria

- [ ] `removeEventListener` receives the same function reference that was passed to `addEventListener`
- [ ] `setTimeout` handle is stored and cleared during cleanup
- [ ] Parent signal abort still properly aborts the child signal
- [ ] Timeout still properly triggers abort when elapsed
- [ ] No double-abort (existing `cleaned` guard preserved)
- [ ] Zero compiler warnings
