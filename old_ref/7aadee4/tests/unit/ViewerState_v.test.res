open Vitest

describe("ViewerState", () => {
  beforeEach(() => {
    // Reset state defaults
    ViewerState.state.activeViewerKey = A
    ViewerState.state.viewerA = Nullable.null
    ViewerState.state.viewerB = Nullable.null
  })

  test("getActiveViewer returns correct viewer based on key", t => {
    ViewerState.state.activeViewerKey = A
    let v = ViewerState.getActiveViewer()
    t->expect(v)->Expect.toBe(ViewerState.state.viewerA)

    ViewerState.state.activeViewerKey = B
    let v2 = ViewerState.getActiveViewer()
    t->expect(v2)->Expect.toBe(ViewerState.state.viewerB)
  })

  test("getInactiveViewer returns opposite viewer", t => {
    ViewerState.state.activeViewerKey = A
    t->expect(ViewerState.getInactiveViewer())->Expect.toBe(ViewerState.state.viewerB)

    ViewerState.state.activeViewerKey = B
    t->expect(ViewerState.getInactiveViewer())->Expect.toBe(ViewerState.state.viewerA)
  })

  test("getActiveContainerId returns correct ID", t => {
    ViewerState.state.activeViewerKey = A
    t->expect(ViewerState.getActiveContainerId())->Expect.toBe("panorama-a")

    ViewerState.state.activeViewerKey = B
    t->expect(ViewerState.getActiveContainerId())->Expect.toBe("panorama-b")
  })

  test("resetState should reset loading and safety timeout", t => {
    ViewerState.state.isSceneLoading = true
    ViewerState.state.loadingSceneId = Nullable.make("s1")
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

    t->expect(ViewerState.state.isSceneLoading)->Expect.toBe(false)
    t->expect(ViewerState.state.loadingSceneId)->Expect.toBe(Nullable.null)
    t->expect(ViewerState.state.lastSceneId)->Expect.toBe(Nullable.null)
    t->expect(ViewerState.state.loadSafetyTimeout)->Expect.toBe(Nullable.null)

    let wasCalled = %raw(`global.timeoutCalled`)
    t->expect(wasCalled)->Expect.toBe(true)

    // Restore
    let _ = %raw(`window.clearTimeout = require('node:timers').clearTimeout`)
  })

  test("initial state should have correct default values for new fields", t => {
    t->expect(ViewerState.state.isSwapping)->Expect.toBe(false)
    t->expect(ViewerState.state.mouseVelocityX)->Expect.toBe(0.0)
    t->expect(ViewerState.state.mouseVelocityY)->Expect.toBe(0.0)
    t->expect(ViewerState.state.lastMoveX)->Expect.toBe(0.0)
    t->expect(ViewerState.state.lastMoveY)->Expect.toBe(0.0)
  })
})
