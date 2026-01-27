/* tests/unit/BackendApi_v.test.res */
open Vitest
open ReBindings
open BackendApi

describe("BackendApi", () => {
  beforeEach(() => {
    let _ = %raw(`globalThis.fetch = vi.fn()`)
    let _ = %raw(`
      globalThis.FormData = class {
        constructor() { this.data = new Map() }
        append(k, v) { this.data.set(k, v) }
      }
    `)
  })

  describe("Decoders", () => {
    test(
      "decodeImportResponse: valid object",
      t => {
        let json = JSON.Encode.object(
          Dict.fromArray([
            ("sessionId", JSON.Encode.string("sess123")),
            ("projectData", JSON.Encode.object(Dict.make())),
          ]),
        )
        let result = decodeImportResponse(json)
        switch result {
        | Ok(data) => t->expect(data.sessionId)->Expect.toBe("sess123")
        | Error(e) => t->expect(e)->Expect.toBe("Should have been Ok")
        }
      },
    )

    test(
      "decodeImportResponse: missing fields",
      t => {
        let json = JSON.Encode.object(
          Dict.fromArray([("sessionId", JSON.Encode.string("sess123"))]),
        )
        let result = decodeImportResponse(json)
        switch result {
        | Error(msg) => t->expect(msg)->Expect.toBe("Should have failed")
        | Ok(data) => t->expect(data.sessionId)->Expect.toBe("sess123")
        }
      },
    )

    test(
      "decodeGeocodeResponse: valid object",
      t => {
        let json = JSON.Encode.object(
          Dict.fromArray([("address", JSON.Encode.string("123 Street"))]),
        )
        let result = decodeGeocodeResponse(json)
        switch result {
        | Ok(data) => t->expect(data.address)->Expect.toBe("123 Street")
        | Error(e) => t->expect(e)->Expect.toBe("Should have been Ok")
        }
      },
    )
  })

  describe("API Calls", () => {
    let mockFile: File.t = Obj.magic({"name": "test.jpg"})

    testAsync(
      "importProject: success",
      async t => {
        let mockJson = JSON.Encode.object(
          Dict.fromArray([
            ("sessionId", JSON.Encode.string("sess123")),
            ("projectData", JSON.Encode.object(Dict.make())),
          ]),
        )

        let _ = %raw(`(json) => globalThis.fetch.mockResolvedValue({
          ok: true,
          status: 200,
          json: () => Promise.resolve(json)
        })`)(mockJson)

        let result = await importProject(mockFile)
        switch result {
        | Ok(data) => t->expect(data.sessionId)->Expect.toBe("sess123")
        | Error(e) => t->expect(e)->Expect.toBe("Should have been Ok")
        }
      },
    )

    testAsync(
      "importProject: failure (backend error)",
      async t => {
        let _ = %raw(`() => globalThis.fetch.mockResolvedValue({
          ok: false,
          status: 500,
          statusText: "Internal Server Error",
          json: () => Promise.resolve({ error: "Something went wrong", details: "Detail msg" })
        })`)()

        let result = await importProject(mockFile)
        switch result {
        | Ok(_) => t->expect("Success")->Expect.toBe("Failure")
        | Error(e) => {
            let re = RegExp.fromString("Backend error: 500 Detail msg")
            t->expect(e)->Expect.String.toMatch(re)
          }
        }
      },
    )

    testAsync(
      "reverseGeocode: success",
      async t => {
        let mockJson = JSON.Encode.object(
          Dict.fromArray([("address", JSON.Encode.string("Target Address"))]),
        )

        let _ = %raw(`(json) => globalThis.fetch.mockResolvedValue({
          ok: true,
          status: 200,
          json: () => Promise.resolve(json)
        })`)(mockJson)

        let result = await reverseGeocode(0.0, 0.0)
        switch result {
        | Ok(addr) => t->expect(addr)->Expect.toBe("Target Address")
        | Error(e) => t->expect(e)->Expect.toBe("Should have been Ok")
        }
      },
    )

    testAsync(
      "reverseGeocode: service unavailable",
      async t => {
        let _ = %raw(`() => globalThis.fetch.mockResolvedValue({
          ok: false,
          status: 503
        })`)()

        let result = await reverseGeocode(0.0, 0.0)
        t->expect(result)->Expect.toEqual(Error("Geocoding service unavailable"))
      },
    )
  })
})
