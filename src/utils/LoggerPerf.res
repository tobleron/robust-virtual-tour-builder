/* src/utils/LoggerPerf.res */
// @efficiency-role: service-orchestrator

open LoggerCommon

let getPerfThreshold = (durationMs: float) =>
  if durationMs > 500.0 {
    "VERY_SLOW"
  } else if durationMs > 100.0 {
    "SLOW"
  } else {
    "OK"
  }

let getPerfEmoji = (durationMs: float) =>
  if durationMs > 500.0 {
    "🐢"
  } else if durationMs > 100.0 {
    "⏱️"
  } else {
    "⚡"
  }

let getPerfLevel = (durationMs: float) =>
  if durationMs > 500.0 {
    Warn
  } else if durationMs > 100.0 {
    Info
  } else {
    Debug
  }

let enrichPerfData = (data: option<'a>, durationMs: float, threshold: string): JSON.t => {
  let pd = switch data {
  | Some(d) =>
    let obj = Object.assign(Object.make(), asDynamic(d))
    asDynamic(obj)
  | None => asDynamic(Object.make())
  }
  pd["durationMs"] = durationMs
  pd["threshold"] = threshold
  castToJson(pd)
}

let perf = (
  ~emitLog: (string, level, string, option<JSON.t>) => unit,
  ~module_: string,
  ~message: string,
  ~durationMs: float,
  ~data: 'a=?,
  (),
) => {
  let threshold = getPerfThreshold(durationMs)
  let emoji = getPerfEmoji(durationMs)
  let level = getPerfLevel(durationMs)
  emitLog(
    module_,
    level,
    `${emoji} ${message} (${Float.toFixed(durationMs, ~digits=2)}ms)`,
    Some(enrichPerfData(data, durationMs, threshold)),
  )
}

let timed = (
  ~perfFn: (string, string, float) => unit,
  ~module_: string,
  ~operation: string,
  fn: unit => 'a,
): timedResult<'a> => {
  let start = Date.now()
  let result = fn()
  let durationMs = Date.now() -. start
  perfFn(module_, operation, durationMs)
  {result, durationMs}
}

let timedAsync = async (
  ~perfFn: (string, string, float) => unit,
  ~module_: string,
  ~operation: string,
  fn: unit => promise<'a>,
): timedResult<'a> => {
  let start = Date.now()
  let result = await fn()
  let durationMs = Date.now() -. start
  perfFn(module_, operation, durationMs)
  {result, durationMs}
}
