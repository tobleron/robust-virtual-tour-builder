# Task 1460: AsyncQueue Error Propagation

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 4.3  
**Phase**: 4 (Polish)  
**Depends on**: None  
**Blocks**: None

---

## Objective
Propagate worker errors to callers so failed items can be inspected and potentially retried, instead of being silently swallowed.

## Problem
**Location**: `src/utils/AsyncQueue.res` lines 85-95

When a worker throws, the error is logged but the item is stored as `None` in the results array:
```rescript
->Promise.catch(err => {
  // Error logged...
  completedCount := completedCount.contents + 1
  Dict.set(activeStatuses, Belt.Int.toString(i), "__Error__")
  // But the result slot stays None — caller can't distinguish
  // "not processed" from "failed"
  report()
  next()
  Promise.resolve()
})
```

The caller receives `Belt.Array.keepMap(results, x => x)` which filters out `None` values — failed items are simply absent from results.

## Implementation

### Change result type to include errors

```rescript
type queueResult<'result> =
  | Success('result)
  | Failed(int, string)  // (index, error message)

// Change results array type
let results: Belt.Array.t<option<queueResult<'result>>> = Belt.Array.make(total, None)
```

### Update worker completion
```rescript
// On success:
let _ = Belt.Array.set(results, i, Some(Success(res)))

// On failure:
let (msg, _) = getErrorDetails(err)
let _ = Belt.Array.set(results, i, Some(Failed(i, msg)))
```

### Update return value
```rescript
// Change resolve to include all results (successes and failures)
resolve.contents(Belt.Array.keepMap(results, x => x))
```

### Alternative (less breaking): Add error callback

If changing the return type is too breaking for existing callers, add an optional `onError` callback parameter:

```rescript
let execute = (
  items: array<'item>,
  maxConcurrency: int,
  worker: (int, 'item, string => unit) => Promise.t<'result>,
  onProgress: (float, string) => unit,
  ~onWorkerError: option<(int, string) => unit>=?,
) => {
  // ... in catch block:
  switch onWorkerError {
  | Some(cb) => cb(i, msg)
  | None => ()
  }
}
```

Choose the approach that minimizes disruption to existing callers. The callback approach is safer.

## Files to Modify

| File | Change |
|------|--------|
| `src/utils/AsyncQueue.res` | Add `onWorkerError` callback or change result type to propagate failures |

## Acceptance Criteria

- [ ] Failed worker items are distinguishable from successful ones
- [ ] Caller can inspect which items failed and why
- [ ] Existing callers continue to work (backwards compatible if using callback approach)
- [ ] Error logging preserved alongside propagation
- [ ] Zero compiler warnings
