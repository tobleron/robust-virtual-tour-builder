open Vitest

let mkHealthJson = (
  ~status="ok",
  ~includeRuntime=true,
  ~includeDetails=false,
  (),
): JSON.t => {
  let baseFields: array<(string, JSON.t)> = [
    ("status", JsonCombinators.Json.Encode.string(status)),
    ("timestamp", JsonCombinators.Json.Encode.string("2026-03-05T10:00:00Z")),
    (
      "db",
      JsonCombinators.Json.Encode.object([
        ("status", JsonCombinators.Json.Encode.string("ok")),
        ("message", JsonCombinators.Json.Encode.null),
      ]),
    ),
    (
      "disk",
      JsonCombinators.Json.Encode.object([
        ("status", JsonCombinators.Json.Encode.string("ok")),
        ("cacheDir", JsonCombinators.Json.Encode.string("../cache")),
        ("databaseDir", JsonCombinators.Json.Encode.string("data")),
      ]),
    ),
    (
      "cache",
      JsonCombinators.Json.Encode.object([
        ("cacheSize", JsonCombinators.Json.Encode.float(50.0)),
        ("maxCacheSize", JsonCombinators.Json.Encode.float(5000.0)),
        ("hits", JsonCombinators.Json.Encode.float(42.0)),
        ("misses", JsonCombinators.Json.Encode.float(8.0)),
        ("hitRate", JsonCombinators.Json.Encode.float(84.0)),
      ]),
    ),
  ]

  let withRuntime = if includeRuntime {
    Belt.Array.concat(
      baseFields,
      [(
        "runtime",
        JsonCombinators.Json.Encode.object([("activeSessions", JsonCombinators.Json.Encode.float(3.0))]),
      )],
    )
  } else {
    baseFields
  }

  let withDetails = if includeDetails {
    Belt.Array.concat(
      withRuntime,
      [("details", JsonCombinators.Json.Encode.string("disk warn"))],
    )
  } else {
    withRuntime
  }

  JsonCombinators.Json.Encode.object(withDetails)
}

describe("AdminHealthApi decoder", () => {
  test("decodes full health payload", t => {
    let json = mkHealthJson(~includeRuntime=true, ~includeDetails=true, ())
    switch JsonCombinators.Json.decode(json, HealthApi.healthSnapshotDecoder) {
    | Ok(decoded) =>
      t->expect(decoded.status)->Expect.toBe("ok")
      t->expect(decoded.runtime.activeSessions)->Expect.toBe(3)
      t->expect(decoded.cache.hits)->Expect.toBe(42)
      t->expect(decoded.details->Option.getOr(""))->Expect.toBe("disk warn")
    | Error(_) => t->expect("decode_error")->Expect.toBe("unexpected")
    }
  })

  test("defaults runtime.activeSessions when runtime missing", t => {
    let json = mkHealthJson(~includeRuntime=false, ())
    switch JsonCombinators.Json.decode(json, HealthApi.healthSnapshotDecoder) {
    | Ok(decoded) => t->expect(decoded.runtime.activeSessions)->Expect.toBe(0)
    | Error(_) => t->expect("decode_error")->Expect.toBe("unexpected")
    }
  })
})
