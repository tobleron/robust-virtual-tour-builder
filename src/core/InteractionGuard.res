open InteractionPolicies
open ReBindings

exception Debounced

type state = {
  mutable lastExecution: float,
  mutable timerId: option<int>,
  mutable pendingReject: option<exn => unit>,
  mutable limiter: option<RateLimiter.t>,
}

let registry = Dict.make()
let locks = Dict.make()

let getState = (id) => {
  switch Dict.get(registry, id) {
  | Some(s) => s
  | None =>
    let s = {
      lastExecution: 0.0,
      timerId: None,
      pendingReject: None,
      limiter: None,
    }
    Dict.set(registry, id, s)
    s
  }
}

let isLocked = (key) => {
  switch Dict.get(locks, key) {
  | Some(v) => v
  | None => false
  }
}

let setLock = (key, value) => {
  Dict.set(locks, key, value)
}

let attempt = (id: string, policy: policy, action: unit => Promise.t<'a>): Result.t<Promise.t<'a>, string> => {
  let s = getState(id)
  let now = Date.now()

  switch policy {
  | Throttle(ms, Leading) =>
    if now -. s.lastExecution < Belt.Int.toFloat(ms) {
      Error("Throttled")
    } else {
      s.lastExecution = now
      Ok(action())
    }

  | Throttle(_, Trailing) =>
    Error("Trailing throttle not implemented")

  | Debounce(ms) =>
    switch s.timerId {
    | Some(tid) =>
        Window.clearTimeout(tid)
        // Reject previous pending promise
        switch s.pendingReject {
        | Some(reject) => reject(Debounced)
        | None => ()
        }
    | None => ()
    }

    let p = Promise.make((resolve, reject) => {
      s.pendingReject = Some(reject)
      let tid = Window.setTimeout(() => {
        s.timerId = None
        s.pendingReject = None
        action()
        ->Promise.then(v => {
          resolve(v)
          Promise.resolve()
        })
        ->Promise.catch(e => {
          reject(e)
          Promise.resolve()
        })
        ->ignore
      }, ms)
      s.timerId = Some(tid)
    })
    Ok(p)

  | Mutex(scope) =>
    let lockKey = switch scope {
    | Global => "global_mutex"
    | Keyed(k) => "mutex_" ++ k
    }

    if isLocked(lockKey) {
      Error("Locked")
    } else {
      setLock(lockKey, true)
      let p = action()
      let wrapped = p->Promise.finally(() => {
        setLock(lockKey, false)
      })
      Ok(wrapped)
    }

  | SlidingWindow(maxCalls, windowMs) =>
    let limiter = switch s.limiter {
    | Some(l) => l
    | None =>
      let l = RateLimiter.make(~maxCalls, ~windowMs)
      s.limiter = Some(l)
      l
    }

    if RateLimiter.canCall(limiter) {
      RateLimiter.recordCall(limiter)
      Ok(action())
    } else {
      Error("Rate limited")
    }
  }
}
