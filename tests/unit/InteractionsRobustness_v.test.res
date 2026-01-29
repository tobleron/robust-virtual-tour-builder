open Vitest
open Types
open Actions

describe("Interactions Robustness (Chaos Fuzzing)", () => {
  let initial = State.initialState

  // 1. Define Invariants
  let checkInvariants = (t, state: state, lastAction: string) => {
    // Rule: Cannot be in Linking Mode and Simulation Mode simultaneously
    if state.isLinking && state.simulation.status == Running {
      t->expect("Linking and Simulating")->Expect.toEqual("Should not happen: " ++ lastAction)
    }

    // Rule: activeIndex must be valid or -1
    let sceneCount = Belt.Array.length(state.scenes)
    if state.activeIndex >= sceneCount {
      t
      ->expect("Index " ++ Belt.Int.toString(state.activeIndex))
      ->Expect.toEqual(
        "Should be less than " ++ Belt.Int.toString(sceneCount) ++ " after " ++ lastAction,
      )
    }

    // Rule: navigation != Idle implies transition.type_ != None
    if state.navigation != Idle && state.transition.type_ == Fade {
      t
      ->expect("Navigation Active")
      ->Expect.toEqual("Transition type should not be None after " ++ lastAction)
    }
  }

  // 2. Define Action Generators
  let getRandomIndex = max => {
    if max <= 0 {
      0
    } else {
      Math.floor(Math.random() *. Belt.Int.toFloat(max))->Float.toInt
    }
  }

  let pickRandomAction = (state: state): action => {
    let roll = Math.random() *. 10.0
    let sceneCount = Belt.Array.length(state.scenes)

    if roll < 1.0 {
      // Add Scene
      AddScenes([
        Logger.castToJson({
          "id": "chaos-" ++ Float.toString(Date.now()),
          "name": "Chaos Scene",
        }),
      ])
    } else if roll < 2.0 && sceneCount > 0 {
      // Delete Scene
      DeleteScene(getRandomIndex(sceneCount))
    } else if roll < 5.0 && sceneCount > 0 {
      // Set Active Scene
      SetActiveScene(getRandomIndex(sceneCount), 0.0, 0.0, None)
    } else if roll < 6.0 {
      // Toggle Linking
      state.isLinking ? StopLinking : StartLinking(None)
    } else if roll < 7.0 {
      // Toggle simulation
      state.simulation.status == Running ? StopAutoPilot : StartAutoPilot(0, false)
    } else if roll < 8.0 && sceneCount > 0 {
      // Add Hotspot to some scene
      let sIdx = getRandomIndex(sceneCount)
      AddHotspot(
        sIdx,
        {
          linkId: "chaos-link",
          yaw: 10.0,
          pitch: 10.0,
          target: "somewhere",
          targetYaw: None,
          targetPitch: None,
          targetHfov: None,
          startYaw: None,
          startPitch: None,
          startHfov: None,
          viewFrame: None,
          returnViewFrame: None,
          isReturnLink: None,
          waypoints: None,
          displayPitch: None,
          transition: None,
          duration: None,
        },
      )
    } else {
      Reset
    }
  }

  test("Reducer should survive 500 random sequential interactions", t => {
    let state = ref(initial)

    // Seed with some scenes
    state.contents = Reducer.reducer(
      state.contents,
      AddScenes([
        Logger.castToJson({
          "id": "s1",
          "name": "Scene 1",
          "preview": "p1",
        }),
        Logger.castToJson({
          "id": "s2",
          "name": "Scene 2",
          "preview": "p2",
        }),
      ]),
    )

    for _ in 1 to 500 {
      let action = pickRandomAction(state.contents)
      let actionName = actionToString(action)

      try {
        state.contents = Reducer.reducer(state.contents, action)
        checkInvariants(t, state.contents, actionName)
      } catch {
      | e =>
        switch JsExn.fromException(e) {
        | Some(jsExn) =>
          let msg = JsExn.message(jsExn)->Option.getOr("Unknown JS error")
          t->expect("Crash: " ++ msg)->Expect.toEqual("No crash on " ++ actionName)
        | None =>
          t->expect("Crashed with non-JS error")->Expect.toEqual("No crash on " ++ actionName)
        }
      }
    }

    t->expect(true)->Expect.toEqual(true)
  })
})
