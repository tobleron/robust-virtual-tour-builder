/* tests/unit/PathInterpolationTest.res */
open PathInterpolation

let run = () => {
  Console.log("Running PathInterpolation tests...")

  // Test normalizeYaw
  assert(normalizeYaw(0.0) == 0.0)
  assert(normalizeYaw(190.0) == -170.0)
  assert(normalizeYaw(-190.0) == 170.0)
  assert(normalizeYaw(360.0) == 0.0)
  assert(normalizeYaw(720.0) == 0.0)
  Console.log("✓ normalizeYaw")

  // Test interpolateCatmullRom at t=0 and t=1
  let p0 = {yaw: 0.0, pitch: 0.0}
  let p1 = {yaw: 10.0, pitch: 10.0}
  let p2 = {yaw: 20.0, pitch: 20.0}
  let p3 = {yaw: 30.0, pitch: 30.0}
  
  let t0 = interpolateCatmullRom(p0, p1, p2, p3, 0.0)
  assert(t0.yaw == 10.0)
  assert(t0.pitch == 10.0)
  
  // Catmull-Rom at t=1 should be p2
  let t1 = interpolateCatmullRom(p0, p1, p2, p3, 1.0)
  assert(t1.yaw == 20.0)
  assert(t1.pitch == 20.0)
  Console.log("✓ interpolateCatmullRom boundaries")

  // Test getCatmullRomSpline with wrap around
  let points = [
    {yaw: 350.0, pitch: 0.0},
    {yaw: 10.0, pitch: 0.0},
  ]
  let spline = getCatmullRomSpline(points, 10)
  // Check if it correctly interpolated through 360/0 boundary
  // If it didn't, it would go 350 -> 340 ... -> 0 -> 10 which is long way around.
  // Short way is 350 -> 360(0) -> 10.
  let midPoint = Array.getUnsafe(spline, Array.length(spline) / 2)
  assert(normalizeYaw(midPoint.yaw) == 0.0)
  Console.log("✓ getCatmullRomSpline wrap around")

  Console.log("PathInterpolation tests passed!")
}
