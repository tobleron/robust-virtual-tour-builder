// tests/unit/NotificationQueue_v.test.res
// Comprehensive unit tests for NotificationQueue pure logic
// Tests: deduplication, priority sorting, lifecycle, edge cases
// Coverage target: >90%

open Vitest
open NotificationQueue

describe("NotificationQueue", () => {
  // Helper: Create a test notification with given importance and message
  let makeNotif = (
    importance: NotificationTypes.importance,
    message: string,
    ~createdAt=?,
    (),
  ): NotificationTypes.notification => {
    {
      id: "test-" ++ message,
      importance,
      context: NotificationTypes.Operation("test"),
      message,
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(importance),
      dismissible: true,
      createdAt: switch createdAt {
      | Some(t) => t
      | None => Date.now()
      },
    }
  }

  // Test 1: Deduplication - same message within 2s = skip
  test("deduplication: same message within 2s = skip", t => {
    let now = Date.now()
    let notif1 = makeNotif(NotificationTypes.Error, "Upload failed", ~createdAt=now, ())
    let notif2 = makeNotif(NotificationTypes.Error, "Upload failed", ~createdAt=now +. 100.0, ())

    let queue = empty()
    let queue2 = enqueue(notif1, queue)
    let queue3 = enqueue(notif2, queue2)

    let pendingCount = Belt.Array.length(queue3.pending)
    t->expect(pendingCount)->Expect.toBe(1)
  })

  // Test 2: No dedup - same message >2s apart = both shown
  test("no dedup: same message >2s apart = both shown", t => {
    let now = Date.now()
    let notif1 = makeNotif(NotificationTypes.Error, "Upload failed", ~createdAt=now -. 3000.0, ())
    let notif2 = makeNotif(NotificationTypes.Error, "Upload failed", ~createdAt=now, ())

    let queue = empty()
    let queue2 = enqueue(notif1, queue)
    let queue3 = enqueue(notif2, queue2)

    let pendingCount = Belt.Array.length(queue3.pending)
    t->expect(pendingCount)->Expect.toBe(2)
  })

  // Test 3: Priority sort - Error > Warning > Success > Info > Transient
  test("priority sort: Error > Warning > Success > Info > Transient", t => {
    let notifs = [
      makeNotif(NotificationTypes.Success, "Done", ()),
      makeNotif(NotificationTypes.Error, "Failed", ()),
      makeNotif(NotificationTypes.Info, "Processing", ()),
      makeNotif(NotificationTypes.Warning, "Slow", ()),
      makeNotif(NotificationTypes.Transient, "Quick", ()),
    ]

    let queue = empty()
    let queue2 = Belt.Array.reduce(notifs, queue, (q, n) => enqueue(n, q))

    // Extract importance from sorted pending array
    let sortedImportances = Belt.Array.map(
      queue2.pending,
      n => NotificationTypes.importanceToString(n.importance),
    )

    t
    ->expect(sortedImportances)
    ->Expect.toEqual(["error", "warning", "success", "info", "transient"])
  })

  // Test 4: Auto-dismiss duration - correct per importance
  test("auto-dismiss duration: correct per importance", t => {
    t->expect(NotificationTypes.defaultTimeoutMs(NotificationTypes.Critical))->Expect.toBe(0)
    t->expect(NotificationTypes.defaultTimeoutMs(NotificationTypes.Error))->Expect.toBe(8000)
    t->expect(NotificationTypes.defaultTimeoutMs(NotificationTypes.Warning))->Expect.toBe(5000)
    t->expect(NotificationTypes.defaultTimeoutMs(NotificationTypes.Success))->Expect.toBe(3000)
    t->expect(NotificationTypes.defaultTimeoutMs(NotificationTypes.Info))->Expect.toBe(3000)
    t->expect(NotificationTypes.defaultTimeoutMs(NotificationTypes.Transient))->Expect.toBe(2000)
  })

  // Test 5: Archived retention - keep 10, delete oldest
  test("archived retention: keep 10, delete oldest", t => {
    let queue = ref(empty())

    // Create 15 notifications and move them through: pending → active → archived
    for i in 0 to 14 {
      let notif = makeNotif(NotificationTypes.Info, "Notif " ++ Int.toString(i), ())
      // Enqueue (to pending)
      queue := enqueue(notif, queue.contents)
      // Dequeue (to active)
      queue := dequeue(queue.contents)
      // Dismiss (to archived)
      queue := dismiss(notif.id, queue.contents)
    }

    let archivedCount = Belt.Array.length(queue.contents.archived)
    t->expect(archivedCount)->Expect.toBe(10)
  })

  // Test 6: Enqueue/dequeue lifecycle
  test("enqueue/dequeue lifecycle", t => {
    let queue = ref(empty())

    // Enqueue 5 notifications
    for i in 0 to 4 {
      let notif = makeNotif(NotificationTypes.Info, "Notif " ++ Int.toString(i), ())
      queue := enqueue(notif, queue.contents)
    }
    t->expect(Belt.Array.length(queue.contents.pending))->Expect.toBe(5)
    t->expect(Belt.Array.length(queue.contents.active))->Expect.toBe(0)

    // Dequeue 3 times (max 3 active)
    queue := dequeue(queue.contents)
    queue := dequeue(queue.contents)
    queue := dequeue(queue.contents)

    t->expect(Belt.Array.length(queue.contents.pending))->Expect.toBe(2)
    t->expect(Belt.Array.length(queue.contents.active))->Expect.toBe(3)

    // Try to dequeue again (should fail - active full)
    let stateBefore = queue.contents.active
    queue := dequeue(queue.contents)
    let stateAfter = queue.contents.active

    t->expect(Belt.Array.length(stateAfter))->Expect.toBe(Belt.Array.length(stateBefore))
  })

  // Test 7: Dismiss removes from active and archives
  test("dismiss removes from active and archives", t => {
    let queue = ref(empty())

    // Create 3 notifications
    let notifs = [
      makeNotif(NotificationTypes.Info, "First", ()),
      makeNotif(NotificationTypes.Info, "Second", ()),
      makeNotif(NotificationTypes.Info, "Third", ()),
    ]

    let baseQueue = empty()
    queue := Belt.Array.reduce(notifs, baseQueue, (q, n) => enqueue(n, q))

    // Move all to active (dequeue 3 times)
    queue := dequeue(queue.contents)
    queue := dequeue(queue.contents)
    queue := dequeue(queue.contents)

    t->expect(Belt.Array.length(queue.contents.active))->Expect.toBe(3)

    // Get ID of second notification to dismiss
    let secondIdOpt = Belt.Array.get(queue.contents.active, 1)

    switch secondIdOpt {
    | Some(notif) => {
        queue := dismiss(notif.id, queue.contents)

        // Verify: active reduced by 1, archived increased by 1
        t->expect(Belt.Array.length(queue.contents.active))->Expect.toBe(2)
        t->expect(Belt.Array.length(queue.contents.archived))->Expect.toBe(1)
      }
    | None => t->expect(false)->Expect.toBe(true) // Should have found notification
    }
  })

  // Test 8: Edge case - operations on empty queue
  test("edge case: operations on empty queue", t => {
    let queue = empty()

    // Test getById on empty queue
    let notFound = getById("nonexistent", queue)
    t->expect(notFound)->Expect.toEqual(None)

    // Test dequeue on empty pending
    let emptyPending = Belt.Array.length(queue.pending)
    t->expect(emptyPending)->Expect.toBe(0)

    let dequeueResult = dequeue(queue)
    t->expect(Belt.Array.length(dequeueResult.pending))->Expect.toBe(0)
    t->expect(Belt.Array.length(dequeueResult.active))->Expect.toBe(0)
    t->expect(Belt.Array.length(dequeueResult.archived))->Expect.toBe(0)

    // Test dismiss on empty queue (should not crash)
    let dismissResult = dismiss("nonexistent", queue)
    t->expect(Belt.Array.length(dismissResult.active))->Expect.toBe(0)
  })
})
