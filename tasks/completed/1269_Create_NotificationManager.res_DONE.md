# 1269: Create NotificationManager.res - Stateful API

**Status**: Pending
**Priority**: High (Core API - blocks integration)
**Effort**: 1.5 hours
**Dependencies**: 1266 (NotificationTypes.res must exist)
**Can Parallelize With**: 1267, 1268 (only depends on 1266, not on queue impl)
**Scalability**: ⭐⭐⭐⭐⭐ (Public API, all downstream modules use this)
**Reliability**: ⭐⭐⭐⭐ (State management + timers, needs tests in 1270)

---

## 🎯 Objective

Implement the centralized notification manager with module-level state, listener pattern for React subscriptions, and auto-dismiss timers. This wraps NotificationQueue with stateful behavior and event pub/sub.

**Outcome**: Complete NotificationManager API ready for React components to subscribe to, tests written in 1270, ready for NotificationCenter component to consume.

---

## 📋 Acceptance Criteria

✅ **Code Quality**
- Zero ReScript compilation errors
- Zero compiler warnings
- All functions properly typed
- No unwrap() or panic calls

✅ **Functionality**
- `dispatch`: Queue notification + schedule auto-dismiss timer
- `subscribe`: Register listener, return unsubscribe function
- `getState`: Return current queue state
- `dismiss`: Remove by ID, cancel timer
- `clear`: Wipe all notifications
- `generateId`: Create unique ID with format "notif-{timestamp}-{random}"

✅ **State Management**
- Module-level ref for queue state
- Listeners array for pub/sub
- Timer map for auto-dismiss tracking
- Proper cleanup on dismiss

✅ **Architecture**
- Listeners notified on every state change
- Each listener gets new state
- Unsubscribe function works correctly
- No memory leaks (timers cleaned up)

---

## 📝 Implementation Checklist

**Module State**:
- [ ] Create module-level `state: ref<NotificationTypes.queueState>`
- [ ] Create module-level `listeners: ref<array<NotificationTypes.queueState => unit>>`
- [ ] Create module-level `timerIds: ref<Belt.Map.String.t<Js.Global.timeoutId>>`

**Core Functions**:
- [ ] Implement `dispatch: (NotificationTypes.notification) => unit`
  - [ ] Enqueue through NotificationQueue
  - [ ] Update module state
  - [ ] Schedule auto-dismiss timer if duration > 0
  - [ ] Notify all listeners
- [ ] Implement `subscribe: ((NotificationTypes.queueState) => unit) => unit => unit`
  - [ ] Add listener to array
  - [ ] Return unsubscribe function
- [ ] Implement `getState: unit => NotificationTypes.queueState`
  - [ ] Return current state
- [ ] Implement `dismiss: (string) => unit`
  - [ ] Find and cancel timer
  - [ ] Remove from queue
  - [ ] Notify listeners
- [ ] Implement `clear: unit => unit`
  - [ ] Cancel all timers
  - [ ] Reset queue to empty
  - [ ] Notify listeners
- [ ] Implement `generateId: unit => string`
  - [ ] Format: "notif-{Date.now()}-{random}"

**Listener Notification**:
- [ ] Create `notifyListeners: NotificationTypes.queueState => unit`
  - [ ] Iterate listeners
  - [ ] Call each with new state

**Auto-dismiss Timer**:
- [ ] Create `scheduleAutoDismiss: (string, int) => unit`
  - [ ] Calculate timeout in milliseconds
  - [ ] Set timer to call dismiss after timeout
  - [ ] Store timedId in map

**Cleanup**:
- [ ] Create `cancelTimer: (string) => unit`
  - [ ] Remove from timer map
  - [ ] Verify cleanup works

**Compilation**:
- [ ] Run `npm run res:build` - verify 0 warnings
- [ ] Verify no `unwrap()` or `panic()` calls

---

## 🧪 Testing

**Verification Steps** (manual - full tests in 1270):
1. Compile: `npm run res:build`
2. Check for warnings: 0 allowed
3. Verify no undefined references to NotificationQueue
4. Check generateId creates unique IDs: Run in console
5. Wait for 1270 to write comprehensive tests

---

## 📊 Code Template

