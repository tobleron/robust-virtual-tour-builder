type t = {
  maxCalls: int,
  windowMs: int,
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
  // We assume caller checked canCall, but we check again or just push?
  // Usually recordCall implies success.
  // We should also prune first.
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
