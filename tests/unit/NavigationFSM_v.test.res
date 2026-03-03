// @efficiency: infra-adapter
/* tests/unit/NavigationFSM_v.test.res */

open Vitest
open Types

describe("NavigationFSM", () => {
  test("Idle state transitions to Preloading on UserClickedScene", t => {
    let state = IdleFsm
    let event: navigationEvent = UserClickedScene({targetSceneId: "scene-1", previewOnly: false})
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Preloading({targetSceneId, isAnticipatory}) =>
      t->expect(targetSceneId)->Expect.toBe("scene-1")
      t->expect(isAnticipatory)->Expect.toBe(false)
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Preloading to Transitioning on TextureLoaded", t => {
    let state = Preloading({
      targetSceneId: "scene-1",
      attempt: 1,
      isAnticipatory: false,
    })
    let event: navigationEvent = TextureLoaded({targetSceneId: "scene-1"})
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Transitioning({toSceneId}) => t->expect(toSceneId)->Expect.toBe("scene-1")
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Transitioning to Stabilizing on TransitionComplete", t => {
    let state = Transitioning({
      fromSceneId: None,
      toSceneId: "scene-1",
      progress: 1.0,
      isPreview: false,
    })
    let event: navigationEvent = TransitionComplete
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Stabilizing({targetSceneId}) => t->expect(targetSceneId)->Expect.toBe("scene-1")
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Stabilizing to Idle on StabilizeComplete", t => {
    let state = Stabilizing({targetSceneId: "scene-1"})
    let event: navigationEvent = StabilizeComplete
    let nextState = NavigationFSM.reducer(state, event)

    t->expect(nextState)->Expect.toEqual(IdleFsm)
  })

  test("Interruptions: User clicks another scene while preloading", t => {
    let state = Preloading({
      targetSceneId: "scene-1",
      attempt: 1,
      isAnticipatory: false,
    })
    let event: navigationEvent = UserClickedScene({targetSceneId: "scene-2", previewOnly: false})
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Preloading({targetSceneId}) => t->expect(targetSceneId)->Expect.toBe("scene-2")
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Interruptions: User clicks another scene while transitioning", t => {
    let state = Transitioning({
      fromSceneId: None,
      toSceneId: "scene-1",
      progress: 0.5,
      isPreview: false,
    })
    let event: navigationEvent = UserClickedScene({targetSceneId: "scene-2", previewOnly: false})
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Preloading({targetSceneId}) => t->expect(targetSceneId)->Expect.toBe("scene-2")
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("TextureLoaded mismatch is ignored and stays in Preloading", t => {
    let state = Preloading({
      targetSceneId: "scene-correct",
      attempt: 1,
      isAnticipatory: false,
    })
    let event: navigationEvent = TextureLoaded({targetSceneId: "scene-wrong"})
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | Preloading({targetSceneId}) => t->expect(targetSceneId)->Expect.toBe("scene-correct")
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Anticipatory load stays Idle after TextureLoaded", t => {
    let state = Preloading({
      targetSceneId: "scene-1",
      attempt: 1,
      isAnticipatory: true,
    })
    let event: navigationEvent = TextureLoaded({targetSceneId: "scene-1"})
    let nextState = NavigationFSM.reducer(state, event)

    t->expect(nextState)->Expect.toEqual(IdleFsm)
  })

  test("Preloading to Error on LoadTimeout", t => {
    let state = Preloading({
      targetSceneId: "scene-1",
      attempt: 1,
      isAnticipatory: false,
    })
    let event: navigationEvent = LoadTimeout
    let nextState = NavigationFSM.reducer(state, event)

    switch nextState {
    | ErrorFsm({code, recoveryTarget}) =>
      t->expect(code)->Expect.toBe("TIMEOUT")
      t->expect(recoveryTarget)->Expect.toEqual(Some("scene-1"))
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Error to Preloading (retry) on RecoveryTriggered", t => {
    let state = ErrorFsm({
      code: "TIMEOUT",
      recoveryTarget: Some("scene-1"),
    })
    let event: navigationEvent = RecoveryTriggered({targetSceneId: "scene-1"})
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
      Preloading({
        targetSceneId: "s1",
        attempt: 1,
        isAnticipatory: false,
      }),
      Transitioning({
        fromSceneId: None,
        toSceneId: "s1",
        progress: 0.5,
        isPreview: false,
      }),
      Stabilizing({targetSceneId: "s1"}),
      ErrorFsm({code: "ERR", recoveryTarget: None}),
    ]

    states->Belt.Array.forEach(
      state => {
        let nextState = NavigationFSM.reducer(state, Reset)
        t->expect(nextState)->Expect.toEqual(IdleFsm)
      },
    )
  })
})
