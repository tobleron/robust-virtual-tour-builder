// @efficiency: infra-adapter
open Vitest
open ReBindings

describe("ProjectionMath", () => {
  let rect: Dom.rect = {
    width: 1000.0,
    height: 500.0,
    left: 0.0,
    top: 0.0,
    right: 1000.0,
    bottom: 500.0,
    x: 0.0,
    y: 0.0,
  }

  test("degToRad and toRad conversion", t => {
    t->expect(ProjectionMath.toRad(180.0))->Expect.Float.toBeCloseTo(Math.Constants.pi, 5)
    t->expect(ProjectionMath.toRad(0.0))->Expect.toBe(0.0)
  })

  test("getProjState calculates correctly", t => {
    let state = ProjectionMath.getProjState(90.0, rect)
    t->expect(state.aspectRatio)->Expect.toBe(2.0)
    // tan(45deg) = 1.0
    t->expect(state.halfTanHfov)->Expect.Float.toBeCloseTo(1.0, 5)
    // tan(vfov/2) = 1.0 / 2.0 = 0.5
    t->expect(state.halfTanVfov)->Expect.Float.toBeCloseTo(0.5, 5)
    t->expect(state.invHalfTanHfov)->Expect.Float.toBeCloseTo(1.0, 5)
    t->expect(state.invHalfTanVfov)->Expect.Float.toBeCloseTo(2.0, 5)
  })

  test("getScreenCoords center projection", t => {
    let cam = ProjectionMath.makeCamState(0.0, 0.0, 90.0, rect)
    let coords = ProjectionMath.getScreenCoords(cam, 0.0, 0.0, rect)

    switch coords {
    | Some(c) =>
      t->expect(c.x)->Expect.toBe(500.0)
      t->expect(c.y)->Expect.toBe(250.0)
    | None => t->expect(false)->Expect.toBe(true)
    }
  })

  test("getScreenCoords horizontal edge projection", t => {
    let cam = ProjectionMath.makeCamState(0.0, 0.0, 90.0, rect)
    // At 45 degrees yaw, should be at edge of 90deg HFOV
    let coords = ProjectionMath.getScreenCoords(cam, 0.0, 45.0, rect)

    switch coords {
    | Some(c) =>
      t->expect(c.x)->Expect.Float.toBeCloseTo(1000.0, 5)
      t->expect(c.y)->Expect.toBe(250.0)
    | None => t->expect(false)->Expect.toBe(true)
    }
  })

  test("getScreenCoords vertical edge projection", t => {
    let cam = ProjectionMath.makeCamState(0.0, 0.0, 90.0, rect)
    // tan(vfov/2) = 0.5. At tan(pitch) = 0.5 should be at top edge (y=0)
    // pitch = atan(0.5) approx 26.565 deg
    let pitch = Math.atan(0.5) *. 180.0 /. Math.Constants.pi
    let coords = ProjectionMath.getScreenCoords(cam, pitch, 0.0, rect)

    switch coords {
    | Some(c) =>
      t->expect(c.x)->Expect.toBe(500.0)
      t->expect(c.y)->Expect.Float.toBeCloseTo(0.0, 5)
    | None => t->expect(false)->Expect.toBe(true)
    }
  })

  test("getScreenCoords out of view (behind camera)", t => {
    let cam = ProjectionMath.makeCamState(0.0, 0.0, 90.0, rect)
    let coords = ProjectionMath.getScreenCoords(cam, 0.0, 100.0, rect)
    t->expect(coords)->Expect.toBeNone
  })

  test("getScreenCoords wrap around logic", t => {
    let cam = ProjectionMath.makeCamState(170.0, 0.0, 90.0, rect)
    // target at -170 should be wrap around to 190, diff should be 20 deg
    let coords = ProjectionMath.getScreenCoords(cam, 0.0, -170.0, rect)

    switch coords {
    | Some(c) => t->expect(c.x)->Expect.Float.toBeGreaterThan(500.0)
    | None => t->expect(false)->Expect.toBe(true)
    }
  })

  test("getScreenCoords checks 180 degree boundary", t => {
    let cam = ProjectionMath.makeCamState(0.0, 0.0, 90.0, rect)
    // Directly behind: should return None
    let coords = ProjectionMath.getScreenCoords(cam, 0.0, 180.0, rect)
    t->expect(coords)->Expect.toBeNone
  })

  test("getScreenCoords checks looking straight up", t => {
    let cam = ProjectionMath.makeCamState(0.0, 0.0, 90.0, rect)
    // Looking up at 89 degrees (almost 90)
    let coords = ProjectionMath.getScreenCoords(cam, 89.0, 0.0, rect)
    switch coords {
    | Some(c) => t->expect(c.y)->Expect.Float.toBeLessThan(250.0)
    | None => t->expect(false)->Expect.toBe(true)
    }
  })
})
