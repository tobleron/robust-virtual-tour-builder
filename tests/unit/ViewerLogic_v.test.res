// @efficiency: infra-adapter
open Vitest

describe("ViewerLogic", () => {
  describe("getEdgePower", () => {
    test(
      "returns 0.0 when inside deadzone",
      t => {
        t->expect(ViewerLogic.getEdgePower(0.5, 0.6))->Expect.toBe(0.0)
        t->expect(ViewerLogic.getEdgePower(-0.5, 0.6))->Expect.toBe(0.0)
        t->expect(ViewerLogic.getEdgePower(0.0, 0.1))->Expect.toBe(0.0)
      },
    )

    test(
      "returns positive power when above deadzone",
      t => {
        // val = 0.5, dz = 0.0
        // a = 0.5, n = 0.5 / 1.0 = 0.5
        // s = 1.0
        // res = 0.5 * 0.5 = 0.25
        t->expect(ViewerLogic.getEdgePower(0.5, 0.0))->Expect.toBe(0.25)
      },
    )

    test(
      "returns negative power when below negative deadzone",
      t => {
        // val = -0.5, dz = 0.0
        // a = 0.5, n = 0.5 / 1.0 = 0.5
        // s = -1.0
        // res = -0.25
        t->expect(ViewerLogic.getEdgePower(-0.5, 0.0))->Expect.toBe(-0.25)
      },
    )

    test(
      "calculates curve correctly",
      t => {
        // val = 0.8, dz = 0.6
        // a = 0.8
        // n = (0.8 - 0.6) / (1.0 - 0.6) = 0.2 / 0.4 = 0.5
        // res = 0.5 * 0.5 = 0.25
        t->expect(ViewerLogic.getEdgePower(0.8, 0.6))->Expect.Float.toBeCloseTo(0.25, 5)
      },
    )
  })

  describe("getBoost", () => {
    test(
      "returns 0.0 when velocity is low",
      t => {
        t->expect(ViewerLogic.getBoost(400.0))->Expect.toBe(0.0)
        t->expect(ViewerLogic.getBoost(-400.0))->Expect.toBe(0.0)
        t->expect(ViewerLogic.getBoost(500.0))->Expect.toBe(0.0)
      },
    )

    test(
      "scales linearly above 500",
      t => {
        // vel = 2000
        // a = 2000
        // (2000 - 500) / 3000 = 1500 / 3000 = 0.5
        // min(0.5, 1.5) = 0.5
        t->expect(ViewerLogic.getBoost(2000.0))->Expect.Float.toBeCloseTo(0.5, 5)
      },
    )

    test(
      "clamps at 1.5",
      t => {
        // vel = 8000
        // (8000 - 500) / 3000 = 7500 / 3000 = 2.5
        // min(2.5, 1.5) = 1.5
        t->expect(ViewerLogic.getBoost(8000.0))->Expect.toBe(1.5)
      },
    )
  })
})
