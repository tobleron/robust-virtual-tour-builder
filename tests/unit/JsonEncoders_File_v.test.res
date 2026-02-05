open Vitest
open JsonCombinators.Json

describe("JsonEncoders File/Blob Persistence Fix", () => {
  test("JsonParsersEncoders.file encodes File as empty string", t => {
    let dummyFile: ReBindings.File.t = %raw("{}")
    let f = Types.File(dummyFile)

    let json = JsonParsersEncoders.file(f)
    t->expect(stringify(json))->Expect.toBe("\"\"")
  })

  test("JsonParsersEncoders.file encodes Blob as empty string", t => {
    let dummyBlob: ReBindings.Blob.t = %raw("{}")
    let f = Types.Blob(dummyBlob)

    let json = JsonParsersEncoders.file(f)
    t->expect(stringify(json))->Expect.toBe("\"\"")
  })

  test("JsonParsersEncoders.file encodes Url as string", t => {
    let f = Types.Url("http://example.com/image.jpg")
    let json = JsonParsersEncoders.file(f)
    t->expect(stringify(json))->Expect.toBe("\"http://example.com/image.jpg\"")
  })

  test("JsonEncoders.Upload.encodeFileFromTypes preserves File object via identity", t => {
    let dummyFile: ReBindings.File.t = %raw("{}")
    let f = Types.File(dummyFile)

    let json = JsonEncoders.Upload.encodeFileFromTypes(f)
    t->expect(stringify(json))->Expect.toBe("{}")
  })
})
