/* src/utils/WorkerPool.res */

type worker
type workerMessageEvent

@new external makeWorker: string => worker = "Worker"
@send external postMessage: (worker, 'a) => unit = "postMessage"
@send external terminate: (worker, unit) => unit = "terminate"
@set external setOnMessage: (worker, workerMessageEvent => unit) => unit = "onmessage"
@set external setOnError: (worker, 'a => unit) => unit = "onerror"
@get external getEventData: workerMessageEvent => 'a = "data"

type fingerprintResponse = {id: string, ok: bool, checksum: option<string>, error: option<string>}

type fingerprintWaiter = {
  id: string,
  resolve: option<string> => unit,
}

type state = {
  workers: array<worker>,
  readyRef: ref<bool>,
  nextWorkerIdxRef: ref<int>,
  waitersRef: ref<array<fingerprintWaiter>>,
}

let poolRef: ref<option<state>> = ref(None)

let createPoolSize = (): int => {
  let cores: int = %raw("(typeof navigator !== 'undefined' && navigator.hardwareConcurrency) ? navigator.hardwareConcurrency : 2")
  let proposed = cores - 1
  if proposed < 1 {
    1
  } else if proposed > 8 {
    8
  } else {
    proposed
  }
}

let takeWorker = (pool: state): worker => {
  let idx = pool.nextWorkerIdxRef.contents
  let worker = pool.workers->Belt.Array.getExn(idx)
  let nextIdx = idx + 1
  pool.nextWorkerIdxRef := if nextIdx >= Belt.Array.length(pool.workers) {0} else {nextIdx}
  worker
}

let removeWaiter = (pool: state, id: string): option<fingerprintWaiter> => {
  let found = ref(None)
  pool.waitersRef := pool.waitersRef.contents->Belt.Array.keep(waiter => {
    if waiter.id == id {
      found := Some(waiter)
      false
    } else {
      true
    }
  })
  found.contents
}

let bindWorkerHandlers = (pool: state, worker: worker) => {
  setOnMessage(worker, evt => {
    let payload: fingerprintResponse = getEventData(evt)
    switch removeWaiter(pool, payload.id) {
    | Some(waiter) =>
      if payload.ok {
        waiter.resolve(payload.checksum)
      } else {
        waiter.resolve(None)
      }
    | None => ()
    }
  })
  setOnError(worker, _err => ())
}

let ensurePool = (): option<state> => {
  switch poolRef.contents {
  | Some(pool) if pool.readyRef.contents => Some(pool)
  | _ =>
    try {
      let size = createPoolSize()
      let workers = Belt.Array.makeBy(size, _ => makeWorker("/workers/image-worker.js"))
      let pool = {
        workers,
        readyRef: ref(true),
        nextWorkerIdxRef: ref(0),
        waitersRef: ref([]),
      }
      workers->Belt.Array.forEach(w => bindWorkerHandlers(pool, w))
      poolRef := Some(pool)
      Some(pool)
    } catch {
    | _ =>
      poolRef := None
      None
    }
  }
}

let fingerprintWithWorker = (file: BrowserBindings.File.t): Promise.t<option<string>> => {
  switch ensurePool() {
  | None => Promise.resolve(None)
  | Some(pool) =>
    Promise.make((resolve, _reject) => {
      let id = Math.random()->Float.toString ++ "_" ++ Date.now()->Float.toInt->Int.toString
      pool.waitersRef := Belt.Array.concat(pool.waitersRef.contents, [{id, resolve}])
      let worker = takeWorker(pool)
      postMessage(worker, {"id": id, "type": "fingerprint", "file": file})
    })
  }
}

let shutdown = () => {
  switch poolRef.contents {
  | Some(pool) =>
    pool.workers->Belt.Array.forEach(w => terminate(w, ()))
    poolRef := None
  | None => ()
  }
}
