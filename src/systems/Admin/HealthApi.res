open ReBindings

type healthComponent = {
  status: string,
  message: option<string>,
}

type healthDisk = {
  status: string,
  cacheDir: string,
  databaseDir: string,
}

type healthCache = {
  cacheSize: int,
  maxCacheSize: int,
  hits: int,
  misses: int,
  hitRate: float,
}

type healthRuntime = {
  activeSessions: int,
}

type healthSnapshot = {
  status: string,
  timestamp: string,
  db: healthComponent,
  disk: healthDisk,
  cache: healthCache,
  runtime: healthRuntime,
  details: option<string>,
}

let healthComponentDecoder = {
  open JsonCombinators.Json.Decode
  object(field => {
    status: field.required("status", string),
    message: field.optional("message", option(string))->Option.flatMap(x => x),
  })
}

let healthDiskDecoder = {
  open JsonCombinators.Json.Decode
  object(field => {
    status: field.required("status", string),
    cacheDir: field.required("cacheDir", string),
    databaseDir: field.required("databaseDir", string),
  })
}

let floatToInt = (v: float): int => Int.fromFloat(v)

let healthCacheDecoder = {
  JsonCombinators.Json.Decode.object(field => {
    cacheSize: field.required("cacheSize", JsonCombinators.Json.Decode.float)->floatToInt,
    maxCacheSize: field.required("maxCacheSize", JsonCombinators.Json.Decode.float)->floatToInt,
    hits: field.required("hits", JsonCombinators.Json.Decode.float)->floatToInt,
    misses: field.required("misses", JsonCombinators.Json.Decode.float)->floatToInt,
    hitRate: field.required("hitRate", JsonCombinators.Json.Decode.float),
  })
}

let healthRuntimeDecoder = {
  JsonCombinators.Json.Decode.object(field => {
    activeSessions: field.optional("activeSessions", JsonCombinators.Json.Decode.float)->Option.map(
      floatToInt,
    )->Option.getOr(0),
  })
}

let healthSnapshotDecoder = {
  open JsonCombinators.Json.Decode
  object(field => {
    status: field.required("status", string),
    timestamp: field.required("timestamp", string),
    db: field.required("db", healthComponentDecoder),
    disk: field.required("disk", healthDiskDecoder),
    cache: field.required("cache", healthCacheDecoder),
    runtime: field.optional("runtime", healthRuntimeDecoder)->Option.getOr({activeSessions: 0}),
    details: field.optional("details", option(string))->Option.flatMap(x => x),
  })
}

let fetchHealth = (): Promise.t<result<healthSnapshot, string>> => {
  let url = Constants.backendUrl ++ "/api/health?t=" ++ Date.now()->Float.toString
  Fetch.fetchSimple(url)
  ->Promise.then(response =>
    Fetch.json(response)
    ->Promise.then(json => {
      switch JsonCombinators.Json.decode(json, healthSnapshotDecoder) {
      | Ok(snapshot) => Promise.resolve(Ok(snapshot))
      | Error(msg) =>
        Logger.error(
          ~module_="AdminHealthApi",
          ~message="HEALTH_DECODE_FAILED",
          ~data=Some({"error": msg}),
          (),
        )
        Promise.resolve(Error("Health decode failed: " ++ msg))
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="AdminHealthApi",
        ~message="HEALTH_RESPONSE_JSON_FAILED",
        ~data=Some({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Health response parsing failed: " ++ msg))
    })
  )
  ->Promise.catch(e => {
    let (msg, stack) = Logger.getErrorDetails(e)
    Logger.error(
      ~module_="AdminHealthApi",
      ~message="HEALTH_FETCH_FAILED",
      ~data=Some({"error": msg, "stack": stack, "url": url}),
      (),
    )
    Promise.resolve(Error("Health request failed: " ++ msg))
  })
}
