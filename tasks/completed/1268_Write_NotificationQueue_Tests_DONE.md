# 1268: Write NotificationQueue Tests - >90% Coverage

**Status**: Pending
**Priority**: High (Quality gate for 1267, blocks integration)
**Effort**: 1.5 hours
**Dependencies**: 1267 (NotificationQueue.res must exist and compile)
**Scalability**: ⭐⭐⭐⭐⭐ (Independent test module, no blocking)
**Reliability**: ⭐⭐⭐⭐⭐ (Comprehensive test coverage, 8 tests, >90% required)

---

## 🎯 Objective

Write comprehensive unit tests for NotificationQueue.res that verify all queue operations (enqueue, dequeue, dismiss, sorting, deduplication) work correctly. Achieve >90% code coverage. Tests should pass before moving to 1269.

**Outcome**: 8 passing tests, >90% coverage, all edge cases verified, ready for NotificationManager to use queue logic.

---

## 📋 Acceptance Criteria

✅ **Test Coverage**
- 8 unit tests written and passing
- >90% code coverage for NotificationQueue
- All public functions tested
- All edge cases covered

✅ **Test Quality**
- Each test has single, clear assertion
- Test names describe what they verify
- Tests independent (no shared state)
- No flaky tests (deterministic results)

✅ **Functionality Verified**
- ✅ Deduplication: same message <2s = skip
- ✅ No dedup: same message >2s = both shown
- ✅ Priority sort: Error > Warning > Success > Info > Transient
- ✅ Auto-dismiss duration: correct per importance
- ✅ Archived retention: keep 10, delete oldest
- ✅ Enqueue/dequeue lifecycle
- ✅ Dismiss removes from active, moves to archived
- ✅ Edge case: Empty queue

---

## 📝 Implementation Checklist

**Test File Setup**:
- [ ] Create file: `tests/unit/NotificationQueue_v.test.res`
- [ ] Import NotificationQueue and NotificationTypes
- [ ] Create helper functions for test data

**Test 1: Deduplication (same message <2s)**:
- [ ] Create two identical notifications
- [ ] Enqueue first (should succeed)
- [ ] Immediately enqueue second (should skip)
- [ ] Assert pending.length === 1

**Test 2: No dedup (same message >2s)**:
- [ ] Create notification, enqueue (timestamp = now)
- [ ] Create identical notification with timestamp > 2000ms ago
- [ ] Enqueue second notification
- [ ] Assert pending.length === 2 (both added)

**Test 3: Priority sort**:
- [ ] Create 5 notifications in random importance order (Success, Info, Error, Warning, Transient)
- [ ] Enqueue all
- [ ] Assert pending array sorted: [Error, Warning, Success, Info, Transient]

**Test 4: Auto-dismiss duration**:
- [ ] Verify defaultTimeoutMs returns correct values
- [ ] Error: 8000ms ✓
- [ ] Critical: 0ms ✓
- [ ] Warning: 5000ms ✓
- [ ] Success: 3000ms ✓
- [ ] Info: 3000ms ✓
- [ ] Transient: 2000ms ✓

**Test 5: Archived retention (keep 10)**:
- [ ] Create 15 notifications
- [ ] Dismiss all 15 one by one
- [ ] Assert archived.length === 10 (oldest 5 discarded)

**Test 6: Enqueue/dequeue lifecycle**:
- [ ] Start with empty queue
- [ ] Enqueue 5 notifications
- [ ] Assert pending.length === 5, active.length === 0
- [ ] Call dequeue 3 times
- [ ] Assert pending.length === 2, active.length === 3
- [ ] Call dequeue again (should fail, active full)
- [ ] Assert active.length === 3 (unchanged)

**Test 7: Dismiss removes from active**:
- [ ] Enqueue 3 notifications
- [ ] Dequeue them to active
- [ ] Dismiss middle notification
- [ ] Assert active.length === 2
- [ ] Assert archived.length === 1
- [ ] Assert dismissed notification in archived