```rescript
// src/core/NotificationManager.res

open NotificationTypes

// Module state
let state: ref<queueState> = ref(NotificationQueue.empty())
let listeners: ref<array<queueState => unit>> = ref([])
let timerIds: ref<Belt.Map.String.t<Js.Global.timeoutId>> = ref(Belt.Map.String.empty)

// Notify all listeners of state change
let notifyListeners = (newState: queueState): unit => {
  Belt.Array.forEach(listeners.contents, listener => {
    listener(newState)
  })
}

// Schedule auto-dismiss timer for a notification
let scheduleAutoDismiss = (notifId: string, duration: int): unit => {
  if duration > 0 {
    let timeoutId = Js.Global.setTimeout(() => {
      dismiss(notifId)
    }, duration)
    timerIds := Belt.Map.String.set(timerIds.contents, notifId, timeoutId)
  }
}

// Cancel timer for a notification
let cancelTimer = (notifId: string): unit => {
  match Belt.Map.String.get(timerIds.contents, notifId) {
  | Some(timeoutId) =>
      Js.Global.clearTimeout(timeoutId)
      timerIds := Belt.Map.String.remove(timerIds.contents, notifId)
  | None => ()
  }
}

// Generate unique notification ID
let generateId = (): string => {
  let timestamp = Js.Date.now() |> Int.fromFloat |> Int.toString
  let random = Js.Math.random() *. 1000000.0 |> Int.fromFloat |> Int.toString
  "notif-" ++ timestamp ++ "-" ++ random
}

// Public API: Dispatch a notification
let dispatch = (notif: notification): unit => {
  let withId = {
    ...notif,
    id: if notif.id === "" {
      generateId()
    } else {
      notif.id
    },
  }
  state := NotificationQueue.enqueue(withId, state.contents)
  scheduleAutoDismiss(withId.id, withId.duration)
  notifyListeners(state.contents)
}

// Public API: Subscribe to state changes
let subscribe = (listener: queueState => unit): (unit => unit) => {
  listeners := Belt.Array.concat(listeners.contents, [listener])

  // Return unsubscribe function
  () => {
    listeners := Belt.Array.keep(listeners.contents, l => l !== listener)
  }
}

// Public API: Get current state
let getState = (): queueState => {
  state.contents
}

// Public API: Dismiss a notification
let dismiss = (notifId: string): unit => {
  cancelTimer(notifId)
  state := NotificationQueue.dismiss(notifId, state.contents)
  notifyListeners(state.contents)
}

// Public API: Clear all notifications
let clear = (): unit => {
  // Cancel all timers
  Belt.Map.String.forEach(timerIds.contents, (_key, timeoutId) => {
    Js.Global.clearTimeout(timeoutId)
  })
  timerIds := Belt.Map.String.empty
  state := NotificationQueue.empty()
  notifyListeners(state.contents)
}
```

---

## 🔍 Quality Gates (Must Pass Before 1270 Starts)

| Gate | Condition | Check |
|------|-----------|-------|
| Compilation | 0 errors, 0 warnings | `npm run res:build` output |
| No Panics | No unwrap/panic | Code review - check for `->Belt.Option.getExn` |
| Type Safety | All types correct | ReScript compiler enforces |
| Module Exports | All functions accessible | Can import in other modules |

---

## 🔄 Rollback Plan

If compilation fails:
1. Check NotificationQueue import: `open NotificationQueue`
2. Verify function names match NotificationQueue module
3. Check Belt.Map.String syntax for timer storage
4. Run `npm run res:fmt` to auto-fix formatting

If state management buggy:
- Verify listener notification happens after state update
- Check unsubscribe function uses reference equality (===)
- Verify timer map cleanup in dismiss()

---

## 💡 Implementation Tips

1. **Test generateId**: Run in browser console to verify format
2. **Listener notification**: Always call notifyListeners after state change
3. **Timer cleanup**: Verify each dismiss() cancels the timer
4. **Pure state updates**: Use NotificationQueue for queue logic, don't duplicate
5. **Compile often**: Catch type errors early

---

## 🚀 Next Tasks

After this compiles successfully:
- **1270: Write NotificationManager tests** (depends on this + 1269)
- **1271: Create NotificationCenter component** (depends on 1266, 1269)
- (1270 and 1271 can start in parallel after 1269 compiles)

---

## 📌 Notes

- **Module State**: Uses ref for mutable state (allowed here - it's behind the public API boundary)
- **Listener Pattern**: Classic pub/sub - each listener gets new state on every change
- **Timer Management**: Must clean up timers on dismiss to prevent memory leaks
- **Scalability**: All downstream modules subscribe via this API
- **Reliability**: Tests in 1270 will verify listener cleanup and state consistency
