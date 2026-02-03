# TASK: Implement Client-Side Request Debouncing & Rate Limiting

**Priority**: 🟢 Low
**Estimated Effort**: Small (1-2 hours)
**Dependencies**: None
**Related Tasks**: 1201

---

## 1. Problem Statement

While the backend has `QuotaCheck` middleware for rate limiting, the frontend lacks client-side protection:

- **Wasted Requests**: Users can spam save/export buttons before backend quota kicks in.
- **Poor UX**: Users don't get immediate feedback that they're clicking too fast.
- **Network Congestion**: Redundant requests consume bandwidth and connections.

---

## 2. Technical Requirements

### A. Create Debounce Utility

**File**: `src/utils/Debounce.res` (new)

```rescript
type debounced<'a, 'b> = {
  call: 'a => Promise.t<'b>,
  cancel: unit => unit,
  pending: unit => bool,
}

let make: (
  ~fn: 'a => Promise.t<'b>,
  ~wait: int,
  ~leading: bool=?,
  ~trailing: bool=?,
) => debounced<'a, 'b>
```

### B. Create Rate Limiter Utility

**File**: `src/utils/RateLimiter.res` (new)

```rescript
type t

let make: (~maxCalls: int, ~windowMs: int) => t
let canCall: t => bool
let recordCall: t => unit
let reset: t => unit
let remainingCalls: t => int
```

**Logic**:
- Sliding window rate limiting.
- Default: 10 calls per 60 seconds for heavy operations.

### C. Create Combined Hook

**File**: `src/hooks/useThrottledAction.res` (new)

```rescript
let make = (~action: unit => Promise.t<'a>, ~debounceMs: int, ~rateLimit: (int, int)) => {
  let (isThrottled, setThrottled) = React.useState(() => false)
  let (isPending, setPending) = React.useState(() => false)
  
  let execute = () => {
    if isThrottled || isPending {
      EventBus.dispatch(ShowNotification(
        "Please wait before trying again.",
        #Warning,
        None
      ))
      Promise.resolve(None)
    } else {
      setPending(_ => true)
      action()
      ->Promise.then(result => {
        setPending(_ => false)
        Promise.resolve(Some(result))
      })
      ->Promise.catch(_ => {
        setPending(_ => false)
        Promise.resolve(None)
      })
    }
  }
  
  (execute, isPending, isThrottled)
}
```

### D. Apply to Heavy Operations

| Component | Action | Debounce | Rate Limit |
|-----------|--------|----------|------------|
| `SidebarActions.res` | Save Project | 2000ms | 5/60s |
| `SidebarActions.res` | Export Tour | 5000ms | 3/60s |
| `SidebarActions.res` | Import Project | 2000ms | 5/60s |
| `ViewerSnapshot.res` | Capture Snapshot | 1000ms | 10/60s |

---

## 3. Visual Feedback

When action is debounced/throttled:

```rescript
// Button shows loading state
<button
  disabled={isPending || isThrottled}
  className={isPending ? "btn-loading" : ""}
>
  {isPending ? "Processing..." : "Save"}
</button>
```

Add CSS:
```css
.btn-loading {
  opacity: 0.7;
  cursor: wait;
}

.btn-loading::after {
  content: "";
  /* spinner animation */
}
```

---

## 4. Verification Criteria

- [ ] Rapid clicking on Save button only triggers one request.
- [ ] User sees "Please wait" notification when throttled.
- [ ] Rate limiter resets after window expires.
- [ ] Button shows loading state during pending action.
- [ ] `npm run build` completes with zero warnings.

---

## 5. File Checklist

- [ ] `src/utils/Debounce.res` - New module
- [ ] `src/utils/RateLimiter.res` - New module
- [ ] `src/hooks/useThrottledAction.res` - New hook
- [ ] `src/components/Sidebar/SidebarActions.res` - Apply to buttons
- [ ] `src/components/ViewerSnapshot.res` - Apply to capture
- [ ] `index.css` - Loading button styles
- [ ] `tests/unit/Debounce_v.test.res` - Unit tests
- [ ] `tests/unit/RateLimiter_v.test.res` - Unit tests
- [ ] `MAP.md` - Add new module entries

---

## 6. References

- `src/utils/RequestQueue.res` (existing concurrency control)
- `src/components/Sidebar/SidebarActions.res`
- `backend/src/middleware.rs` (QuotaCheck reference)
