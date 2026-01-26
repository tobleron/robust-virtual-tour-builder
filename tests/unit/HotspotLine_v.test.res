/* tests/unit/HotspotLine_v.test.res */
open Vitest

describe("HotspotLine Systems", () => {
  let mockViewer: ReBindings.Viewer.t = Obj.magic({
    "getYaw": () => 0.0,
    "getPitch": () => 0.0,
    "getHfov": () => 90.0,
    "isLoaded": () => true,
    "sceneId": "scene-1",
  })

  beforeEach(() => {
    // Correct way to set active viewer for tests
    ViewerPool.registerInstance("panorama-a", mockViewer)
    GlobalStateBridge.setState(State.initialState)
  })

  test("getScreenCoords: center view", t => {
    let rect: ReBindings.Dom.rect = {
      x: 0.0,
      y: 0.0,
      left: 0.0,
      top: 0.0,
      width: 1000.0,
      height: 500.0,
      right: 1000.0,
      bottom: 500.0,
    }

    let coords = HotspotLine.getScreenCoords(mockViewer, 0.0, 0.0, rect)

    switch coords {
    | Some(c) =>
      t->expect(c.x)->Expect.Float.toBeCloseTo(500.0, 1)
      t->expect(c.y)->Expect.Float.toBeCloseTo(250.0, 1)
    | None => t->expect(true)->Expect.toBe(false) // Should not be None
    }
  })

  test("getScreenCoords: off-center view", t => {
    let rect: ReBindings.Dom.rect = {
      x: 0.0,
      y: 0.0,
      left: 0.0,
      top: 0.0,
      width: 1000.0,
      height: 1000.0,
      right: 1000.0,
      bottom: 1000.0,
    }

    // With 90 deg hfov and square aspect ratio, 45 deg yaw should be at the edge
    let coords = HotspotLine.getScreenCoords(mockViewer, 0.0, 45.0, rect)

    switch coords {
    | Some(c) => t->expect(c.x)->Expect.Float.toBeCloseTo(1000.0, 1)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("updateLines: should handle empty state and no DOM safely", t => {
    // Should run through safely without crashing even if SVG is not found
    HotspotLine.updateLines(mockViewer, State.initialState, ())
    t->expect(true)->Expect.toBe(true)
  })

  test("updateLines: should not crash if viewer not loaded", t => {
    let mockViewerNotLoaded: ReBindings.Viewer.t = Obj.magic({
      "isLoaded": () => false,
    })

    // Temporarily set this as active
    ViewerPool.registerInstance("panorama-a", mockViewerNotLoaded)
    let mockState = State.initialState

    HotspotLine.updateLines(mockViewerNotLoaded, mockState, ())
    t->expect(true)->Expect.toBe(true)
  })

  describe("Math & Logic", () => {
    test(
      "getFloorProjectedPath generates points",
      t => {
        let start: PathInterpolation.point = {yaw: 0.0, pitch: -30.0}
        let end: PathInterpolation.point = {yaw: 10.0, pitch: -40.0}

        let path = PathInterpolation.getFloorProjectedPath(start, end, 10)

        t->expect(Array.length(path))->Expect.toBe(11)
        t->expect(Belt.Array.getExn(path, 0).pitch)->Expect.Float.toBeCloseTo(-30.0, 1)
        t->expect(Belt.Array.getExn(path, 10).pitch)->Expect.Float.toBeCloseTo(-40.0, 1)
      },
    )

    test(
      "drawSimulationArrow: execution check",
      t => {
        // Should not crash even if DOM is missing
        HotspotLine.updateSimulationArrow(mockViewer, 0.0, 0.0, 10.0, 10.0, 0.5, ())
        t->expect(true)->Expect.toBe(true)
      },
    )
  })
})
