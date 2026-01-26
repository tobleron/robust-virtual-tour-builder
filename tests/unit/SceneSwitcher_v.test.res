open Vitest
open Types
open Actions

describe("SceneSwitcher", () => {
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

    SceneSwitcher.navigateToScene(dispatch, state, 1, 0, -1, ())

    t->expect(dispatched.contents->Array.length >= 2)->Expect.toBe(true)
    // Expect SetActiveScene and IncrementJourneyId
    let hasSetActive = dispatched.contents->Array.some(
      a => {
        switch a {
        | SetActiveScene(idx, _, _, _) => idx == 1
        | _ => false
        }
      },
    )
    t->expect(hasSetActive)->Expect.toBe(true)
  })
})
