// @efficiency: infra-adapter
/* tests/unit/RequestQueue_v.test.res */
open Vitest
open RequestQueue

describe("RequestQueue", () => {
  let swallowRejection = (p: Promise.t<'a>): Promise.t<unit> =>
    p
    ->Promise.then(_ => Promise.resolve())
    ->Promise.catch(_ => Promise.resolve())

  afterEach(() => {
    let _ = drain()
    paused := false
    activeCount := 0
    nowMs := (_ => Date.now())
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
      let _ = schedule(blocker)->swallowRejection
    }
    // Fill pending queue.
    for _i in 1 to maxQueued {
      let _ = schedule(blocker)->swallowRejection
    }

    let overflowResult = await schedule(blocker)
    ->Promise.then(_ => Promise.resolve("resolved"))
    ->Promise.catch(_ => Promise.resolve("rejected"))

    t->expect(overflowResult)->Expect.toBe("rejected")
  })

  testAsync("pause stops processing new tasks", async t => {
    pause()
    let executed = ref(false)
    let _ = schedule(
      async () => {
        executed := true
      },
    )->swallowRejection

    // Wait a bit to ensure it doesn't run
    let _ = await Promise.make(
      (resolve, _) => {
        let _ = ReBindings.Window.setTimeout(() => resolve(ignore()), 50)
      },
    )

    t->expect(executed.contents)->Expect.toBe(false)
    t->expect(length())->Expect.toBe(1)

    // Cleanup
    let _ = drain()
    resume()
  })

  testAsync("resume restarts processing", async t => {
    pause()
    let executed = ref(false)
    let _ = schedule(
      async () => {
        executed := true
      },
    )

    t->expect(executed.contents)->Expect.toBe(false)

    resume()

    // Wait for execution
    let _ = await Promise.make(
      (resolve, _) => {
        let _ = ReBindings.Window.setTimeout(() => resolve(ignore()), 50)
      },
    )

    t->expect(executed.contents)->Expect.toBe(true)
    t->expect(length())->Expect.toBe(0)
  })

  testAsync("drain clears the queue", async t => {
    pause()
    let _ = schedule(async () => {ignore()})->swallowRejection
    let _ = schedule(async () => {ignore()})->swallowRejection
    let _ = schedule(async () => {ignore()})->swallowRejection

    t->expect(length())->Expect.toBe(3)

    let count = drain()
    t->expect(count)->Expect.toBe(3)
    t->expect(length())->Expect.toBe(0)

    resume()
  })

  testAsync("drain rejects pending tasks", async t => {
    pause()
    let p = schedule(async () => {ignore()})

    let rejection =
      p
      ->Promise.then(_ => Promise.resolve("resolved"))
      ->Promise.catch(_ => Promise.resolve("rejected"))

    let _ = drain()

    let result = await rejection
    t->expect(result)->Expect.toBe("rejected")
    resume()
  })

  testAsync("priority scheduling executes critical before normal/background", async t => {
    pause()
    let order = ref([])
    let mk = (label: string) =>
      scheduleWithPriority(
        ~priority=Background,
        () => {
          order := Belt.Array.concat(order.contents, [label])
          Promise.resolve()
        },
      )

    let _ = mk("background-1")->swallowRejection
    let _ = scheduleWithPriority(
      ~priority=Normal,
      () => {
        order := Belt.Array.concat(order.contents, ["normal-1"])
        Promise.resolve()
      },
    )->swallowRejection
    let _ = scheduleWithPriority(
      ~priority=Critical,
      () => {
        order := Belt.Array.concat(order.contents, ["critical-1"])
        Promise.resolve()
      },
    )->swallowRejection

    resume()
    let _ = await Promise.make(
      (resolve, _) => {
        let _ = ReBindings.Window.setTimeout(() => resolve(ignore()), 30)
      },
    )

    t->expect(Belt.Array.getExn(order.contents, 0))->Expect.toBe("critical-1")
  })

  testAsync("starvation promotion escalates queued work before dequeue", async t => {
    pause()
    let order = ref([])
    nowMs := (_ => 0.0)

    let _ = scheduleWithPriority(
      ~priority=Background,
      () => {
        order := Belt.Array.concat(order.contents, ["background-1"])
        Promise.resolve()
      },
    )->swallowRejection
    let _ = scheduleWithPriority(
      ~priority=Normal,
      () => {
        order := Belt.Array.concat(order.contents, ["normal-1"])
        Promise.resolve()
      },
    )->swallowRejection

    nowMs := (_ => 60001.0)
    resume()
    let _ = await Promise.make(
      (resolve, _) => {
        let _ = ReBindings.Window.setTimeout(() => resolve(ignore()), 30)
      },
    )

    t->expect(order.contents)->Expect.toEqual(["normal-1", "background-1"])
  })

  testAsync("critical can use burst slots when base concurrency is saturated", async t => {
    let resolves: array<unit => unit> = []
    let blocker = () =>
      Promise.make(
        (resolve, _) => {
          ignore(Array.push(resolves, () => resolve(ignore())))
        },
      )

    for _i in 1 to maxConcurrent {
      let _ = scheduleWithPriority(~priority=Normal, blocker)->swallowRejection
    }

    let criticalRan = ref(false)
    let _ = scheduleWithPriority(
      ~priority=Critical,
      () => {
        criticalRan := true
        Promise.resolve()
      },
    )->swallowRejection

    let _ = await Promise.make(
      (resolve, _) => {
        let _ = ReBindings.Window.setTimeout(() => resolve(ignore()), 40)
      },
    )

    t->expect(criticalRan.contents)->Expect.toBe(true)

    resolves->Belt.Array.forEach(resolve => resolve())
  })

  testAsync("scheduleWithRetry accepts priority and preserves behavior", async t => {
    let result = await scheduleWithRetry(
      ~priority=Background,
      ~task=() => Promise.resolve(Ok("ok")),
    )
    switch result {
    | Retry.Success(value, _) => t->expect(value)->Expect.toBe("ok")
    | _ => t->expect("ExpectedSuccess")->Expect.toBe("UnexpectedResult")
    }
  })
})
