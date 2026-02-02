/* src/utils/LoggerLogic.res */

open LoggerCommon

let getPerfThreshold = (durationMs: float) => {
  if durationMs > 500.0 {
    "VERY_SLOW"
  } else if durationMs > 100.0 {
    "SLOW"
  } else {
    "OK"
  }
}

let getPerfEmoji = (durationMs: float) => {
  if durationMs > 500.0 {
    "🐢"
  } else if durationMs > 100.0 {
    "⏱️"
  } else {
    "⚡"
  }
}

let getPerfLevel = (durationMs: float) => {
  if durationMs > 500.0 {
    Warn
  } else if durationMs > 100.0 {
    Info
  } else {
    Debug
  }
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
