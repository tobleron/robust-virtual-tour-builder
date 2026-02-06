// @efficiency: infra-adapter
open Vitest
open Types
open Actions

describe("Scene.Switcher", () => {
  beforeEach(() => {
    GlobalStateBridge.setState(State.initialState)
    // Mock Viewer
    let _ = %raw(`
      (function(){
        globalThis.ReBindings = globalThis.ReBindings || {};
        globalThis.ReBindings.Viewer = {
          instance: {},
          getYaw: () => 0.0,
          getPitch: () => 0.0,
          getHfov: () => 90.0
        }
      })()
    `)
  })

  test("navigateToScene manual jump updates state", t => {
    let dispatched = ref([])
    let dispatch = a => {
      let _ = Array.push(dispatched.contents, a)
    }

    let s1 = TestUtils.createMockScene(~id="s1", ~name="s1", ())
    let s2 = TestUtils.createMockScene(~id="s2", ~name="s2", ())
    let state = {...State.initialState, scenes: [s1, s2], activeIndex: 0}

    Scene.Switcher.navigateToScene(dispatch, state, 1, 0, -1, ())

    t->expect(dispatched.contents->Array.length)->Expect.toBe(1)
    // Expect Batch containing SetActiveScene and IncrementJourneyId
    let hasSetActive = dispatched.contents->Array.some(
      a => {
        switch a {
        | Batch(actions) =>
          actions->Array.some(
            inner => {
              switch inner {
              | SetActiveScene(idx, _, _, _) => idx == 1
              | _ => false
              }
            },
          )
        | _ => false
        }
      },
    )
    t->expect(hasSetActive)->Expect.toBe(true)
  })

  test("navigateToScene prevents concurrent navigation", t => {
    let dispatched = ref([])
    let dispatch = a => {
      let _ = Array.push(dispatched.contents, a)
    }

    let s1 = TestUtils.createMockScene(~id="s1", ~name="s1", ())
    let journey: journeyData = {
      journeyId: 1,
      targetIndex: 1,
      sourceIndex: 0,
      hotspotIndex: 0,
      arrivalYaw: 0.0,
      arrivalPitch: 0.0,
      arrivalHfov: 90.0,
      previewOnly: false,
      pathData: Some({
        startPitch: 0.0,
        startYaw: 0.0,
        startHfov: 90.0,
        targetPitchForPan: 0.0,
        targetYawForPan: 0.0,
        targetHfovForPan: 90.0,
        totalPathDistance: 0.0,
        segments: [],
        waypoints: [],
        panDuration: 1000.0,
        arrivalYaw: 0.0,
        arrivalPitch: 0.0,
        arrivalHfov: 90.0,
      }),
    }

    let state = {
      ...State.initialState,
      scenes: [s1],
      navigation: Navigating(journey),
    }

    Scene.Switcher.navigateToScene(dispatch, state, 1, 0, -1, ())

    t->expect(dispatched.contents->Array.length)->Expect.toBe(0)
  })
})
