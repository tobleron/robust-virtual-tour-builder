open Vitest
open UiHelpers

describe("UiHelpers", () => {
  test("insertAt helper", t => {
    let originalArr = [1, 2, 3]
    let inserted = insertAt(originalArr, 1, 99)
    t->expect(Belt.Array.length(inserted))->Expect.toEqual(4)
    t->expect(Belt.Array.getExn(inserted, 0))->Expect.toEqual(1)
    t->expect(Belt.Array.getExn(inserted, 1))->Expect.toEqual(99)
    t->expect(Belt.Array.getExn(inserted, 2))->Expect.toEqual(2)
    t->expect(Belt.Array.getExn(inserted, 3))->Expect.toEqual(3)

    let insertedAtStart = insertAt(originalArr, 0, 88)
    t->expect(Belt.Array.getExn(insertedAtStart, 0))->Expect.toEqual(88)
  })
})
