open Vitest
open ApiHelpers

describe("ApiHelpers", () => {
  test("extractErrorMessage should use details if available", t => {
    let err = {
      error: "Bad Request",
      details: Nullable.make("Missing parameter: id"),
    }
    t->expect(extractErrorMessage(err))->Expect.toBe("Missing parameter: id")
  })

  test("extractErrorMessage should fallback to error field", t => {
    let err = {
      error: "Internal Server Error",
      details: Nullable.null,
    }
    t->expect(extractErrorMessage(err))->Expect.toBe("Internal Server Error")
  })

  testAsync("handleResponse should return Ok for success status", async t => {
    let mockResponse = Obj.magic({
      "ok": true,
      "status": 200,
      "statusText": "OK",
    })

    let result = await handleResponse(mockResponse)
    switch result {
    | Ok(_) => t->expect(true)->Expect.toBe(true)
    | Error(_) => t->expect("Ok")->Expect.toBe("Error")
    }
  })
})
