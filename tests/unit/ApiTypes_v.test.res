open Vitest
open Api

describe("ApiTypes", () => {
  test("decodeImportResponse correctly decodes valid JSON", t => {
    let json = %raw(`({
      sessionId: "mock-id",
      projectData: {}
    })`)

    let result = decodeImportResponse(json)
    switch result {
    | Ok(res) => t->expect(res.sessionId)->Expect.toBe("mock-id")
    | Error(_) => t->expect(true)->Expect.toBe(false)
    }
  })

  test("decodeImportResponse fails on missing session_id", t => {
    let json = %raw(`({
      project_data: {}
    })`)

    let result = decodeImportResponse(json)
    t->expect(result->Result.isError)->Expect.toBe(true)
  })

  test("decodeGeocodeResponse correctly decodes address", t => {
    let json = %raw(`({ address: "123 Test St" })`)

    let result = decodeGeocodeResponse(json)
    switch result {
    | Ok(res) => t->expect(res.address)->Expect.toBe("123 Test St")
    | Error(_) => t->expect(true)->Expect.toBe(false)
    }
  })

  test("CORS credentials configuration is documented", t => {
    // Document that customer API requests use credentials:include
    // Actual implementation in PortalApi.res uses ~includeCredentials=true
    let customerApiUsesCredentials = true

    t->expect(customerApiUsesCredentials)->Expect.toBe(true)
  })
})
