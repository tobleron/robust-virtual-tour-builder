/* tests/unit/NavigationSupervisor_v.test.res */
open Vitest

describe("NavigationSupervisor", () => {
  test("Initial state is idle", t => {
    t->expect(NavigationSupervisor.isIdle())->Expect.toBe(true)
  })

  test("requestNavigation starts task and transitions to Loading", t => {
    NavigationSupervisor.requestNavigation("scene1")
    t->expect(NavigationSupervisor.isIdle())->Expect.toBe(false)
    t->expect(NavigationSupervisor.isBusy())->Expect.toBe(true)

    switch NavigationSupervisor.getStatus() {
    | Loading(_, sceneId) => t->expect(sceneId)->Expect.toBe("scene1")
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("requestNavigation cancels previous task", t => {
    NavigationSupervisor.requestNavigation("scene1")
    let task1 = NavigationSupervisor.getCurrentTask()
    t->expect(task1->Option.isSome)->Expect.toBe(true)

    NavigationSupervisor.requestNavigation("scene2")
    let task2 = NavigationSupervisor.getCurrentTask()

    // Verify task was replaced
    switch (task1, task2) {
    | (Some(t1), Some(t2)) => t->expect(t1.id != t2.id)->Expect.toBe(true)
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("transitionTo updates status and notifies listeners", testCtx => {
    NavigationSupervisor.requestNavigation("scene1")
    let task = NavigationSupervisor.getCurrentTask()

    switch task {
    | Some(t) =>
      NavigationSupervisor.transitionTo(t.id, Swapping(t.id, "scene1"))
      switch NavigationSupervisor.getStatus() {
      | Swapping(_, sceneId) => testCtx->expect(sceneId)->Expect.toBe("scene1")
      | _ => testCtx->expect(true)->Expect.toBe(false)
      }
    | None => testCtx->expect(true)->Expect.toBe(false)
    }
  })

  test("complete resets to idle", testCtx => {
    NavigationSupervisor.requestNavigation("scene1")
    let task = NavigationSupervisor.getCurrentTask()

    switch task {
    | Some(t) =>
      NavigationSupervisor.complete(t.id)
      testCtx->expect(NavigationSupervisor.isIdle())->Expect.toBe(true)
      testCtx->expect(NavigationSupervisor.getCurrentTask())->Expect.toEqual(None)
    | None => testCtx->expect(true)->Expect.toBe(false)
    }
  })

  test("abort resets to idle", testCtx => {
    NavigationSupervisor.requestNavigation("scene1")
    let task = NavigationSupervisor.getCurrentTask()

    switch task {
    | Some(t) =>
      NavigationSupervisor.abort(t.id)
      testCtx->expect(NavigationSupervisor.isIdle())->Expect.toBe(true)
    | None => testCtx->expect(true)->Expect.toBe(false)
    }
  })

  test("stale task operations are ignored", testCtx => {
    NavigationSupervisor.requestNavigation("scene1")
    let task1 = NavigationSupervisor.getCurrentTask()

    NavigationSupervisor.requestNavigation("scene2")
    let task2 = NavigationSupervisor.getCurrentTask()

    switch task1 {
    | Some(t1) =>
      // Attempt to complete with stale taskId should not change current status
      NavigationSupervisor.complete(t1.id)
      testCtx->expect(NavigationSupervisor.isIdle())->Expect.toBe(false) // Still busy
      testCtx->expect(NavigationSupervisor.getCurrentTask()->Option.map(t => t.id))->Expect.toEqual(
        task2->Option.map(t => t.id),
      )
    | None => testCtx->expect(true)->Expect.toBe(false)
    }
  })

  test("addStatusListener notifies on status changes", testCtx => {
    let statusChanges: ref<array<NavigationSupervisor.status>> = ref([])

    let unsub = NavigationSupervisor.addStatusListener(status => {
      statusChanges := Belt.Array.concat(statusChanges.contents, [status])
    })

    NavigationSupervisor.requestNavigation("scene1")
    let task = NavigationSupervisor.getCurrentTask()

    switch task {
    | Some(t) =>
      NavigationSupervisor.transitionTo(t.id, Swapping(t.id, "scene1"))
      NavigationSupervisor.complete(t.id)

      // Should have recorded: Loading, Swapping, Idle (at least 3 status changes)
      testCtx->expect(Belt.Array.length(statusChanges.contents) >= 3)->Expect.toBe(true)

      unsub()
    | None => testCtx->expect(true)->Expect.toBe(false)
    }
  })

  test("AbortSignal is created for each task", testCtx => {
    NavigationSupervisor.requestNavigation("scene1")
    let task = NavigationSupervisor.getCurrentTask()

    switch task {
    | Some(t) =>
      let signal = t.signal
      // Signal should exist and be usable with abort
      testCtx->expect(signal->BrowserBindings.AbortSignal.aborted)->Expect.toBe(false)
      t.abort()
      testCtx->expect(signal->BrowserBindings.AbortSignal.aborted)->Expect.toBe(true)
    | None => testCtx->expect(true)->Expect.toBe(false)
    }
  })
})
