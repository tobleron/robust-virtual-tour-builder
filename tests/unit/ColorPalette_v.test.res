/* tests/unit/ColorPalette_v.test.res */
open Vitest

describe("ColorPalette", () => {
  describe("getGroupColor", () => {
    test(
      "should return default color for None",
      t => {
        t->expect(ColorPalette.getGroupColor(None))->Expect.toBe("#f1f5f9")
      },
    )

    test(
      "should return correct color for valid id",
      t => {
        t->expect(ColorPalette.getGroupColor(Some("1")))->Expect.toBe("#3b82f6")
        t->expect(ColorPalette.getGroupColor(Some("8")))->Expect.toBe("#84cc16")
      },
    )

    test(
      "should return correct color for id requiring modulo",
      t => {
        t->expect(ColorPalette.getGroupColor(Some("9")))->Expect.toBe("#3b82f6")
      },
    )

    test(
      "should return default color for id 0",
      t => {
        t->expect(ColorPalette.getGroupColor(Some("0")))->Expect.toBe("#f1f5f9")
      },
    )

    test(
      "should return default color for negative id",
      t => {
        t->expect(ColorPalette.getGroupColor(Some("-1")))->Expect.toBe("#f1f5f9")
      },
    )

    test(
      "should return default color for non-numeric id",
      t => {
        t->expect(ColorPalette.getGroupColor(Some("abc")))->Expect.toBe("#f1f5f9")
      },
    )
  })

  describe("getGroupClass", () => {
    test(
      "should return default class for None",
      t => {
        t->expect(ColorPalette.getGroupClass(None))->Expect.toBe("group-color-default")
      },
    )

    test(
      "should return correct class for valid id",
      t => {
        t->expect(ColorPalette.getGroupClass(Some("1")))->Expect.toBe("group-color-0")
        t->expect(ColorPalette.getGroupClass(Some("8")))->Expect.toBe("group-color-7")
      },
    )

    test(
      "should return correct class for id requiring modulo",
      t => {
        t->expect(ColorPalette.getGroupClass(Some("9")))->Expect.toBe("group-color-0")
      },
    )

    test(
      "should return default class for id 0",
      t => {
        t->expect(ColorPalette.getGroupClass(Some("0")))->Expect.toBe("group-color-default")
      },
    )

    test(
      "should return default class for negative id",
      t => {
        t->expect(ColorPalette.getGroupClass(Some("-1")))->Expect.toBe("group-color-default")
      },
    )

    test(
      "should return default class for non-numeric id",
      t => {
        t->expect(ColorPalette.getGroupClass(Some("abc")))->Expect.toBe("group-color-default")
      },
    )
  })
})
