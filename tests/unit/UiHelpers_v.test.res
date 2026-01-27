open Vitest
open UiHelpers
open Types

describe("UiHelpers", () => {
  test("insertAt helper", t => {
    let originalArr = [1, 2, 3]
    let inserted = insertAt(originalArr, 1, 99)
    t->expect(Belt.Array.length(inserted))->Expect.toBe(4)
    t->expect(Belt.Array.getExn(inserted, 0))->Expect.toBe(1)
    t->expect(Belt.Array.getExn(inserted, 1))->Expect.toBe(99)
    t->expect(Belt.Array.getExn(inserted, 2))->Expect.toBe(2)
    t->expect(Belt.Array.getExn(inserted, 3))->Expect.toBe(3)

    let insertedAtStart = insertAt(originalArr, 0, 88)
    t->expect(Belt.Array.getExn(insertedAtStart, 0))->Expect.toBe(88)
  })

  test("decodeFile from string", t => {
    let json = JSON.Encode.string("https://example.com/image.jpg")
    let decoded = decodeFile(json)
    t->expect(decoded)->Expect.toEqual(Url("https://example.com/image.jpg"))
  })

  test("decodeFile from invalid json", t => {
    let json = JSON.Encode.null
    let decoded = decodeFile(json)
    t->expect(decoded)->Expect.toEqual(Url(""))
  })

  test("fileToBlob and fileToFile helpers", t => {
    let f = Url("some-url")
    t->expect(fileToFile(f))->Expect.toEqual(None)
  })
})
