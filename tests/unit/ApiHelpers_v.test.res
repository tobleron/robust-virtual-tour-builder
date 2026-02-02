open Vitest

describe("ApiHelpers", () => {
  test("decodeImportResponse", t => {
    let json = try {
      JSON.parseOrThrow(`{
        "sessionId": "sess1",
        "projectData": {}
      }`)
    } catch {
    | _ => failwith("Invalid JSON")
    }

    switch ApiHelpers.decodeImportResponse(json) {
    | Ok(res) => t->expect(res.sessionId)->Expect.toBe("sess1")
    | Error(e) => {
        Console.log(e)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("decodeValidationReport", t => {
    let json = try {
      JSON.parseOrThrow(`{
        "brokenLinksRemoved": 5,
        "orphanedScenes": ["s1"],
        "unusedFiles": [],
        "warnings": ["w1"],
        "errors": []
      }`)
    } catch {
    | _ => failwith("Invalid JSON")
    }

    switch ApiHelpers.decodeValidationReport(json) {
    | Ok(res) => {
        t->expect(res.brokenLinksRemoved)->Expect.toBe(5)
        t->expect(res.orphanedScenes)->Expect.toEqual(["s1"])
      }
    | Error(e) => {
        Console.log(e)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("decodeGeocodeResponse", t => {
    let json = try {
      JSON.parseOrThrow(`{
        "address": "123 Street"
      }`)
    } catch {
    | _ => failwith("Invalid JSON")
    }

    switch ApiHelpers.decodeGeocodeResponse(json) {
    | Ok(res) => t->expect(res.address)->Expect.toBe("123 Street")
    | Error(e) => {
        Console.log(e)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })
})
