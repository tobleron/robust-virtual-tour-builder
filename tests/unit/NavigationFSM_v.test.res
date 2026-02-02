// @efficiency: infra-adapter
/* tests/unit/NavigationFSM_v.test.res */

open Vitest

describe("NavigationFSM", () => {
  test("Idle state transitions to Preloading on UserClickedScene", t => {
    let state = NavigationFSM.Idle
    let event = NavigationFSM.UserClickedScene({targetSceneId: "scene-1"})
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Preloading({targetSceneId, isAnticipatory}) =>
      t->expect(targetSceneId)->Expect.toBe("scene-1")
      t->expect(isAnticipatory)->Expect.toBe(false)
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Preloading to Transitioning on TextureLoaded", t => {
    let state = NavigationFSM.Preloading({
      targetSceneId: "scene-1",
      attempt: 1,
      isAnticipatory: false,
    })
    let event = NavigationFSM.TextureLoaded({targetSceneId: "scene-1"})
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Transitioning({toSceneId}) => t->expect(toSceneId)->Expect.toBe("scene-1")
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Transitioning to Stabilizing on TransitionComplete", t => {
    let state = NavigationFSM.Transitioning({
      fromSceneId: None,
      toSceneId: "scene-1",
      progress: 1.0,
    })
    let event = NavigationFSM.TransitionComplete
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Stabilizing({targetSceneId}) => t->expect(targetSceneId)->Expect.toBe("scene-1")
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Stabilizing to Idle on StabilizeComplete", t => {
    let state = NavigationFSM.Stabilizing({targetSceneId: "scene-1"})
    let event = NavigationFSM.StabilizeComplete
    let nextState = NavigationFSM.reducer(state, event)

    t->expect(nextState)->Expect.toEqual(NavigationFSM.Idle)
  })

  test("Interruptions: User clicks another scene while preloading", t => {
    let state = NavigationFSM.Preloading({
      targetSceneId: "scene-1",
      attempt: 1,
      isAnticipatory: false,
    })
    let event = NavigationFSM.UserClickedScene({targetSceneId: "scene-2"})
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Preloading({targetSceneId}) => t->expect(targetSceneId)->Expect.toBe("scene-2")
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Interruptions: User clicks another scene while transitioning", t => {
    let state = NavigationFSM.Transitioning({
      fromSceneId: None,
      toSceneId: "scene-1",
      progress: 0.5,
    })
    let event = NavigationFSM.UserClickedScene({targetSceneId: "scene-2"})
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Preloading({targetSceneId}) => t->expect(targetSceneId)->Expect.toBe("scene-2")
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Anticipatory load stays Idle after TextureLoaded", t => {
    let state = NavigationFSM.Preloading({
      targetSceneId: "scene-1",
      attempt: 1,
      isAnticipatory: true,
    })
    let event = NavigationFSM.TextureLoaded({targetSceneId: "scene-1"})
    let nextState = NavigationFSM.reducer(state, event)

    t->expect(nextState)->Expect.toEqual(NavigationFSM.Idle)
  })

  test("Preloading to Error on LoadTimeout", t => {
    let state = NavigationFSM.Preloading({
      targetSceneId: "scene-1",
      attempt: 1,
      isAnticipatory: false,
    })
    let event = NavigationFSM.LoadTimeout
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Error({code, recoveryTarget}) =>
      t->expect(code)->Expect.toBe("TIMEOUT")
      t->expect(recoveryTarget)->Expect.toEqual(Some("scene-1"))
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Error to Preloading (retry) on RecoveryTriggered", t => {
    let state = NavigationFSM.Error({
      code: "TIMEOUT",
      recoveryTarget: Some("scene-1"),
    })
    let event = NavigationFSM.RecoveryTriggered({targetSceneId: "scene-1"})
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Preloading({targetSceneId, attempt}) =>
      t->expect(targetSceneId)->Expect.toBe("scene-1")
      t->expect(attempt)->Expect.toBe(2)
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Reset event transitions to Idle from any state", t => {
    let states = [
      NavigationFSM.Preloading({
        targetSceneId: "s1",
        attempt: 1,
        isAnticipatory: false,
      }),
      NavigationFSM.Transitioning({
        fromSceneId: None,
        toSceneId: "s1",
        progress: 0.5,
      }),
      NavigationFSM.Stabilizing({targetSceneId: "s1"}),
      NavigationFSM.Error({code: "ERR", recoveryTarget: None}),
    ]

    states->Belt.Array.forEach(
      state => {
        let nextState = NavigationFSM.reducer(state, NavigationFSM.Reset)
        t->expect(nextState)->Expect.toEqual(NavigationFSM.Idle)
      },
    )
  })
})
