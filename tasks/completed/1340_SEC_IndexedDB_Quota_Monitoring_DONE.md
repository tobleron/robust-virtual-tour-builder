# [1340] IndexedDB Quota Monitoring — Prevent Silent Data Loss

## Priority: P0 (Critical — flagged in Feb 4 audit, still unresolved)

## Context
The application's entire persistence strategy relies on IndexedDB via `PersistenceLayer.res`. If the browser's IndexedDB quota is exhausted:
- `put()` operations silently fail (or throw `QuotaExceededError`)
- The user continues working, believing their data is saved
- **Silent data loss** occurs when the user closes the browser

This was flagged as **P0** in the Commercial Readiness Audit (Feb 4, 2026) and remains unresolved as of Feb 11.

## Objective
1. Monitor IndexedDB usage and warn users before quota exhaustion
2. Handle `QuotaExceededError` gracefully with a clear notification
3. Provide guidance on freeing space (deleting old projects)

## Implementation

### Step 1: Add Storage Estimate Binding

```rescript
// src/bindings/StorageBindings.res
module StorageEstimate = {
  type t = {
    usage: float,    // bytes used
    quota: float,    // bytes available
  }
}

module StorageManager = {
  @val @scope(("navigator", "storage"))
  external estimate: unit => Promise.t<StorageEstimate.t> = "estimate"
}
```

### Step 2: Create Quota Monitor Module

```rescript
// src/systems/Storage/QuotaMonitor.res

let warningThreshold = 0.80  // 80%
let criticalThreshold = 0.95 // 95%

let checkQuota = async () => {
  try {
    let estimate = await StorageManager.estimate()
    let usagePercent = estimate.usage /. estimate.quota
    
    if usagePercent > criticalThreshold {
      NotificationManager.dispatch({
        importance: Error,
        message: "Storage critically full. Save your work and clear old projects.",
        // ...
      })
    } else if usagePercent > warningThreshold {
      NotificationManager.dispatch({
        importance: Warning,
        message: "Storage nearly full (" ++ percentStr ++ "%). Consider removing old projects.",
        // ...
      })
    }
    
    Logger.info(
      ~module_="QuotaMonitor",
      ~message="QUOTA_CHECK",
      ~data=Some({
        "usageMB": estimate.usage /. 1048576.0,
        "quotaMB": estimate.quota /. 1048576.0,
        "percent": usagePercent *. 100.0,
      }),
      (),
    )
  } catch {
  | _ => 
    // StorageManager.estimate() is not available in all browsers
    Logger.debug(~module_="QuotaMonitor", ~message="STORAGE_API_UNAVAILABLE", ())
  }
}
```

### Step 3: Integrate Into Persistence Layer

**[MODIFY] `src/systems/PersistenceLayer.res`**

1. Call `QuotaMonitor.checkQuota()` on app startup
2. Call `QuotaMonitor.checkQuota()` after every successful `put()` operation (throttled to max once per minute)
3. Wrap IndexedDB `put()` in a try/catch that handles `QuotaExceededError`:
   ```rescript
   try {
     await db->put(data)
   } catch {
   | exn =>
     let (msg, _) = Logger.getErrorDetails(exn)
     if String.includes(msg, "QuotaExceeded") {
       NotificationManager.dispatch({
         importance: Error,
         message: "Save failed: Storage full. Please free space.",
         // ...
       })
     }
   }
   ```

### Step 4: Add to App Initialization

**[MODIFY] `src/Main.res`**
- Call `QuotaMonitor.checkQuota()` during initialization, after IndexedDB is opened

## Verification
- [ ] Quota check runs on app startup (visible in Logger output)
- [ ] Warning notification appears when storage > 80%
- [ ] Error notification appears when storage > 95%
- [ ] `QuotaExceededError` is caught and shows user-friendly message
- [ ] `npm run build` passes cleanly
- [ ] Graceful fallback when `navigator.storage.estimate()` is unavailable

## Estimated Effort: Half day
