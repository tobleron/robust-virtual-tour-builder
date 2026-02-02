open Vitest

describe("JsonParsersShared", () => {
  test("exifMetadata decoder with full data", t => {
    let json = try {
      JSON.parseOrThrow(`{
        "dateTime": "2023:01:01 12:00:00",
        "gps": {
          "lat": 10.0,
          "lon": 20.0
        },
        "make": "Canon",
        "model": "EOS",
        "width": 1000,
        "height": 500,
        "focalLength": 24.0,
        "aperture": 2.8,
        "iso": 100
      }`)
    } catch {
    | _ => failwith("Invalid JSON setup")
    }

    switch JsonCombinators.Json.decode(json, JsonParsersShared.exifMetadata) {
    | Ok(m) => {
        t->expect(Nullable.toOption(m.dateTime))->Expect.toBe(Some("2023:01:01 12:00:00"))
        t->expect(Nullable.toOption(m.make))->Expect.toBe(Some("Canon"))
        t->expect(m.width)->Expect.toBe(1000)

        let gps = Nullable.toOption(m.gps)->Option.getOrThrow
        t->expect(gps.lat)->Expect.toBe(10.0)
      }
    | Error(msg) => {
        Console.log("exifMetadata failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("exifMetadata decoder with minimal data", t => {
    let json = try {
      JSON.parseOrThrow(`{}`)
    } catch {
    | _ => failwith("Invalid JSON setup")
    }

    switch JsonCombinators.Json.decode(json, JsonParsersShared.exifMetadata) {
    | Ok(m) => {
        t->expect(Nullable.toOption(m.dateTime))->Expect.toBe(None)
        t->expect(m.width)->Expect.toBe(0) // Default value
        t->expect(Nullable.toOption(m.gps))->Expect.toBe(None)
      }
    | Error(msg) => {
        Console.log("exifMetadata minimal failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("qualityAnalysis decoder", t => {
    let json = try {
      JSON.parseOrThrow(`{
        "score": 0.8,
        "isBlurry": true,
        "issues": 2,
        "analysis": "Too blurry"
      }`)
    } catch {
    | _ => failwith("Invalid JSON setup")
    }

    switch JsonCombinators.Json.decode(json, JsonParsersShared.qualityAnalysis) {
    | Ok(q) => {
        t->expect(q.score)->Expect.toBe(0.8)
        t->expect(q.isBlurry)->Expect.toBe(true)
        t->expect(q.issues)->Expect.toBe(2)
        t->expect(Nullable.toOption(q.analysis))->Expect.toBe(Some("Too blurry"))
        // Defaults
        t->expect(q.isSeverelyDark)->Expect.toBe(false)
      }
    | Error(msg) => {
        Console.log("qualityAnalysis failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("importResponse decoder", t => {
    let json = try {
      JSON.parseOrThrow(`{
        "sessionId": "sess123",
        "projectData": { "some": "data" }
      }`)
    } catch {
    | _ => failwith("Invalid JSON setup")
    }

    switch JsonCombinators.Json.decode(json, JsonParsersShared.importResponse) {
    | Ok(r) => {
        t->expect(r.sessionId)->Expect.toBe("sess123")
        // projectData is 'id' decoder, so it returns Json.t
        t->expect(JsonCombinators.Json.decode(r.projectData, JsonCombinators.Json.Decode.object(f => f.required("some", JsonCombinators.Json.Decode.string))))
          ->Expect.toEqual(Ok("data"))
      }
    | Error(msg) => {
        Console.log("importResponse failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })
})
