open Vitest

describe("ViewerState", () => {
  beforeEach(() => {
    // Reset pool defaults
    ViewerSystem.Pool.pool := [
      {
        id: "primary-a",
        containerId: "panorama-a",
        instance: None,
        status: #Active,
        cleanupTimeout: None,
      },
      {
        id: "primary-b",
        containerId: "panorama-b",
        instance: None,
        status: #Background,
        cleanupTimeout: None,
      },
    ]
    ViewerState.resetState()
  })

  test("getActiveViewer returns Nullable of active instance", t => {
    let mockViewer: ReBindings.Viewer.t = Obj.magic({"id": "v1"})
    ViewerSystem.Pool.registerInstance("panorama-a", mockViewer)

    let v = ViewerSystem.getActiveViewer()
    t->expect(v)->Expect.toBe(Nullable.make(mockViewer))
  })

  test("getInactiveViewer returns Nullable of background instance", t => {
    let mockViewer: ReBindings.Viewer.t = Obj.magic({"id": "v2"})
    ViewerSystem.Pool.registerInstance("panorama-b", mockViewer)

    let v = ViewerSystem.getInactiveViewer()
    t->expect(v)->Expect.toBe(Nullable.make(mockViewer))
  })

  test("getActiveContainerId returns correct ID based on status", t => {
    t->expect(ViewerSystem.getActiveContainerId())->Expect.toBe("panorama-a")
  })

  test("resetState resets lastSceneId and timers", t => {
    ViewerState.state := {...ViewerState.state.contents, lastSceneId: Nullable.make("s0")}
    ViewerSystem.resetState()
    t->expect(ViewerState.state.contents.lastSceneId)->Expect.toBe(Nullable.null)
  })
})
