/* @efficiency-role: infra-adapter */

type t = {
  maxCalls: int,
  windowMs: int,
  // JUSTIFIED: imperative singleton
  mutable timestamps: array<float>,
}

let make = (~maxCalls: int, ~windowMs: int) => {
  {
    maxCalls,
    windowMs,
    timestamps: [],
  }
}

let prune = t => {
  let now = Date.now()
  let limit = now -. Belt.Int.toFloat(t.windowMs)
  t.timestamps = t.timestamps->Belt.Array.keep(ts => ts > limit)
}

let canCall = t => {
  prune(t)
  Array.length(t.timestamps) < t.maxCalls
}

let recordCall = t => {
  prune(t)
  t.timestamps = Belt.Array.concat(t.timestamps, [Date.now()])
}

let remainingCalls = t => {
  prune(t)
  t.maxCalls - Array.length(t.timestamps)
}

let reset = t => {
  t.timestamps = []
}
