/* tests/unit/SimulationAdvancement_v.test.res */
open Vitest
open SimulationAdvancement

describe("SimulationAdvancement", () => {
  let makeContext = (
    ~isFirstScene=false,
    ~currentSceneId=Some("s1"),
    ~completedSceneId=None,
    ~navigationStateIsIdle=true,
    ~operationLifecycleIsBusy=false,
    ~retryCount=0,
    ~maxRetries=3,
    (),
  ) => {
    {
      isFirstScene,
      currentSceneId,
      completedSceneId,
      navigationStateIsIdle,
      operationLifecycleIsBusy,
      retryCount,
      maxRetries,
    }
  }

  describe("Scene Completion Signal Matching", () => {
    test("should advance when completion signal matches current scene", t => {
      let ctx = makeContext(
        ~currentSceneId=Some("s1"),
        ~completedSceneId=Some("s1"),
        (),
      )
      t->expect(evaluate(ctx))->Expect.toEqual(Advance)
    })

    test("should NOT advance when completion signal does not match current scene", t => {
      let ctx = makeContext(
        ~currentSceneId=Some("s2"),
        ~completedSceneId=Some("s1"), // Stale signal
        (),
      )
      // Should retry waiting for correct signal
      t->expect(evaluate(ctx))->Expect.toEqual(Retry({
        count: 1,
        max: 3,
        backoffMs: 0
      }))
    })

    test("should NOT advance when no completion signal is present (unless first scene)", t => {
      let ctx = makeContext(
        ~currentSceneId=Some("s2"),
        ~completedSceneId=None,
        (),
      )
      t->expect(evaluate(ctx))->Expect.toEqual(Retry({
        count: 1,
        max: 3,
        backoffMs: 0
      }))
    })
  })

  describe("First Scene Behavior", () => {
    test("should advance immediately on first scene without waiting for completion signal", t => {
      let ctx = makeContext(
        ~isFirstScene=true,
        ~currentSceneId=Some("s1"),
        ~completedSceneId=None,
        (),
      )
      t->expect(evaluate(ctx))->Expect.toEqual(Advance)
    })

    test("should advance on first scene even with stale signal (though unlikely)", t => {
      let ctx = makeContext(
        ~isFirstScene=true,
        ~currentSceneId=Some("s1"),
        ~completedSceneId=Some("old_signal"),
        (),
      )
      t->expect(evaluate(ctx))->Expect.toEqual(Advance)
    })
  })

  describe("Transition Stabilization / Busy States", () => {
    test("should WAIT if navigation state is not idle", t => {
      let ctx = makeContext(
        ~navigationStateIsIdle=false,
        ~currentSceneId=Some("s1"),
        ~completedSceneId=Some("s1"),
        (),
      )
      t->expect(evaluate(ctx))->Expect.toEqual(Wait({reason: "navigation_not_idle"}))
    })

    test("should WAIT if operation lifecycle is busy", t => {
      let ctx = makeContext(
        ~operationLifecycleIsBusy=true,
        ~currentSceneId=Some("s1"),
        ~completedSceneId=Some("s1"),
        (),
      )
      t->expect(evaluate(ctx))->Expect.toEqual(Wait({reason: "operation_lifecycle_busy"}))
    })
  })

  describe("Retry and Backoff Logic", () => {
    test("should increment retry count and calculate backoff", t => {
      let ctx = makeContext(
        ~retryCount=1,
        ~maxRetries=3,
        ~currentSceneId=Some("s2"),
        ~completedSceneId=None,
        (),
      )
      t->expect(evaluate(ctx))->Expect.toEqual(Retry({
        count: 2,
        max: 3,
        backoffMs: 100 // 100 * retryCount (1)
      }))
    })

    test("should STOP when max retries exceeded", t => {
      let ctx = makeContext(
        ~retryCount=4, // Already exceeded (if max is 3, checking <= max)
        ~maxRetries=3,
        ~currentSceneId=Some("s2"),
        ~completedSceneId=None,
        (),
      )
      // Logic: if retryCount (4) <= max (3) -> false.
      t->expect(evaluate(ctx))->Expect.toEqual(Stop({reason: "max_retries_exceeded_waiting_for_signal"}))
    })
    
    test("should retry up to max count inclusive", t => {
       let ctx = makeContext(
        ~retryCount=3,
        ~maxRetries=3,
        ~currentSceneId=Some("s2"),
        ~completedSceneId=None,
        (),
      )
      // 3 <= 3 is true, so one last retry
      t->expect(evaluate(ctx))->Expect.toEqual(Retry({
        count: 4,
        max: 3,
        backoffMs: 300
      }))
    })
  })
})
