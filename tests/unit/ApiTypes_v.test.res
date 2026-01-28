open Vitest
open ApiTypes

describe("ApiTypes", () => {
  testAsync("decodeImportResponse correctly decodes valid JSON", t => {
    let json = JSON.parseOrThrow(`{"sessionId": "test-session", "projectData": {"foo": "bar"}}`)
    decodeImportResponse(json)->Promise.then(result => {
      switch result {
      | Ok(res) => t->expect(res.sessionId)->Expect.toBe("test-session")
      | Error(msg) => failwith(msg)
      }
      Promise.resolve()
    })
  })

  testAsync("decodeImportResponse fails on invalid JSON", t => {
    let json = JSON.parseOrThrow(`{"foo": "bar"}`)
    decodeImportResponse(json)->Promise.then(result => {
      t->expect(result->Result.isError)->Expect.toBe(true)
      Promise.resolve()
    })
  })

  test("decodeGeocodeResponse correctly decodes valid JSON", t => {
    let json = JSON.parseOrThrow(`{"address": "123 Main St"}`)
    let result = decodeGeocodeResponse(json)
    switch result {
    | Ok(res) => t->expect(res.address)->Expect.toBe("123 Main St")
    | Error(msg) => failwith(msg)
    }
  })
})
