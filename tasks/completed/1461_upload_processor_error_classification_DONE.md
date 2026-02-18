# Task 1461: UploadProcessor Offline vs Backend Error Classification

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 4.4  
**Phase**: 4 (Polish)  
**Depends on**: 1449 (NetworkStatus module)  
**Blocks**: None

---

## Objective
Distinguish between "browser is offline" and "backend is down" in the UploadProcessor health check, providing accurate error messages to the user.

## Problem
**Location**: `src/systems/UploadProcessor.res` lines 38-47

`Resizer.checkBackendHealth()` returns a simple `bool`. When it fails, the message is always:
> "Backend Server Not Connected! Port 8080 is not running."

But the actual issue could be:
- Browser is offline (WiFi/ethernet disconnected)
- DNS resolution failure
- CORS error
- Backend genuinely not running

The user may try to start the backend when the real issue is their WiFi.

## Implementation

### Add offline pre-check before health check

```rescript
if !NetworkStatus.isOnline() {
  updateProgress(100.0, "Error: No Internet Connection", false, "Error")
  UploadProcessorLogic.Utils.notify(
    "You appear to be offline. Please check your internet connection and try again.",
    "warning",
  )
  OperationJournal.failOperation(journalId, "Browser Offline")->Promise.then(
    () => Promise.resolve(emptyResult),
  )
} else {
  Resizer.checkBackendHealth()->Promise.then(isUp => {
    if !isUp {
      updateProgress(100.0, "Error: Backend Offline", false, "Error")
      UploadProcessorLogic.Utils.notify(
        "Backend Server Not Connected! Port 8080 is not running.",
        "error",
      )
      OperationJournal.failOperation(journalId, "Backend Offline")->Promise.then(
        () => Promise.resolve(emptyResult),
      )
    } else {
      // ... existing upload logic ...
    }
  })
}
```

## Files to Modify

| File | Change |
|------|--------|
| `src/systems/UploadProcessor.res` | Add `NetworkStatus.isOnline()` pre-check before `checkBackendHealth()` |

## Acceptance Criteria

- [ ] Offline state shows "You appear to be offline" (not "Port 8080 not running")
- [ ] Backend-down state continues to show "Backend Server Not Connected"
- [ ] Journal records "Browser Offline" vs "Backend Offline" for diagnostics
- [ ] Progress callback shows appropriate phase/message
- [ ] Zero compiler warnings
