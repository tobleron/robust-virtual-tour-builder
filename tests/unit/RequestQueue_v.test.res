// @efficiency: infra-adapter
/* tests/unit/RequestQueue_v.test.res */
open Vitest
open RequestQueue

describe("RequestQueue", () => {
  afterEach(() => {
    let _ = drain()
    paused := false
    activeCount := 0
  })

  test("Module exists and can schedule tasks", t => {
    // Synchronous trigger
    let _ = schedule(() => Promise.resolve())
    t->expect(true)->Expect.toBe(true)
  })

  test("maxConcurrent is defined", t => {
    t->expect(maxConcurrent)->Expect.toBe(6)
  })

  test("maxQueued is defined", t => {
    t->expect(maxQueued > 0)->Expect.toBe(true)
  })

  test("activeCount is accessible and non-negative", t => {
    t->expect(activeCount.contents >= 0)->Expect.toBe(true)
  })

  testAsync("schedule executes task and returns result", async t => {
    let result = await schedule(() => Promise.resolve(42))
    t->expect(result)->Expect.toBe(42)
  })

  testAsync("tasks are queued and limited by maxConcurrent", async t => {
    let results = []

    // Schedule 10 tasks that take some time
    for i in 1 to 10 {
      let _ = schedule(
        async () => {
          let _ = await Promise.make(
            (resolve, _) => {
              let _ = ReBindings.Window.setTimeout(() => resolve(ignore()), 50)
            },
          )
          let _ = Array.push(results, i)
        },
      )
    }

    // activeCount should be at most maxConcurrent
    t->expect(activeCount.contents <= maxConcurrent)->Expect.toBe(true)

    // Wait for all tasks to complete
    let _ = await Promise.make(
      (resolve, _) => {
        let _ = ReBindings.Window.setTimeout(() => resolve(ignore()), 500)
      },
    )

    t->expect(Array.length(results))->Expect.toBe(10)
    t->expect(activeCount.contents)->Expect.toBe(0)
  })

  testAsync("schedule rejects when queue is over capacity", async t => {
    let started = ref(0)
    let blocker = async () => {
      started := started.contents + 1
      let _ = await Promise.make(
        (resolve, _) => {
          let _ = ReBindings.Window.setTimeout(() => resolve(ignore()), 250)
        },
      )
    }

    // Fill active workers.
    for _i in 1 to maxConcurrent {
      let _ = schedule(blocker)
    }
    // Fill pending queue.
    for _i in 1 to maxQueued {
      let _ = schedule(blocker)
    }

    let overflowResult = await schedule(blocker)
    ->Promise.then(_ => Promise.resolve("resolved"))
    ->Promise.catch(_ => Promise.resolve("rejected"))

    t->expect(overflowResult)->Expect.toBe("rejected")
  })

  testAsync("pause stops processing new tasks", async t => {
    pause()
    let executed = ref(false)
    let _ = schedule(async () => {
      executed := true
    })

    // Wait a bit to ensure it doesn't run
    let _ = await Promise.make((resolve, _) => {
      let _ = ReBindings.Window.setTimeout(() => resolve(ignore()), 50)
    })

    t->expect(executed.contents)->Expect.toBe(false)
    t->expect(length())->Expect.toBe(1)

    // Cleanup
    let _ = drain()
    resume()
  })

  testAsync("resume restarts processing", async t => {
    pause()
    let executed = ref(false)
    let _ = schedule(async () => {
      executed := true
    })

    t->expect(executed.contents)->Expect.toBe(false)

    resume()

    // Wait for execution
    let _ = await Promise.make((resolve, _) => {
      let _ = ReBindings.Window.setTimeout(() => resolve(ignore()), 50)
    })

    t->expect(executed.contents)->Expect.toBe(true)
    t->expect(length())->Expect.toBe(0)
  })

  testAsync("drain clears the queue", async t => {
    pause()
    let _ = schedule(async () => {ignore()})
    let _ = schedule(async () => {ignore()})
    let _ = schedule(async () => {ignore()})

    t->expect(length())->Expect.toBe(3)

    let count = drain()
    t->expect(count)->Expect.toBe(3)
    t->expect(length())->Expect.toBe(0)

    resume()
  })

  testAsync("drain rejects pending tasks", async t => {
    pause()
    let p = schedule(async () => {ignore()})

    let rejection = p
    ->Promise.then(_ => Promise.resolve("resolved"))
    ->Promise.catch(_ => Promise.resolve("rejected"))

    let _ = drain()

    let result = await rejection
    t->expect(result)->Expect.toBe("rejected")
    resume()
  })
})
