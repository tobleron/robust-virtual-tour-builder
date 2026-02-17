# Task 1449: Create NetworkStatus Module

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 1.1  
**Phase**: 1 (Critical Foundation)  
**Depends on**: None  
**Blocks**: 1451, 1452, 1454, 1458, 1461

---

## Objective
Create a centralized `NetworkStatus` module that provides browser online/offline awareness to the entire application. This is the **cornerstone** of the network stability initiative — nearly every other fix depends on this module existing.

## Problem
The application has **zero awareness** of browser online/offline state:
- No `navigator.onLine` binding anywhere in the codebase
- No `online`/`offline` event listeners
- The CircuitBreaker and Retry modules operate blindly
- Confusing user notifications ("Connection issues" when the real issue is "You're offline")

## Implementation

### 1. Create `src/utils/NetworkStatus.res`

```rescript
/* src/utils/NetworkStatus.res */

// --- Bindings ---
@val @scope("navigator") external navigatorOnLine: bool = "onLine"

@val @scope("window")
external addEventListener: (string, unit => unit) => unit = "addEventListener"

@val @scope("window")
external removeEventListener: (string, unit => unit) => unit = "removeEventListener"

// --- State ---
let currentStatus: ref<bool> = ref(navigatorOnLine)
let subscribers: ref<array<bool => unit>> = ref([])

// --- Public API ---
let isOnline = (): bool => currentStatus.contents

let subscribe = (callback: bool => unit): (unit => unit) => {
  let _ = Array.push(subscribers.contents, callback)
  () => {
    subscribers := subscribers.contents->Belt.Array.keep(cb => cb !== callback)
  }
}

// --- Internal ---
let notifySubscribers = (online: bool) => {
  subscribers.contents->Belt.Array.forEach(cb => cb(online))
}

let handleOnline = () => {
  if !currentStatus.contents {
    currentStatus := true
    Logger.info(
      ~module_="NetworkStatus",
      ~message="NETWORK_ONLINE",
      (),
    )
    EventBus.dispatch(NetworkStatusChanged(true))
    notifySubscribers(true)
  }
}

let handleOffline = () => {
  if currentStatus.contents {
    currentStatus := false
    Logger.warn(
      ~module_="NetworkStatus",
      ~message="NETWORK_OFFLINE",
      (),
    )
    EventBus.dispatch(NetworkStatusChanged(false))
    notifySubscribers(false)
  }
}

let initialize = () => {
  currentStatus := navigatorOnLine
  addEventListener("online", handleOnline)
  addEventListener("offline", handleOffline)
  Logger.info(
    ~module_="NetworkStatus",
    ~message="INITIALIZED",
    ~data=Some(Logger.castToJson({"online": navigatorOnLine})),
    (),
  )
}

let cleanup = () => {
  removeEventListener("online", handleOnline)
  removeEventListener("offline", handleOffline)
  subscribers := []
}
```

### 2. Create `src/utils/NetworkStatus.resi`

```rescript
/* src/utils/NetworkStatus.resi */

let isOnline: unit => bool
let subscribe: (bool => unit) => unit => unit
let initialize: unit => unit
let cleanup: unit => unit
```

### 3. Add `NetworkStatusChanged` to EventBus

In `src/core/EventBus.res`, add to the event variant:
```rescript
| NetworkStatusChanged(bool)  // true = online, false = offline
```

### 4. Initialize in Main.res

In `src/Main.res`, add `NetworkStatus.initialize()` during app bootstrap (near the Service Worker registration area, around line 157).

### 5. Create Offline Banner Component

Create `src/components/ui/OfflineBanner.res`:
- A persistent, non-intrusive banner at the top of the viewport
- Shows when `NetworkStatus.isOnline()` returns false
- Auto-dismisses when online status returns
- Uses `React.useState` + `NetworkStatus.subscribe` in a `useEffect`
- Styled per `docs/CSS_ARCHITECTURE_AND_BEST_PRACTICES.md`
- Matches warning notification styling (amber/yellow tones)
- Text: "You appear to be offline. Some features may be unavailable."

### 6. Mount OfflineBanner in App.res

Add `<OfflineBanner />` near the top of the app layout (above main content, below any nav).

## Files to Create/Modify

| File | Action |
|------|--------|
| `src/utils/NetworkStatus.res` | **CREATE** |
| `src/utils/NetworkStatus.resi` | **CREATE** |
| `src/core/EventBus.res` | Add `NetworkStatusChanged(bool)` variant |
| `src/Main.res` | Add `NetworkStatus.initialize()` call |
| `src/components/ui/OfflineBanner.res` | **CREATE** |
| `src/App.res` | Mount `<OfflineBanner />` |

## Acceptance Criteria

- [ ] `NetworkStatus.isOnline()` returns correct browser online state
- [ ] `NetworkStatus.subscribe()` fires callbacks on state changes
- [ ] `EventBus.NetworkStatusChanged` dispatched on transitions
- [ ] Offline banner appears when browser goes offline
- [ ] Offline banner auto-dismisses when browser comes back online
- [ ] `NetworkStatus.initialize()` called during app bootstrap
- [ ] Zero compiler warnings
- [ ] Logger output uses `Logger.info`/`Logger.warn` (no `console.log`)
