/* tests/unit/HLTests.test.res */
open Vitest

describe("HotspotLine Systems", () => {
  test("getScreenCoords: center view", t => {
    let mockViewer: ReBindings.Viewer.t = Obj.magic({
      "getYaw": () => 0.0,
      "getPitch": () => 0.0,
      "getHfov": () => 90.0,
    })

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

    // Center point (pitch 0, yaw 0) when looking at (0,0) with 90 hfov
    let coords = HotspotLine.getScreenCoords(mockViewer, 0.0, 0.0, rect)
    Expect.toBeSome(t->expect(coords))
    switch coords {
    | Some(c) =>
      t->expect(c.x)->Expect.Float.toBeCloseTo(500.0, 1)
      t->expect(c.y)->Expect.Float.toBeCloseTo(250.0, 1)
    | None => ()
    }
  })

  test("getScreenCoords: off-center view", t => {
    let mockViewer: ReBindings.Viewer.t = Obj.magic({
      "getYaw": () => 0.0,
      "getPitch": () => 0.0,
      "getHfov": () => 90.0,
    })

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
    Expect.toBeSome(t->expect(coords))
    switch coords {
    | Some(c) => t->expect(c.x)->Expect.Float.toBeCloseTo(1000.0, 1)
    | None => ()
    }
  })
})

describe("Floor Projection Math", () => {
  test("getFloorProjectedPath generates points", t => {
    let start = {PathInterpolation.yaw: 0.0, pitch: -30.0}
    let end = {PathInterpolation.yaw: 10.0, pitch: -40.0}

    let path = PathInterpolation.getFloorProjectedPath(start, end, 10)

    t->expect(Array.length(path))->Expect.toBe(11)
    t->expect(Belt.Array.getExn(path, 0).pitch)->Expect.Float.toBeCloseTo(-30.0, 1)
    t->expect(Belt.Array.getExn(path, 10).pitch)->Expect.Float.toBeCloseTo(-40.0, 1)
  })
})