**Test 8: Edge case - Empty queue**:
- [ ] Create empty queue with `NotificationQueue.empty()`
- [ ] Call getById on non-existent notification
- [ ] Assert returns None
- [ ] Call dequeue on empty pending
- [ ] Assert queue unchanged

---

## 🧪 Testing Framework

**Test Framework**: Vitest with rescript-vitest bindings

**File Structure**:
```rescript
open Vitest
open NotificationQueue
open NotificationTypes

describe("NotificationQueue", () => {
  // Helper: Create test notification
  let makeNotif = (importance, message) => {
    id: "test-" ++ message,
    importance,
    context: Operation("test"),
    message,
    details: None,
    action: None,
    duration: defaultTimeoutMs(importance),
    dismissible: true,
    createdAt: Date.now(),
  }

  test("deduplication: same message within 2s = skip", t => {
    // Test code here
  })

  // ... more tests
})
```

---

## 📊 Code Template

```rescript
// tests/unit/NotificationQueue_v.test.res

open Vitest
open NotificationTypes
open NotificationQueue

describe("NotificationQueue", () => {
  let makeNotif = (importance, message, ~createdAt=?, ()) => {
    id: "test-" ++ message,
    importance,
    context: Operation("test"),
    message,
    details: None,
    action: None,
    duration: defaultTimeoutMs(importance),
    dismissible: true,
    createdAt: switch createdAt {
    | Some(t) => t
    | None => Date.now()
    },
  }

  test("deduplication: same message within 2s = skip", t => {
    let notif1 = makeNotif(Error, "Upload failed")
    let notif2 = makeNotif(Error, "Upload failed")
    let queue = empty()

    let queue2 = enqueue(notif1, queue)
    let queue3 = enqueue(notif2, queue2)

    t->expect(Belt.Array.length(queue3.pending))->Expect.toBe(1)
  })

  test("no dedup: same message >2s apart = both shown", t => {
    let notif1 = makeNotif(Error, "Upload failed", ~createdAt=Date.now() -. 3000.0, ())
    let notif2 = makeNotif(Error, "Upload failed", ~createdAt=Date.now(), ())
    let queue = empty()

    let queue2 = enqueue(notif1, queue)
    let queue3 = enqueue(notif2, queue2)

    t->expect(Belt.Array.length(queue3.pending))->Expect.toBe(2)
  })

  test("priority sort: Error > Warning > Success > Info > Transient", t => {
    let notifs = [
      makeNotif(Success, "Done"),
      makeNotif(Error, "Failed"),
      makeNotif(Info, "Processing"),
      makeNotif(Warning, "Slow"),
      makeNotif(Transient, "Quick"),
    ]

    let queue = Belt.Array.reduce(notifs, empty(), (q, n) => enqueue(n, q))

    let priorities = Belt.Array.map(queue.pending, n => importanceToString(n.importance))
    t->expect(priorities)->Expect.toEqual([
      "error",
      "warning",
      "success",
      "info",
      "transient",
    ])
  })

  test("auto-dismiss duration: correct per importance", t => {
    t->expect(defaultTimeoutMs(Critical))->Expect.toBe(0)
    t->expect(defaultTimeoutMs(Error))->Expect.toBe(8000)
    t->expect(defaultTimeoutMs(Warning))->Expect.toBe(5000)
    t->expect(defaultTimeoutMs(Success))->Expect.toBe(3000)
    t->expect(defaultTimeoutMs(Info))->Expect.toBe(3000)
    t->expect(defaultTimeoutMs(Transient))->Expect.toBe(2000)
  })

  test("archived retention: keep 10, delete oldest", t => {
    let queue = ref(empty())

    // Create and dismiss 15 notifications
    for i in 0 to 14 {
      let notif = makeNotif(Info, "Notif " ++ Int.toString(i))
      queue := dismiss(notif.id, enqueue(notif, queue.contents))
    }

    let archived = queue.contents.archived
    t->expect(Belt.Array.length(archived))->Expect.toBe(10)
  })

  test("enqueue/dequeue lifecycle", t => {
    let queue = ref(empty())

    // Enqueue 5 notifications
    for i in 0 to 4 {
      let notif = makeNotif(Info, "Notif " ++ Int.toString(i))
      queue := enqueue(notif, queue.contents)
    }
    t->expect(Belt.Array.length(queue.contents.pending))->Expect.toBe(5)

    // Dequeue 3 times
    queue := dequeue(queue.contents)
    queue := dequeue(queue.contents)
    queue := dequeue(queue.contents)

    t->expect(Belt.Array.length(queue.contents.pending))->Expect.toBe(2)
    t->expect(Belt.Array.length(queue.contents.active))->Expect.toBe(3)

    // Try to dequeue again (should fail - active full)
    let before = queue.contents.active
    queue := dequeue(queue.contents)
    let after = queue.contents.active

    t->expect(Belt.Array.length(after))->Expect.toBe(Belt.Array.length(before))
  })

  test("dismiss removes from active and archives", t => {
    let queue = ref(empty())

    // Create and enqueue 3 notifications
    let notifs = [
      makeNotif(Info, "First"),
      makeNotif(Info, "Second"),
      makeNotif(Info, "Third"),
    ]

    let baseQueue = empty()
    queue := Belt.Array.reduce(notifs, baseQueue, (q, n) => enqueue(n, q))
    queue := dequeue(queue.contents)
    queue := dequeue(queue.contents)
    queue := dequeue(queue.contents)

    // Dismiss the second one
    let secondId = (Belt.Array.get(notifs, 1)->Belt.Option.getExn).id
    queue := dismiss(secondId, queue.contents)

    t->expect(Belt.Array.length(queue.contents.active))->Expect.toBe(2)
    t->expect(Belt.Array.length(queue.contents.archived))->Expect.toBe(1)
  })

  test("edge case: operations on empty queue", t => {
    let queue = empty()

    t->expect(getById("nonexistent", queue))->Expect.toEqual(None)
    t->expect(Belt.Array.length(queue.pending))->Expect.toBe(0)

    let dequeued = dequeue(queue)
    t->expect(Belt.Array.length(dequeued.pending))->Expect.toBe(0)
  })
})
```

