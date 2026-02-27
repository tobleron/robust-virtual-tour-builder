// @efficiency: infra-adapter
open Vitest

@module("vitest") @scope("vi") external useFakeTimers: unit => unit = "useFakeTimers"
@module("vitest") @scope("vi") external useRealTimers: unit => unit = "useRealTimers"
@module("vitest") @scope("vi") external advanceTimersByTime: int => unit = "advanceTimersByTime"
@module("vitest") @scope("vi") external setSystemTime: float => unit = "setSystemTime"

describe("OperationLifecycle", () => {
  beforeEach(() => {
    useFakeTimers()
    setSystemTime(1000.0) // predictable start time
    OperationLifecycle.reset()
  })

  afterEach(() => {
    useRealTimers()
  })

  test("starts operation correctly", t => {
    let id = OperationLifecycle.start(
      ~type_=OperationLifecycle.Navigation,
      ~scope=OperationLifecycle.Ambient,
      (),
    )
    let op = OperationLifecycle.getOperation(id)

    switch op {
    | Some(task) => {
        t->expect(task.id)->Expect.toBe(id)
        t->expect(task.type_)->Expect.toBe(OperationLifecycle.Navigation)
        t->expect(task.scope)->Expect.toBe(OperationLifecycle.Ambient)
        t
        ->expect(task.status)
        ->Expect.toEqual(OperationLifecycle.Active({progress: 0.0, message: None}))
      }
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("completes operation correctly", t => {
    let id = OperationLifecycle.start(~type_=OperationLifecycle.Navigation, ())
    OperationLifecycle.complete(id, ~result="Done", ())
    let op = OperationLifecycle.getOperation(id)

    switch op {
    | Some(task) =>
      t
      ->expect(task.status)
      ->Expect.toEqual(OperationLifecycle.Completed({result: Some("Done")}))
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("fails operation correctly", t => {
    let id = OperationLifecycle.start(~type_=OperationLifecycle.Navigation, ())
    OperationLifecycle.fail(id, "Error occurred")
    let op = OperationLifecycle.getOperation(id)

    switch op {
    | Some(task) =>
      t
      ->expect(task.status)
      ->Expect.toEqual(OperationLifecycle.Failed({error: "Error occurred"}))
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("auto-cleanup after completion", t => {
    let id = OperationLifecycle.start(~type_=OperationLifecycle.Navigation, ())
    OperationLifecycle.complete(id, ())

    // Default cleanup is 5000ms
    advanceTimersByTime(5000)

    let op = OperationLifecycle.getOperation(id)
    t->expect(op)->Expect.toBe(None)
  })

  test("auto-cleanup after failure", t => {
    let id = OperationLifecycle.start(~type_=OperationLifecycle.Navigation, ())
    OperationLifecycle.fail(id, "oops")

    // Default cleanup is 10000ms
    advanceTimersByTime(10000)

    let op = OperationLifecycle.getOperation(id)
    t->expect(op)->Expect.toBe(None)
  })

  test("sets default visibility threshold correctly", t => {
    let navId = OperationLifecycle.start(~type_=OperationLifecycle.Navigation, ())
    let navOp = OperationLifecycle.getOperation(navId)->Option.getOrThrow
    t->expect(navOp.visibleAfterMs)->Expect.toBe(1200)

    let upId = OperationLifecycle.start(~type_=OperationLifecycle.Upload, ())
    let upOp = OperationLifecycle.getOperation(upId)->Option.getOrThrow
    t->expect(upOp.visibleAfterMs)->Expect.toBe(700)

    let thumbId = OperationLifecycle.start(~type_=OperationLifecycle.ThumbnailGeneration, ())
    let thumbOp = OperationLifecycle.getOperation(thumbId)->Option.getOrThrow
    t->expect(thumbOp.visibleAfterMs)->Expect.toBe(1500)

    let projId = OperationLifecycle.start(~type_=OperationLifecycle.ProjectLoad, ())
    let projOp = OperationLifecycle.getOperation(projId)->Option.getOrThrow
    t->expect(projOp.visibleAfterMs)->Expect.toBe(500)
  })

  test("overrides default visibility threshold", t => {
    let id = OperationLifecycle.start(~type_=OperationLifecycle.Navigation, ~visibleAfterMs=100, ())
    let op = OperationLifecycle.getOperation(id)->Option.getOrThrow
    t->expect(op.visibleAfterMs)->Expect.toBe(100)
  })

  test("tracks completion stats", t => {
    let id = OperationLifecycle.start(~type_=OperationLifecycle.Upload, ())
    OperationLifecycle.complete(id, ())
    let stats = OperationLifecycle.getStats()

    t->expect(stats.active)->Expect.toBe(0)
    t->expect(stats.completedTotal)->Expect.toBe(1)
    t->expect(stats.leakedTotal)->Expect.toBe(0)
  })

  test("fails expired active operations on ttl sweep and tracks leaked stats", t => {
    let id = OperationLifecycle.start(~type_=OperationLifecycle.Navigation, ())

    // Sweep runs every 30s; expiry requires elapsed > 30s.
    // First sweep @30s does not expire, second sweep @60s does.
    advanceTimersByTime(61000)

    let op = OperationLifecycle.getOperation(id)
    switch op {
    | Some(task) =>
      t
      ->expect(task.status)
      ->Expect.toEqual(OperationLifecycle.Failed({error: "OPERATION_TIMEOUT_TTL_EXCEEDED"}))
    | None => t->expect(false)->Expect.toBe(true)
    }

    let stats = OperationLifecycle.getStats()
    t->expect(stats.active)->Expect.toBe(0)
    t->expect(stats.leakedTotal)->Expect.toBe(1)
  })
})
