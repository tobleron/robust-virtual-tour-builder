open Vitest
open NavigationLogic
open Types

describe("NavigationLogic", () => {
  let createPathData = segments => {
    {
      startPitch: 0.0,
      startYaw: 0.0,
      startHfov: 100.0,
      targetPitchForPan: 0.0,
      targetYawForPan: 0.0,
      targetHfovForPan: 100.0,
      totalPathDistance: 10.0,
      segments,
      waypoints: [],
      panDuration: 1000.0,
      arrivalYaw: 0.0,
      arrivalPitch: 0.0,
      arrivalHfov: 100.0,
    }
  }

  let createSegment = (dist, p1Pitch, p1Yaw, p2Pitch, p2Yaw) => {
    let p1 = {pitch: p1Pitch, yaw: p1Yaw}
    let p2 = {pitch: p2Pitch, yaw: p2Yaw}
    {
      dist,
      yawDiff: p2Yaw -. p1Yaw,
      pitchDiff: p2Pitch -. p1Pitch,
      p1,
      p2,
    }
  }

  test("calculateCameraPosition at start returns start position", t => {
    let segment = createSegment(10.0, 0.0, 0.0, 10.0, 20.0)
    let pathData = createPathData([segment])

    let (pitch, yaw) = calculateCameraPosition(~progress=0.0, ~pathData)

    t->expect(pitch)->Expect.toBe(0.0)
    t->expect(yaw)->Expect.toBe(0.0)
  })

  test("calculateCameraPosition at end returns end position", t => {
    let segment = createSegment(10.0, 0.0, 0.0, 10.0, 20.0)
    let pathData = createPathData([segment])

    let (pitch, yaw) = calculateCameraPosition(~progress=1.0, ~pathData)

    t->expect(pitch)->Expect.toBe(10.0)
    t->expect(yaw)->Expect.toBe(20.0)
  })

  test("calculateCameraPosition interpolates correctly in single segment", t => {
    let segment = createSegment(10.0, 0.0, 0.0, 10.0, 20.0)
    let pathData = createPathData([segment])

    let (pitch, yaw) = calculateCameraPosition(~progress=0.5, ~pathData)

    t->expect(pitch)->Expect.toBe(5.0)
    t->expect(yaw)->Expect.toBe(10.0)
  })

  test("calculateCameraPosition interpolates correctly across multiple segments", t => {
    // Total distance 10.0. Seg 1: 5.0, Seg 2: 5.0.
    // Progress 0.75 means 7.5 distance -> middle of Seg 2.

    let seg1 = createSegment(5.0, 0.0, 0.0, 10.0, 10.0) // 0->10 pitch, 0->10 yaw
    let seg2 = createSegment(5.0, 10.0, 10.0, 20.0, 30.0) // 10->20 pitch, 10->30 yaw

    let pathData = createPathData([seg1, seg2])

    // Check 0.25 (middle of seg 1)
    let (p1, y1) = calculateCameraPosition(~progress=0.25, ~pathData)
    t->expect(p1)->Expect.toBe(5.0)
    t->expect(y1)->Expect.toBe(5.0)

    // Check 0.75 (middle of seg 2)
    let (p2, y2) = calculateCameraPosition(~progress=0.75, ~pathData)
    t->expect(p2)->Expect.toBe(15.0)
    t->expect(y2)->Expect.toBe(20.0)
  })

  test("calculateCameraPosition handles empty segments", t => {
    let pathData = createPathData([])
    let (p, y) = calculateCameraPosition(~progress=0.5, ~pathData)
    // Expect start values
    t->expect(p)->Expect.toBe(0.0)
    t->expect(y)->Expect.toBe(0.0)
  })
})
