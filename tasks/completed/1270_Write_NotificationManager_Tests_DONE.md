# 1270: Write NotificationManager Tests - >85% Coverage

**Status**: Pending
**Priority**: High (Quality gate for 1269, blocks integration)
**Effort**: 1.5 hours
**Dependencies**: 1269 (NotificationManager.res must exist and compile)
**Can Parallelize With**: 1268 (independent test modules)
**Scalability**: ⭐⭐⭐⭐⭐ (Independent test module)
**Reliability**: ⭐⭐⭐⭐⭐ (State management tests - critical for reliability)

---

## 🎯 Objective

Write unit tests for NotificationManager.res that verify state management, listener pattern, timer cleanup, and public API correctness. Achieve >85% code coverage. Tests verify that state changes notify listeners and timers are properly managed.

**Outcome**: 4 passing tests, >85% coverage, all critical state management verified, ready for NotificationCenter to subscribe to.

---

## 📋 Acceptance Criteria

✅ **Test Coverage**
- 4 unit tests written and passing
- >85% code coverage for NotificationManager
- All public functions tested
- Edge cases covered (cleanup, multiple listeners)

✅ **Test Quality**
- Each test has single, clear assertion
- Test names describe what they verify
- Tests independent (no shared manager state)
- No flaky tests

✅ **Functionality Verified**
- ✅ Subscribe: listener receives state updates
- ✅ Listener cleanup: unsubscribe prevents future updates
- ✅ Dismiss: removes from active, cancels timer
- ✅ Multiple listeners work independently

---

## 📝 Implementation Checklist

**Test File Setup**:
- [ ] Create file: `tests/unit/NotificationManager_v.test.res`
- [ ] Import NotificationManager and NotificationTypes
- [ ] Create helper functions for test data

**Test 1: Subscribe and listener receives updates**:
- [ ] Reset manager state
- [ ] Create listener callback
- [ ] Subscribe listener
- [ ] Dispatch notification
- [ ] Assert listener was called
- [ ] Assert listener received updated state

**Test 2: Listener cleanup - unsubscribe prevents updates**:
- [ ] Create and subscribe listener
- [ ] Dispatch first notification (listener called)
- [ ] Get unsubscribe function and call it
- [ ] Dispatch second notification
- [ ] Assert listener was NOT called for second notification

