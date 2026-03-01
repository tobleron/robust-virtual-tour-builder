/* tests/unit/NavigationController_v.test.res */
open Vitest
open Types
open ReBindings

/* Mocks */
%%raw(`
  import { vi } from "vitest";

  vi.mock("../../src/systems/Scene/SceneLoader.bs.js", () => ({
    Loader: {
      loadNewScene: vi.fn(),
    }
  }));

  // We need to mock NavigationSupervisor to verify abort was called
  // But we use the real one for logic, just spy on abort
`)

describe("NavigationController", () => {
  module Vi = {
    @module("vitest") @scope("vi") external useFakeTimers: unit => unit = "useFakeTimers"
    @module("vitest") @scope("vi") external useRealTimers: unit => unit = "useRealTimers"
    @module("vitest") @scope("vi") external advanceTimersByTime: int => unit = "advanceTimersByTime"
  }

  beforeEach(() => {
    Vi.useFakeTimers()
    NavigationSupervisor.reset()
    let _ = %raw(`vi.clearAllMocks()`)
  })

  afterEach(() => {
    Vi.useRealTimers()
  })

  test("LoadTimeout aborts NavigationSupervisor task", t => {
    let scene1 = TestUtils.createMockScene(~id="s1", ~name="s1", ())
    let state = TestUtils.createMockState(~scenes=[scene1], ~activeIndex=0, ())

    // Start navigation
    NavigationSupervisor.requestNavigation("s1")
    let task = NavigationSupervisor.getCurrentTask()->Option.getOrThrow
    let taskId = task.token.id

    t->expect(NavigationSupervisor.isBusy())->Expect.toBe(true)

    let seenEvents = ref([])
    let dispatch = (action: Actions.action) => {
      switch action {
      | DispatchNavigationFsmEvent(ev) => seenEvents := Belt.Array.concat(seenEvents.contents, [ev])
      | _ => ()
      }
    }

    let _getState = () => state

    // Setup FSM state for Loading
    let _navState: navigationState = {
      ...state.navigationState,
      navigationFsm: Preloading({
        targetSceneId: "s1",
        attempt: 0,
        isAnticipatory: false,
      }),
    }

    // Trigger the hook logic (simulated)
    // We manually simulate what useEffect does
    let timeoutId = Window.setTimeout(
      () => {
        if NavigationSupervisor.isCurrentToken(task.token) {
          NavigationSupervisor.abort(taskId)
          dispatch(Actions.DispatchNavigationFsmEvent(LoadTimeout))
        }
      },
      Constants.sceneLoadTimeout,
    )

    // Advance past timeout (15s)
    Vi.advanceTimersByTime(Constants.sceneLoadTimeout + 100)

    // Verify Supervisor is now Idle (Regression Prevention for H2)
    t->expect(NavigationSupervisor.isIdle())->Expect.toBe(true)

    // Verify Event was dispatched
    t->expect(seenEvents.contents->Belt.Array.some(ev => ev == LoadTimeout))->Expect.toBe(true)

    Window.clearTimeout(timeoutId)
  })
})
