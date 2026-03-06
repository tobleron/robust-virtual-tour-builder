open Vitest

describe("SharedTypes appError", () => {
  test("classifies timeout from message", t => {
    let err = SharedTypes.appErrorFromMessage(~message="Request timeout after 5000ms")
    t->expect(SharedTypes.appErrorType(err))->Expect.toBe("timeout")
    t->expect(SharedTypes.appErrorRetryable(err))->Expect.toBe(true)
  })

  test("classifies permission from HTTP 401", t => {
    let err = SharedTypes.appErrorFromHttpStatus(~status=401, ~message="Unauthorized")
    t->expect(SharedTypes.appErrorType(err))->Expect.toBe("permission")
    t->expect(SharedTypes.appErrorRetryable(err))->Expect.toBe(false)
  })

  test("serializes telemetry envelope keys", t => {
    let err = SharedTypes.NetworkError({message: "offline", code: Some("NET_OFFLINE")})
    let payload = SharedTypes.appErrorToTelemetryJson(err, ~operationContext="api_fetch")
    let decodeField = (key: string) =>
      JsonCombinators.Json.decode(payload, JsonCombinators.Json.Decode.field(key, JsonCombinators.Json.Decode.string))

    switch decodeField("error_type") {
    | Ok(v) => t->expect(v)->Expect.toBe("network")
    | Error(_) => t->expect("missing")->Expect.toBe("error_type")
    }
    switch decodeField("operation_context") {
    | Ok(v) => t->expect(v)->Expect.toBe("api_fetch")
    | Error(_) => t->expect("missing")->Expect.toBe("operation_context")
    }
  })
})