**Test 3: Dismiss removes from active and cancels timer**:
- [ ] Clear manager state
- [ ] Create notification with auto-dismiss timer
- [ ] Dispatch notification
- [ ] Wait minimal time (ensure timer is set)
- [ ] Call dismiss
- [ ] Assert notification removed from active
- [ ] Assert timer canceled (doesn't fire after dismiss)

**Test 4: Multiple listeners work independently**:
- [ ] Create listener1 and listener2
- [ ] Subscribe both
- [ ] Dispatch notification
- [ ] Assert both listeners called
- [ ] Unsubscribe listener1
- [ ] Dispatch second notification
- [ ] Assert listener2 called but listener1 not called

---

## 🧪 Testing Framework

**Test Framework**: Vitest with rescript-vitest bindings

**Challenge**: Managing module state between tests
- Solution: Use `NotificationManager.clear()` before each test
- Solution: Don't rely on global state being reset (test in isolation)

---

## 📊 Code Template

```rescript
// tests/unit/NotificationManager_v.test.res

open Vitest
open NotificationManager
open NotificationTypes

describe("NotificationManager", () => {
  let makeNotif = (importance, message) => {
    id: "",  // Let manager generate ID
    importance,
    context: Operation("test"),
    message,
    details: None,
    action: None,
    duration: 1000,  // 1 second auto-dismiss
    dismissible: true,
    createdAt: Date.now(),
  }

  beforeEach(() => {
    // Clear manager before each test
    NotificationManager.clear()
  })

  test("subscribe: listener receives state updates", t => {
    let listenerCalled = ref(false)
    let capturedState = ref(None)

    let unsubscribe = NotificationManager.subscribe(newState => {
      listenerCalled := true
      capturedState := Some(newState)
    })

    let notif = makeNotif(Info, "Test message")
    NotificationManager.dispatch(notif)

    t->expect(listenerCalled.contents)->Expect.toBe(true)
    match capturedState.contents {
    | Some(state) =>
        let activeCount = Belt.Array.length(state.active)
        t->expect(activeCount)->Expect.toBeGreaterThan(0)
    | None => t->expect(false)->Expect.toBe(true)  // Should have state
    }
  })

  test("listener cleanup: unsubscribe prevents future updates", t => {
    let callCount = ref(0)

    let unsubscribe = NotificationManager.subscribe(_newState => {
      callCount := callCount.contents + 1
    })

    // First dispatch - listener should be called
    let notif1 = makeNotif(Info, "First")
    NotificationManager.dispatch(notif1)
    let firstCount = callCount.contents

    // Unsubscribe
    unsubscribe()

    // Second dispatch - listener should NOT be called
    let notif2 = makeNotif(Info, "Second")
    NotificationManager.dispatch(notif2)
    let secondCount = callCount.contents

    t->expect(firstCount)->Expect.toBeGreaterThan(0)
    t->expect(secondCount)->Expect.toBe(firstCount)  // Count unchanged
  })

  test("dismiss: removes from active and cancels timer", t => {
    let notif = makeNotif(Error, "Error message")
    NotificationManager.dispatch(notif)

    let stateAfterDispatch = NotificationManager.getState()
    let activeCountBefore = Belt.Array.length(stateAfterDispatch.active)

    // Get the ID that was generated
    let notifIdOpt = Belt.Array.get(stateAfterDispatch.active, 0)

    match notifIdOpt {
    | Some(n) =>
        NotificationManager.dismiss(n.id)
        let stateAfterDismiss = NotificationManager.getState()
        let activeCountAfter = Belt.Array.length(stateAfterDismiss.active)

        t->expect(activeCountBefore)->Expect.toBeGreaterThan(0)
        t->expect(activeCountAfter)->Expect.toBe(0)
    | None => t->expect(false)->Expect.toBe(true)  // Should have found notification
    }
  })

  test("multiple listeners work independently", t => {
    let listener1Called = ref(false)
    let listener2Called = ref(false)

    let unsub1 = NotificationManager.subscribe(_state => {
      listener1Called := true
    })

    let unsub2 = NotificationManager.subscribe(_state => {
      listener2Called := true
    })

    // Both should be called
    let notif = makeNotif(Info, "Test")
    NotificationManager.dispatch(notif)

    let bothCalledAfterFirst = listener1Called.contents && listener2Called.contents
    t->expect(bothCalledAfterFirst)->Expect.toBe(true)

    // Reset and unsubscribe listener1
    listener1Called := false
    listener2Called := false
    unsub1()

    // Dispatch again - only listener2 should be called
    let notif2 = makeNotif(Info, "Test 2")
    NotificationManager.dispatch(notif2)

    t->expect(listener1Called.contents)->Expect.toBe(false)
    t->expect(listener2Called.contents)->Expect.toBe(true)
  })
})
```

---

## 🔍 Quality Gates (Must Pass Before 1271 Starts)

| Gate | Condition | Check |
|------|-----------|-------|
| Test Count | 4 tests written | `npm run test:frontend -- NotificationManager` |
| All Pass | 100% passing | All tests green in Vitest output |
| Coverage | >85% for NotificationManager | Vitest coverage report |
| No Flakes | Consistent results | Run tests 3x, same results each time |

---

## 🔄 Rollback Plan

If tests fail:
1. Check listener callback syntax: `_state => { ... }`
2. Verify unsubscribe function is called correctly
3. Check clearTimeout is actually canceling timers
4. Use Logger.debug to trace listener calls

If coverage <85%:
- Identify uncovered lines in coverage report
- Check timer cleanup path in dismiss()
- Check listener array iteration in notifyListeners()
- Add tests for edge cases

---

## 💡 Testing Tips

1. **Use beforeEach**: Reset manager state before each test
2. **Check listener call count**: Use ref to track invocations
3. **Test cleanup**: Verify unsubscribe actually removes listener
4. **Timer verification**: Hard to test actual timeout, but can verify cleanup path
5. **Immutability**: Listeners should receive new state objects

---

## 🚀 Next Tasks

After all tests pass with >85% coverage:
- **1271: Create NotificationCenter component** (can start in parallel after 1269 compiles)
- **1272: Add backward compat to EventBus** (can start after 1269 compiles)

---

## 📌 Notes

- **Dependency**: 1269 must compile before starting this task
- **State Management**: Tests verify pub/sub pattern works correctly
- **Cleanup Testing**: Hard to test actual timeout behavior, so focus on timer setup/cleanup
- **Scalability**: Tests take <5 seconds to run (fast feedback)
- **Reliability**: State management tests are critical - verify no memory leaks
