open Vitest
open ViewerTypes

describe("ViewerTypes", () => {
  test("should define ratchetState correctly", t => {
    let state: ratchetState = {
      pitchOffset: 0.0,
      yawOffset: 0.0,
      maxPitchOffset: 10.0,
      minPitchOffset: -10.0,
      maxYawOffset: 20.0,
      minYawOffset: -20.0,
    }

    t->expect(state.pitchOffset)->Expect.toBe(0.0)
    t->expect(state.maxYawOffset)->Expect.toBe(20.0)
  })

  test("should define viewerKey correctly", t => {
    let keyA = A
    let keyB = B

    t->expect(keyA)->Expect.toBe(A)
    t->expect(keyB)->Expect.toBe(B)
  })
})
