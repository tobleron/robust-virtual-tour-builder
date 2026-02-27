/* src/utils/WorkerPool.res */

type worker
type workerMessageEvent

@new external makeWorker: string => worker = "Worker"
@send external postMessage: (worker, 'a) => unit = "postMessage"
@send external terminate: (worker, unit) => unit = "terminate"
@set external setOnMessage: (worker, workerMessageEvent => unit) => unit = "onmessage"
@set external setOnError: (worker, 'a => unit) => unit = "onerror"
@get external getEventData: workerMessageEvent => 'a = "data"

type fingerprintResponse = {id: string, ok: bool, checksum: option<string>}
type validateImageResponse = {id: string, ok: bool, isImage: option<bool>}
type generateTinyResponse = {id: string, ok: bool, tiny: option<BrowserBindings.Blob.t>}
type exifResponse = {id: string, ok: bool, width: option<int>, height: option<int>}

type waiter<'a> = {
  id: string,
  resolve: 'a => unit,
}

type state = {
  workers: array<worker>,
  readyRef: ref<bool>,
  nextWorkerIdxRef: ref<int>,
  fingerprintWaitersRef: ref<array<waiter<option<string>>>>,
  validateWaitersRef: ref<array<waiter<option<bool>>>>,
  tinyWaitersRef: ref<array<waiter<option<BrowserBindings.Blob.t>>>>,
  exifWaitersRef: ref<array<waiter<option<(int, int)>>>>,
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

let removeFingerprintWaiter = (pool: state, id: string): option<waiter<option<string>>> => {
  let found = ref(None)
  pool.fingerprintWaitersRef := pool.fingerprintWaitersRef.contents->Belt.Array.keep(waiter => {
    if waiter.id == id {
      found := Some(waiter)
      false
    } else {
      true
    }
  })
  found.contents
}

let removeValidateWaiter = (pool: state, id: string): option<waiter<option<bool>>> => {
  let found = ref(None)
  pool.validateWaitersRef := pool.validateWaitersRef.contents->Belt.Array.keep(waiter => {
    if waiter.id == id {
      found := Some(waiter)
      false
    } else {
      true
    }
  })
  found.contents
}

let removeTinyWaiter = (pool: state, id: string): option<waiter<option<BrowserBindings.Blob.t>>> => {
  let found = ref(None)
  pool.tinyWaitersRef := pool.tinyWaitersRef.contents->Belt.Array.keep(waiter => {
    if waiter.id == id {
      found := Some(waiter)
      false
    } else {
      true
    }
  })
  found.contents
}

let removeExifWaiter = (pool: state, id: string): option<waiter<option<(int, int)>>> => {
  let found = ref(None)
  pool.exifWaitersRef := pool.exifWaitersRef.contents->Belt.Array.keep(waiter => {
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
    let payload: {"id": string, "type": option<string>} = getEventData(evt)
    switch payload["type"] {
    | Some("validateImage") =>
      let validatePayload: validateImageResponse = getEventData(evt)
      switch removeValidateWaiter(pool, validatePayload.id) {
      | Some(waiter) =>
        if validatePayload.ok {
          waiter.resolve(validatePayload.isImage)
        } else {
          waiter.resolve(None)
        }
      | None => ()
      }
    | Some("generateTiny") =>
      let tinyPayload: generateTinyResponse = getEventData(evt)
      switch removeTinyWaiter(pool, tinyPayload.id) {
      | Some(waiter) =>
        if tinyPayload.ok {
          waiter.resolve(tinyPayload.tiny)
        } else {
          waiter.resolve(None)
        }
      | None => ()
      }
    | Some("extractExif") =>
      let exifPayload: exifResponse = getEventData(evt)
      switch removeExifWaiter(pool, exifPayload.id) {
      | Some(waiter) =>
        if exifPayload.ok {
          switch (exifPayload.width, exifPayload.height) {
          | (Some(w), Some(h)) => waiter.resolve(Some((w, h)))
          | _ => waiter.resolve(None)
          }
        } else {
          waiter.resolve(None)
        }
      | None => ()
      }
    | _ =>
      let fingerprintPayload: fingerprintResponse = getEventData(evt)
      switch removeFingerprintWaiter(pool, fingerprintPayload.id) {
      | Some(waiter) =>
        if fingerprintPayload.ok {
          waiter.resolve(fingerprintPayload.checksum)
        } else {
          waiter.resolve(None)
        }
      | None => ()
      }
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
        fingerprintWaitersRef: ref([]),
        validateWaitersRef: ref([]),
        tinyWaitersRef: ref([]),
        exifWaitersRef: ref([]),
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

let fingerprintWithWorker = (
  file: BrowserBindings.File.t,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
): Promise.t<option<string>> => {
  switch ensurePool() {
  | None => Promise.resolve(None)
  | Some(pool) =>
    Promise.make((resolve, _reject) => {
      let id = Math.random()->Float.toString ++ "_" ++ Date.now()->Float.toInt->Int.toString
      let settled = ref(false)
      let finish = value => {
        if !settled.contents {
          settled := true
          resolve(value)
        }
      }
      let removeOnAbort = ref(None)
      signal->Option.forEach(sig => {
        let onAbort = () => {
          let _ = removeFingerprintWaiter(pool, id)
          finish(None)
        }
        BrowserBindings.AbortSignal.addEventListener(sig, "abort", onAbort)
        removeOnAbort := Some(() => BrowserBindings.AbortSignal.removeEventListener(sig, "abort", onAbort))
        if BrowserBindings.AbortSignal.aborted(sig) {
          onAbort()
        }
      })
      pool.fingerprintWaitersRef := Belt.Array.concat(pool.fingerprintWaitersRef.contents, [{id, resolve}])
      pool.fingerprintWaitersRef := pool.fingerprintWaitersRef.contents
      ->Belt.Array.map(waiter =>
        if waiter.id == id {
          {
            ...waiter,
            resolve: value => {
              removeOnAbort.contents->Option.forEach(cb => cb())
              finish(value)
            },
          }
        } else {
          waiter
        }
      )
      let worker = takeWorker(pool)
      postMessage(worker, {"id": id, "type": "fingerprint", "file": file})
    })
  }
}

let validateImageWithWorker = (
  file: BrowserBindings.File.t,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
): Promise.t<option<bool>> => {
  switch ensurePool() {
  | None => Promise.resolve(None)
  | Some(pool) =>
    Promise.make((resolve, _reject) => {
      let id = Math.random()->Float.toString ++ "_" ++ Date.now()->Float.toInt->Int.toString
      let settled = ref(false)
      let finish = value => {
        if !settled.contents {
          settled := true
          resolve(value)
        }
      }
      let removeOnAbort = ref(None)
      signal->Option.forEach(sig => {
        let onAbort = () => {
          let _ = removeValidateWaiter(pool, id)
          finish(None)
        }
        BrowserBindings.AbortSignal.addEventListener(sig, "abort", onAbort)
        removeOnAbort := Some(() => BrowserBindings.AbortSignal.removeEventListener(sig, "abort", onAbort))
        if BrowserBindings.AbortSignal.aborted(sig) {
          onAbort()
        }
      })
      pool.validateWaitersRef := Belt.Array.concat(pool.validateWaitersRef.contents, [{id, resolve}])
      pool.validateWaitersRef := pool.validateWaitersRef.contents
      ->Belt.Array.map(waiter =>
        if waiter.id == id {
          {
            ...waiter,
            resolve: value => {
              removeOnAbort.contents->Option.forEach(cb => cb())
              finish(value)
            },
          }
        } else {
          waiter
        }
      )
      let worker = takeWorker(pool)
      postMessage(worker, {"id": id, "type": "validateImage", "file": file})
    })
  }
}

let generateTinyWithWorker = (
  blob: BrowserBindings.Blob.t,
  ~width: int=256,
  ~height: int=144,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
): Promise.t<option<BrowserBindings.Blob.t>> => {
  switch ensurePool() {
  | None => Promise.resolve(None)
  | Some(pool) =>
    Promise.make((resolve, _reject) => {
      let id = Math.random()->Float.toString ++ "_" ++ Date.now()->Float.toInt->Int.toString
      let settled = ref(false)
      let finish = value => {
        if !settled.contents {
          settled := true
          resolve(value)
        }
      }
      let removeOnAbort = ref(None)
      signal->Option.forEach(sig => {
        let onAbort = () => {
          let _ = removeTinyWaiter(pool, id)
          finish(None)
        }
        BrowserBindings.AbortSignal.addEventListener(sig, "abort", onAbort)
        removeOnAbort := Some(() => BrowserBindings.AbortSignal.removeEventListener(sig, "abort", onAbort))
        if BrowserBindings.AbortSignal.aborted(sig) {
          onAbort()
        }
      })
      pool.tinyWaitersRef := Belt.Array.concat(pool.tinyWaitersRef.contents, [{id, resolve}])
      pool.tinyWaitersRef := pool.tinyWaitersRef.contents
      ->Belt.Array.map(waiter =>
        if waiter.id == id {
          {
            ...waiter,
            resolve: value => {
              removeOnAbort.contents->Option.forEach(cb => cb())
              finish(value)
            },
          }
        } else {
          waiter
        }
      )
      let worker = takeWorker(pool)
      postMessage(
        worker,
        {"id": id, "type": "generateTiny", "blob": blob, "width": width, "height": height},
      )
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

let extractExifWithWorker = (
  file: BrowserBindings.File.t,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
): Promise.t<option<(int, int)>> => {
  switch ensurePool() {
  | None => Promise.resolve(None)
  | Some(pool) =>
    Promise.make((resolve, _reject) => {
      let id = Math.random()->Float.toString ++ "_" ++ Date.now()->Float.toInt->Int.toString
      let settled = ref(false)
      let finish = value => {
        if !settled.contents {
          settled := true
          resolve(value)
        }
      }
      let removeOnAbort = ref(None)
      signal->Option.forEach(sig => {
        let onAbort = () => {
          let _ = removeExifWaiter(pool, id)
          finish(None)
        }
        BrowserBindings.AbortSignal.addEventListener(sig, "abort", onAbort)
        removeOnAbort := Some(() => BrowserBindings.AbortSignal.removeEventListener(sig, "abort", onAbort))
        if BrowserBindings.AbortSignal.aborted(sig) {
          onAbort()
        }
      })
      pool.exifWaitersRef := Belt.Array.concat(pool.exifWaitersRef.contents, [{id, resolve}])
      pool.exifWaitersRef := pool.exifWaitersRef.contents
      ->Belt.Array.map(waiter =>
        if waiter.id == id {
          {
            ...waiter,
            resolve: value => {
              removeOnAbort.contents->Option.forEach(cb => cb())
              finish(value)
            },
          }
        } else {
          waiter
        }
      )
      let worker = takeWorker(pool)
      postMessage(worker, {"id": id, "type": "extractExif", "file": file})
    })
  }
}
