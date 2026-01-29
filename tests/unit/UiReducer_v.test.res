/* tests/unit/Reducer.UiTest.res */
open Vitest
open Actions
open Types

describe("Reducer.Ui", () => {
  let initialState = State.initialState

  test("SetPreloadingScene updates preloadingSceneIndex", t => {
    let action = SetPreloadingScene(5)
    let result = Reducer.Ui.reduce(initialState, action)

    switch result {
    | Some(newState) => t->expect(newState.preloadingSceneIndex)->Expect.toBe(5)
    | None => t->expect(true)->Expect.toBe(false) // Fail if None
    }
  })

  test("StartLinking enables isLinking and sets draft", t => {
    let draft: linkDraft = {
      pitch: 10.0,
      yaw: 20.0,
      camPitch: 0.0,
      camYaw: 0.0,
      camHfov: 90.0,
      intermediatePoints: None,
    }
    let action = StartLinking(Some(draft))
    let result = Reducer.Ui.reduce(initialState, action)

    switch result {
    | Some(newState) => {
        t->expect(newState.isLinking)->Expect.toBe(true)
        t->expect(newState.linkDraft)->Expect.toBe(Some(draft))
      }
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("StopLinking disables isLinking and clears draft", t => {
    let state = {
      ...initialState,
      isLinking: true,
      linkDraft: Some({
        pitch: 0.0,
        yaw: 0.0,
        camPitch: 0.0,
        camYaw: 0.0,
        camHfov: 0.0,
        intermediatePoints: None,
      }),
    }
    let action = StopLinking
    let result = Reducer.Ui.reduce(state, action)

    switch result {
    | Some(newState) => {
        t->expect(newState.isLinking)->Expect.toBe(false)
        t->expect(newState.linkDraft)->Expect.toBe(None)
      }
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("UpdateLinkDraft updates the draft", t => {
    let draft: linkDraft = {
      pitch: 30.0,
      yaw: 40.0,
      camPitch: 0.0,
      camYaw: 0.0,
      camHfov: 90.0,
      intermediatePoints: None,
    }
    let action = UpdateLinkDraft(draft)
    let result = Reducer.Ui.reduce(initialState, action)

    switch result {
    | Some(newState) => t->expect(newState.linkDraft)->Expect.toBe(Some(draft))
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("SetIsTeasing updates isTeasing", t => {
    let action = SetIsTeasing(true)
    let result = Reducer.Ui.reduce(initialState, action)

    switch result {
    | Some(newState) => t->expect(newState.isTeasing)->Expect.toBe(true)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Unhandled action returns None", t => {
    let action = Reset // Reducer.Ui doesn't handle Reset
    let result = Reducer.Ui.reduce(initialState, action)

    t->expect(result)->Expect.toBe(None)
  })
})
