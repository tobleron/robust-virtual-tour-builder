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
})
