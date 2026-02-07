# 1267: Create NotificationQueue.res - Pure Queue Logic

**Status**: Pending
**Priority**: High (Foundation - blocks tests and manager)
**Effort**: 1.5 hours
**Dependencies**: 1266 (NotificationTypes.res - must compile first)
**Scalability**: ⭐⭐⭐⭐⭐ (Pure functional logic, fully parallelizable with 1269)
**Reliability**: ⭐⭐⭐⭐⭐ (100% deterministic, testable in isolation)

---

## 🎯 Objective

Implement the pure stateless queue logic that manages notification lifecycle: enqueuing, dequeuing, deduplication, priority sorting, and dismissal. This module contains NO side effects - it's pure functional logic that takes a `queueState` and returns a new `queueState`.

**Outcome**: Complete queue module with all operations, tested thoroughly in 1268, ready for NotificationManager to wrap with state.

---

## 📋 Acceptance Criteria

✅ **Code Quality**
- Zero ReScript compilation errors
- Zero compiler warnings
- All functions pure (no mutable state, no side effects)
- >90% test coverage (achieved in task 1268)

✅ **Functionality**
- `enqueue`: Add notification, apply dedup, sort by importance
- `dequeue`: Move first pending to active (max 3 active)
- `dismiss`: Remove from active, move to archived (keep max 10)
- `sortByImportance`: Sort array by importance priority
- `shouldDeduplicate`: Check if notification is duplicate
- `getById`: Find notification by ID
- `empty`: Create empty queue state

✅ **Deduplication Logic**
- Same `dedupKey` within 2 seconds = skip notification
- Different key or >2 seconds apart = both shown
- Timestamp comparison working correctly

✅ **Priority Sorting**
- Error notifications appear first
- Critical only used for forced modals (rare)
- Success messages appear last
- Sorting deterministic and consistent

---

## 📝 Implementation Checklist

**Queue Operations**:
- [ ] Implement `empty: unit => NotificationTypes.queueState`
- [ ] Implement `enqueue: (NotificationTypes.notification, NotificationTypes.queueState) => NotificationTypes.queueState`
  - [ ] Check for deduplication
  - [ ] Add to pending array if not duplicate
  - [ ] Sort pending by importance
- [ ] Implement `dequeue: (NotificationTypes.queueState) => NotificationTypes.queueState`
  - [ ] Move first pending to active
  - [ ] Only if active.length < 3
- [ ] Implement `dismiss: (string, NotificationTypes.queueState) => NotificationTypes.queueState`
  - [ ] Remove from active by ID
  - [ ] Add to archived
  - [ ] Keep only last 10 archived

**Helper Functions**:
- [ ] Implement `sortByImportance: array<NotificationTypes.notification> => array<NotificationTypes.notification>`
  - [ ] Use `importancePriority` helper from Types
- [ ] Implement `shouldDeduplicate: (NotificationTypes.notification, NotificationTypes.queueState) => bool`
  - [ ] Check pending array for same dedupKey
  - [ ] Check if <2 seconds old
- [ ] Implement `getById: (string, NotificationTypes.queueState) => option<NotificationTypes.notification>`
  - [ ] Search across all three arrays (pending, active, archived)

**Quality**:
- [ ] Run `npm run res:build` - verify 0 warnings
- [ ] No mutable state - all functions return new queueState
- [ ] All pattern matches exhaustive

---

## 🧪 Testing

**Verification Steps** (manual before unit tests):
1. Compile: `npm run res:build`
2. Verify zero warnings: Check compiler output
3. Check exports: `src/core/NotificationQueue.bs.js` exists
4. Wait for task 1268 to write and run unit tests

**Unit Tests Coverage** (will be done in task 1268):
- [ ] Test deduplication: same message within 2s = skip
- [ ] Test no dedup: same message >2s apart = both shown
- [ ] Test priority sort: Error > Warning > Success > Info > Transient
- [ ] Test auto-dismiss duration applied correctly
- [ ] Test archived retention: keep 10, delete oldest
- [ ] Test enqueue/dequeue lifecycle
- [ ] Test dismiss removes from active, moves to archived
- [ ] Test edge case: Empty queue

---

## 📊 Code Template

