open Vitest

describe("ViewerState with ViewerPool", () => {
  beforeEach(() => {
    // Reset pool defaults
    ViewerPool.pool->Belt.Array.forEach(
      v => {
        v.instance = None
        v.status = v.id == "primary-a" ? #Active : #Background
      },
    )
  })

  test("getActiveViewer returns correct viewer from pool", t => {
    let mockViewer = Obj.magic({"id": "mock"})
    ViewerPool.registerInstance("panorama-a", mockViewer)

    let v = ViewerState.getActiveViewer()
    t->expect(v)->Expect.toBe(Nullable.make(mockViewer))
  })

  test("getInactiveViewer returns correct viewer from pool", t => {
    let mockViewer = Obj.magic({"id": "mock-inactive"})
    ViewerPool.registerInstance("panorama-b", mockViewer)

    let v = ViewerState.getInactiveViewer()
    t->expect(v)->Expect.toBe(Nullable.make(mockViewer))
  })

  test("getActiveContainerId returns correct ID from pool", t => {
    t->expect(ViewerState.getActiveContainerId())->Expect.toBe("panorama-a")

    ViewerPool.swapActive()
    t->expect(ViewerState.getActiveContainerId())->Expect.toBe("panorama-b")
  })

  test("resetState should reset safety timeout and pool timeouts", t => {
    ViewerState.state.lastSceneId = Nullable.make("s0")

    let _timeoutCalled = ref(false)
    let mockTimeoutId = 123
    let _ = %raw(`
      window.clearTimeout = (id) => {
        if (id === 123) {
          global.timeoutCalled = true;
        }
      }
    `)
    ViewerState.state.loadSafetyTimeout = Nullable.make(mockTimeoutId)
    let _ = %raw(`global.timeoutCalled = false`)

    ViewerState.resetState()

    t->expect(ViewerState.state.lastSceneId)->Expect.toBe(Nullable.null)
    t->expect(ViewerState.state.loadSafetyTimeout)->Expect.toBe(Nullable.null)

    let wasCalled = %raw(`global.timeoutCalled`)
    t->expect(wasCalled)->Expect.toBe(true)

    // Restore
    let _ = %raw(`window.clearTimeout = require('node:timers').clearTimeout`)
  })

  test("initial state should have correct default values", t => {
    t->expect(ViewerState.state.isSwapping)->Expect.toBe(false)
  })
})
