/* tests/unit/NavigationSupervisor_v.test.res */
open Vitest
open Types

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
    | (Some(t1), Some(t2)) => t->expect(t1.token.id != t2.token.id)->Expect.toBe(true)
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("transitionTo updates status and notifies listeners", testCtx => {
    NavigationSupervisor.requestNavigation("scene1")
    let task = NavigationSupervisor.getCurrentTask()

    switch task {
    | Some(t) =>
      NavigationSupervisor.transitionTo(t.token.id, Swapping(t.token.id, "scene1"))
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
      NavigationSupervisor.complete(t.token.id)
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
      NavigationSupervisor.abort(t.token.id)
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
      NavigationSupervisor.complete(t1.token.id)
      testCtx->expect(NavigationSupervisor.isIdle())->Expect.toBe(false) // Still busy
      testCtx
      ->expect(NavigationSupervisor.getCurrentTask()->Option.map(t => t.token.id))
      ->Expect.toEqual(task2->Option.map(t => t.token.id))
    | None => testCtx->expect(true)->Expect.toBe(false)
    }
  })

  test("addStatusListener notifies on status changes", testCtx => {
    let statusChanges: ref<array<NavigationSupervisor.status>> = ref([])

    let unsub = NavigationSupervisor.addStatusListener(
      status => {
        statusChanges := Belt.Array.concat(statusChanges.contents, [status])
      },
    )

    NavigationSupervisor.requestNavigation("scene1")
    let task = NavigationSupervisor.getCurrentTask()

    switch task {
    | Some(t) =>
      NavigationSupervisor.transitionTo(t.token.id, Swapping(t.token.id, "scene1"))
      NavigationSupervisor.complete(t.token.id)

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
      let signal = t.token.signal
      // Signal should exist and be usable with abort
      testCtx->expect(signal->BrowserBindings.AbortSignal.aborted)->Expect.toBe(false)
      t.abort()
      testCtx->expect(signal->BrowserBindings.AbortSignal.aborted)->Expect.toBe(true)
    | None => testCtx->expect(true)->Expect.toBe(false)
    }
  })

  test("concurrent requests abort the previous one", t => {
    NavigationSupervisor.requestNavigation("scene1")
    let task1 = NavigationSupervisor.getCurrentTask()

    // Check task1 signal is not aborted
    switch task1 {
    | Some(tk) =>
      t->expect(tk.token.signal->BrowserBindings.AbortSignal.aborted)->Expect.toBe(false)
    | None => t->expect(false)->Expect.toBe(true)
    }

    NavigationSupervisor.requestNavigation("scene2")
    let task2 = NavigationSupervisor.getCurrentTask()

    // Task1 should be aborted now
    switch task1 {
    | Some(tk) => t->expect(tk.token.signal->BrowserBindings.AbortSignal.aborted)->Expect.toBe(true)
    | None => ()
    }

    // Task2 should be active and not aborted
    switch task2 {
    | Some(tk) =>
      t->expect(tk.token.signal->BrowserBindings.AbortSignal.aborted)->Expect.toBe(false)
    | None => t->expect(false)->Expect.toBe(true)
    }
  })

  test("new request resets in-flight journey state before dispatching latest intent", t => {
    let staleJourney: journeyData = {
      journeyId: 7,
      targetIndex: 1,
      sourceIndex: 0,
      hotspotIndex: 0,
      arrivalYaw: 0.0,
      arrivalPitch: 0.0,
      arrivalHfov: 100.0,
      previewOnly: false,
      pathData: None,
    }
    let staleState: state = {
      ...State.initialState,
      navigationState: {
        ...State.initialState.navigationState,
        navigation: Navigating(staleJourney),
        incomingLink: Some({sceneIndex: 0, hotspotIndex: 0}),
      },
    }
    AppStateBridge.updateState(staleState)

    let seenActions: ref<array<Actions.action>> = ref([])
    NavigationSupervisor.configure(
      action => {
        seenActions := Belt.Array.concat(seenActions.contents, [action])
      },
    )

    NavigationSupervisor.requestNavigation("scene-new")

    let hasIdleReset = seenActions.contents->Belt.Array.some(
      action =>
        switch action {
        | Actions.SetNavigationStatus(Idle) => true
        | _ => false
        },
    )
    let hasIncomingCleared = seenActions.contents->Belt.Array.some(
      action =>
        switch action {
        | Actions.SetIncomingLink(None) => true
        | _ => false
        },
    )
    let hasLatestIntent = seenActions.contents->Belt.Array.some(
      action =>
        switch action {
        | Actions.DispatchNavigationFsmEvent(UserClickedScene({targetSceneId})) =>
          targetSceneId == "scene-new"
        | _ => false
        },
    )

    t->expect(hasIdleReset)->Expect.toBe(true)
    t->expect(hasIncomingCleared)->Expect.toBe(true)
    t->expect(hasLatestIntent)->Expect.toBe(true)

    NavigationSupervisor.configure(AppStateBridge.dispatch)
  })
})
