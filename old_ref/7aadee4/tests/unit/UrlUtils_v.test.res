/* tests/unit/UrlUtils_v.test.res */
open Vitest
open UrlUtils

// Global mock for URL
let _ = %raw(`
  globalThis.URL = {
    createObjectURL: (obj) => {
      if (!obj) throw new Error("Invalid object");
      return "blob:mock-url";
    },
    revokeObjectURL: vi.fn()
  }
`)

describe("UrlUtils - Object URL Management", () => {
  beforeEach(() => {
    let _ = %raw(`vi.clearAllMocks()`)
  })

  test("fileToUrl returns raw string for Url variant", t => {
    let url = "https://example.com/pano.jpg"
    let f = Types.Url(url)
    t->expect(fileToUrl(f))->Expect.toBe(url)
  })

  test("fileToUrl returns object URL for Blob variant", t => {
    let b = Obj.magic({"size": 100})
    let f = Types.Blob(b)
    t->expect(fileToUrl(f))->Expect.toBe("blob:mock-url")
  })

  test("fileToUrl returns object URL for File variant", t => {
    let fileObj = Obj.magic({"name": "test.jpg"})
    let f = Types.File(fileObj)
    t->expect(fileToUrl(f))->Expect.toBe("blob:mock-url")
  })

  test("safeCreateObjectURL returns empty string and logs error on failure", t => {
    // Force error by passing null to our mock which throws
    let result = safeCreateObjectURL(Obj.magic(Nullable.null))
    t->expect(result)->Expect.toBe("")
  })

  test("revokeUrl calls revokeObjectURL for blob URLs", t => {
    revokeUrl("blob:mock-url")
    let calls = %raw(`URL.revokeObjectURL.mock.calls.length`)
    t->expect(calls)->Expect.toBe(1)
  })

  test("revokeUrl skips revokeObjectURL for http URLs", t => {
    revokeUrl("http://example.com")
    let calls = %raw(`URL.revokeObjectURL.mock.calls.length`)
    t->expect(calls)->Expect.toBe(0)
  })
})
