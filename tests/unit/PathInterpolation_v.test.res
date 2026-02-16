// @efficiency: infra-adapter
open Vitest
open Vitest.Expect
open PathInterpolation

describe("PathInterpolation", _ => {
  describe("normalizeYaw", _ => {
    test(
      "normalizes angles to [-180, 180]",
      t => {
        t->expect(normalizeYaw(0.0))->toBe(0.0)
        t->expect(normalizeYaw(180.0))->toBe(180.0)
        t->expect(normalizeYaw(-180.0))->toBe(-180.0)
        t->expect(normalizeYaw(190.0))->toBe(-170.0)
        t->expect(normalizeYaw(-190.0))->toBe(170.0)
        t->expect(normalizeYaw(360.0))->toBe(0.0)
        t->expect(normalizeYaw(720.0))->toBe(0.0)
        t->expect(normalizeYaw(-370.0))->toBe(-10.0)
      },
    )
  })

  describe("interpolateBSpline", _ => {
    let p0 = {yaw: 0.0, pitch: 0.0}
    let p1 = {yaw: 10.0, pitch: 10.0}
    let p2 = {yaw: 20.0, pitch: 20.0}
    let p3 = {yaw: 30.0, pitch: 30.0}

    test(
      "interpolates correctly at t=0",
      t => {
        let res = interpolateBSpline(p0, p1, p2, p3, 0.0)
        t->expect(res.yaw)->toBe(10.0)
        t->expect(res.pitch)->toBe(10.0)
      },
    )

    test(
      "interpolates correctly at t=1",
      t => {
        let res = interpolateBSpline(p0, p1, p2, p3, 1.0)
        t->expect(res.yaw)->toBe(20.0)
        t->expect(res.pitch)->toBe(20.0)
      },
    )

    test(
      "interpolates midway",
      t => {
        let res = interpolateBSpline(p0, p1, p2, p3, 0.5)
        t->expect(res.yaw)->toBe(15.0)
        t->expect(res.pitch)->toBe(15.0)
      },
    )
  })

  describe("getBSplinePath", _ => {
    test(
      "returns same points if fewer than 2 provided",
      t => {
        let points = [{yaw: 0.0, pitch: 0.0}]
        let res = getBSplinePath(points, 10)
        t->expect(res)->toEqual(points)
      },
    )

    test(
      "interpolates with wrap around logic",
      t => {
        // 350 -> 10 should go through 0 (distance 20), not -170 (distance 340)
        let points = [{yaw: 350.0, pitch: 0.0}, {yaw: 10.0, pitch: 0.0}]
        let spline = getBSplinePath(points, 2)

        // Verify continuity: no step should jump across the long arc.
        let hasLargeJump = ref(false)
        if Belt.Array.length(spline) >= 2 {
          for i in 0 to Belt.Array.length(spline) - 2 {
            let p1 = Belt.Array.getExn(spline, i)
            let p2 = Belt.Array.getExn(spline, i + 1)
            let delta = Math.abs(normalizeYaw(p2.yaw -. p1.yaw))
            if delta > 40.0 {
              hasLargeJump := true
            }
          }
        }
        t->expect(hasLargeJump.contents)->toBe(false)
      },
    )
  })

  describe("getFloorProjectedPath", _ => {
    test(
      "returns raw points if projection fails (too close to horizon/up)",
      t => {
        let p1 = {yaw: 0.0, pitch: 0.0}
        let p2 = {yaw: 90.0, pitch: 0.0}
        let result = getFloorProjectedPath(p1, p2, 5)
        t->expect(result)->toEqual([p1, p2])
      },
    )

    test(
      "returns projected path for downward looking points",
      t => {
        // Look 45 degrees down
        let p1 = {yaw: 0.0, pitch: -45.0} // x=0, z=-1 (r=1)
        let p2 = {yaw: 90.0, pitch: -45.0} // x=1, z=0 (r=1)

        let result = getFloorProjectedPath(p1, p2, 10)
        t->expect(Belt.Array.length(result) > 2)->toBe(true)

        // Midway point should check out
        // Linear interpolation on floor plane between (0,1) and (1,0) at t=0.5 is (0.5, 0.5)
        // r = sqrt(0.5^2 + 0.5^2) = sqrt(0.5) = 0.707
        // pitch = atan(-1/r) = atan(-1.414) -> approx -54.7 degrees
        // yaw = atan2(0.5, 0.5) -> 45 degrees

        let mid = Belt.Array.getExn(result, 5)
        t->expect(Math.abs(mid.yaw -. 45.0) < 0.1)->toBe(true)
        t->expect(Math.abs(mid.pitch -. -54.7) < 0.1)->toBe(true)
      },
    )
  })

  describe("getSphericalPath", _ => {
    test(
      "returns start and end if points are too close",
      t => {
        let p1 = {yaw: 0.0, pitch: 0.0}
        let p2 = {yaw: 0.0, pitch: 0.0001}
        let res = getSphericalPath(p1, p2, 5)
        t->expect(res)->toEqual([p1, p2])
      },
    )

    test(
      "interpolates along great circle",
      t => {
        let p1 = {yaw: 0.0, pitch: 0.0}
        let p2 = {yaw: 90.0, pitch: 0.0}
        let res = getSphericalPath(p1, p2, 2)

        // Midway (t=0.5) should be yaw 45, pitch 0
        // Index 1 (0, 1, 2)
        let mid = Belt.Array.getExn(res, 1)
        t->expect(Math.abs(mid.yaw -. 45.0) < 0.1)->toBe(true)
        t->expect(Math.abs(mid.pitch -. 0.0) < 0.1)->toBe(true)
      },
    )
  })
})
