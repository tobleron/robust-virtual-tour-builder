# Task 1459: Service Worker Fetch Timeout

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 4.2  
**Phase**: 4 (Polish)  
**Depends on**: None  
**Blocks**: None

---

## Objective
Add a timeout wrapper around network fetch fallbacks in the service worker to prevent indefinite hangs on degraded connections.

## Problem
**Location**: `src/ServiceWorkerMain.res` fetch event handler

For non-cached requests, the service worker falls through to `fetch(request)` without a timeout. On degraded networks (not fully offline), these requests can hang indefinitely — neither failing fast nor succeeding.

## Implementation

### Add timeout wrapper in fetch handler

```rescript
let fetchWithTimeout = (request, timeoutMs) => {
  Promise.race([
    Fetch.fetch(request),
    Promise.make((_, reject) => {
      let _ = setTimeout(() => {
        reject("ServiceWorkerFetchTimeout")
      }, timeoutMs)
    })
  ])
}
```

### Apply in fetch event handler

Replace direct `fetch(request)` calls in the fetch event handler with `fetchWithTimeout(request, 15000)` (15 second timeout).

On timeout:
- For navigation requests: serve a cached fallback (the app shell) if available
- For API requests: let the error propagate (the app-level retry/CB will handle it)
- For asset requests: serve from cache if available, otherwise fail gracefully

### Timeout values
- Navigation requests: 10 seconds (user expects fast page loads)
- API requests: 30 seconds (some operations are legitimately slow)
- Asset requests: 15 seconds (reasonable middle ground)

## Files to Modify

| File | Change |
|------|--------|
| `src/ServiceWorkerMain.res` | Add `fetchWithTimeout` helper, apply to fetch handler with request-type-specific timeouts |

## Acceptance Criteria

- [ ] Network fetch in service worker has a configurable timeout
- [ ] Navigation requests timeout after 10 seconds
- [ ] Cached fallback served on timeout for navigation requests
- [ ] API requests timeout after 30 seconds
- [ ] Asset requests timeout after 15 seconds
- [ ] Zero compiler warnings
