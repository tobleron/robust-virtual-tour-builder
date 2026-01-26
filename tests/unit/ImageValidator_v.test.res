open Vitest

describe("ImageValidator", () => {
  let mockFile = (name, type_) => {
    Obj.magic({"name": name, "type": type_})
  }

  test("validateFiles filters non-images", t => {
    let f1 = mockFile("test.jpg", "image/jpeg")
    let f2 = mockFile("test.txt", "text/plain")
    let invalid = ref([])
    let result = ImageValidator.validateFiles(
      [f1, f2],
      name => {
        let _ = Array.push(invalid.contents, name)
      },
    )

    t->expect(Array.length(result))->Expect.toBe(1)
    t->expect(Array.length(invalid.contents))->Expect.toBe(1)
    t->expect(Belt.Array.getExn(invalid.contents, 0))->Expect.toBe("test.txt")
  })

  test("validateFiles handles case insensitive extensions", t => {
    let f1 = mockFile("test.JPG", "image/jpeg")
    let result = ImageValidator.validateFiles([f1], _ => ())
    t->expect(Array.length(result))->Expect.toBe(1)
  })
})