```rescript
// src/core/NotificationQueue.res

open NotificationTypes

let empty = (): queueState => {
  pending: [],
  active: [],
  archived: [],
}

let sortByImportance = (notifications: array<notification>): array<notification> => {
  Belt.Array.copy(notifications)
  |> Belt.Array.sort(_, (a, b) => {
    let aPriority = importancePriority(a.importance)
    let bPriority = importancePriority(b.importance)
    Pervasives.compare(aPriority, bPriority)
  })
}

let shouldDeduplicate = (notif: notification, state: queueState): bool => {
  let key = dedupKey(notif)
  let now = Date.now()
  let twoSecsMs = 2000.0

  Belt.Array.some(state.pending, existingNotif => {
    dedupKey(existingNotif) === key &&
    now -. existingNotif.createdAt < twoSecsMs
  })
}

let enqueue = (notif: notification, state: queueState): queueState => {
  if shouldDeduplicate(notif, state) {
    // Skip duplicate
    state
  } else {
    // Add to pending and sort
    let newPending = Belt.Array.concat(state.pending, [notif])
    {
      ...state,
      pending: sortByImportance(newPending),
    }
  }
}

let dequeue = (state: queueState): queueState => {
  if Belt.Array.length(state.active) >= 3 || Belt.Array.length(state.pending) === 0 {
    // Can't add more active or nothing to dequeue
    state
  } else {
    // Move first pending to active
    let (first, rest) = Belt.Array.splitAt(state.pending, 1)
    match Belt.Array.get(first, 0) {
    | Some(notif) => {
        ...state,
        pending: rest,
        active: Belt.Array.concat(state.active, [notif]),
      }
    | None => state
    }
  }
}

let dismiss = (notifId: string, state: queueState): queueState => {
  // Find and remove from active
  let newActive = Belt.Array.keep(state.active, notif => notif.id !== notifId)
  let dismissedOpt = Belt.Array.find(state.active, notif => notif.id === notifId)

  match dismissedOpt {
  | Some(dismissed) => {
      // Add to archived, keep only last 10
      let newArchived = Belt.Array.concat(state.archived, [dismissed])
      let trimmedArchived =
        if Belt.Array.length(newArchived) > 10 {
          Belt.Array.sliceToEnd(newArchived, Belt.Array.length(newArchived) - 10)
        } else {
          newArchived
        }
      {
        pending: state.pending,
        active: newActive,
        archived: trimmedArchived,
      }
    }
  | None => state
  }
}

let getById = (notifId: string, state: queueState): option<notification> => {
  let inPending = Belt.Array.find(state.pending, n => n.id === notifId)
  match inPending {
  | Some(n) => Some(n)
  | None =>
      let inActive = Belt.Array.find(state.active, n => n.id === notifId)
      match inActive {
      | Some(n) => Some(n)
      | None => Belt.Array.find(state.archived, n => n.id === notifId)
      }
  }
}
```

---

## 🔍 Quality Gates (Must Pass Before 1268 Starts)

| Gate | Condition | Check |
|------|-----------|-------|
| Compilation | 0 errors, 0 warnings | `npm run res:build` output |
| Purity | No side effects | Code review - no mutable state |
| Determinism | Same input → same output | Logic review |
| Dedup Logic | 2-second window works | Wait for 1268 tests |

---

## 🔄 Rollback Plan

If compilation fails:
1. Check pattern match exhaustiveness (ReScript enforces)
2. Verify array operations: `Belt.Array.concat`, `Belt.Array.keep`, `Belt.Array.find`
3. Check type alignment with NotificationTypes
4. Run `npm run res:fmt` to auto-fix

If dedup logic is wrong:
- Verify 2-second comparison: `now -. createdAt < 2000.0`
- Check dedupKey uses context + message (from Types helper)
- Add Logger.debug calls to diagnose timestamp comparisons

---

## 💡 Implementation Tips

1. **Pure functional approach**: Every function takes queueState, returns new queueState
2. **Use Belt.Array for immutability**: Never mutate arrays, always `concat` or `copy`
3. **Test deduplication first**: It's the trickiest logic
4. **Sorting algorithm**: Use `importancePriority` from Types for consistent ordering
5. **Compile often**: Catch type errors early

---

## 🚀 Next Tasks

After this compiles successfully:
- **1268: Write NotificationQueue tests** (depends on 1267)
- **1269: Create NotificationManager** (can start in parallel - also depends only on 1266)
- **1270: Write NotificationManager tests** (can start in parallel after 1269)

---

## 📌 Notes

- **Pure logic module** - no side effects, no React, no EventBus, just data transformation
- **Testable in isolation** - no external dependencies, fully deterministic
- **Foundation for NotificationManager** - will wrap this with state management and timers
- **Scalability**: Easy to test, easy to profile, easy to optimize if needed
- **Reliability**: Pure functions = no hidden bugs, 100% predictable behavior
