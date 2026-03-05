open Vitest

let parseJson = (raw: string): JSON.t => {
  switch JsonCombinators.Json.parse(raw) {
  | Ok(json) => json
  | Error(message) => failwith("Fixture JSON parse failed: " ++ message)
  }
}

describe("API Contract Decoders", () => {
  test("geocodeResponse accepts backend contract shape", t => {
    let json = parseJson(`{"address":"Cairo, Egypt"}`)
    switch JsonCombinators.Json.decode(json, JsonParsers.Shared.geocodeResponse) {
    | Ok(decoded) => t->expect(decoded.address)->Expect.toBe("Cairo, Egypt")
    | Error(message) => failwith("Expected geocode contract to decode: " ++ message)
    }
  })

  test("geocodeResponse rejects renamed field drift", t => {
    let json = parseJson(`{"display_name":"Cairo, Egypt"}`)
    switch JsonCombinators.Json.decode(json, JsonParsers.Shared.geocodeResponse) {
    | Ok(_) => failwith("Expected geocode contract drift to fail decoding")
    | Error(_) => t->expect(true)->Expect.toBe(true)
    }
  })

  test("importResponse requires sessionId field", t => {
    let validJson = parseJson(`{"sessionId":"sess_1","projectData":{"tourName":"Demo"}}`)
    switch JsonCombinators.Json.decode(validJson, JsonParsers.Shared.importResponse) {
    | Ok(decoded) => t->expect(decoded.sessionId)->Expect.toBe("sess_1")
    | Error(message) => failwith("Expected importResponse to decode: " ++ message)
    }

    let driftedJson = parseJson(`{"session_id":"sess_1","projectData":{"tourName":"Demo"}}`)
    switch JsonCombinators.Json.decode(driftedJson, JsonParsers.Shared.importResponse) {
    | Ok(_) => failwith("Expected importResponse drift to fail decoding")
    | Error(_) => t->expect(true)->Expect.toBe(true)
    }
  })

  test("metadataResponse requires exif and quality payload", t => {
    let validJson = parseJson(`{
      "exif": {"width": 4000, "height": 2000},
      "quality": {"score": 0.91}
    }`)
    switch JsonCombinators.Json.decode(validJson, JsonParsers.Shared.metadataResponse) {
    | Ok(decoded) => {
        t->expect(decoded.exif.width)->Expect.toBe(4000)
        t->expect(decoded.quality.score)->Expect.toBe(0.91)
      }
    | Error(message) => failwith("Expected metadataResponse to decode: " ++ message)
    }

    let driftedJson = parseJson(`{"exif":{"width":4000,"height":2000}}`)
    switch JsonCombinators.Json.decode(driftedJson, JsonParsers.Shared.metadataResponse) {
    | Ok(_) => failwith("Expected metadataResponse missing quality to fail decoding")
    | Error(_) => t->expect(true)->Expect.toBe(true)
    }
  })

  test("similarityResponse enforces durationMs", t => {
    let validJson = parseJson(`{
      "results": [{"idA":"a","idB":"b","similarity":0.87}],
      "durationMs": 3.1
    }`)
    switch JsonCombinators.Json.decode(validJson, JsonParsers.Shared.similarityResponse) {
    | Ok(decoded) => {
        t->expect(Belt.Array.length(decoded.results))->Expect.toBe(1)
        t->expect(decoded.durationMs)->Expect.toBe(3.1)
      }
    | Error(message) => failwith("Expected similarityResponse to decode: " ++ message)
    }

    let driftedJson = parseJson(`{"results":[{"idA":"a","idB":"b","similarity":0.87}]}`)
    switch JsonCombinators.Json.decode(driftedJson, JsonParsers.Shared.similarityResponse) {
    | Ok(_) => failwith("Expected similarityResponse missing durationMs to fail decoding")
    | Error(_) => t->expect(true)->Expect.toBe(true)
    }
  })
})