---

## 🔍 Quality Gates (Must Pass Before 1269 Starts)

| Gate | Condition | Check |
|------|-----------|-------|
| Test Count | 8 tests written | `npm run test:frontend -- NotificationQueue` |
| All Pass | 100% passing | All tests green in Vitest output |
| Coverage | >90% for NotificationQueue | Vitest coverage report |
| No Flakes | Consistent results | Run tests 3x, same results each time |

---

## 🔄 Rollback Plan

If tests fail:
1. Check timestamp calculations: `Date.now() -. createdAt < 2000.0` must work
2. Verify dedup logic: Check `dedupKey` function in NotificationTypes
3. Check array sorting: Verify `importancePriority` returns 0-5
4. Debug: Add `Logger.debug` calls to see intermediate values
5. Re-run: `npm run res:build && npm run test:frontend`

If coverage <90%:
- Identify uncovered lines: Check Vitest coverage report
- Add tests for missing branches
- Check edge cases in dismiss/dequeue logic

---

## 💡 Testing Tips

1. **Use helper function**: `makeNotif` creates consistent test data
2. **Test state immutability**: Verify original queue unchanged after operations
3. **Test edge cases**: Empty queue, single item, boundary conditions
4. **Debug with Logger**: If dedup logic wrong, use Logger.debug to inspect createdAt
5. **Run often**: `npm run test:watch` for fast feedback

---

## 🚀 Next Tasks

After all tests pass with >90% coverage:
- **1269: Create NotificationManager** (depends on 1266, 1267)
- **1270: Write NotificationManager tests** (depends on 1269, can start after 1269 compiles)

---

## 📌 Notes

- **Quality Gate**: 1267 must compile before starting this task
- **Dependency**: Vitest framework must be working (npm run test:frontend)
- **Coverage**: >90% is hard requirement, not optional
- **Scalability**: Tests take <5 seconds to run (fast feedback)
- **Reliability**: Pure function tests are inherently reliable (no flakes)
