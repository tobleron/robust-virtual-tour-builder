/* src/utils/WorkerPoolCore.res */

type worker
type workerMessageEvent
type workerErrorEvent
type workerMessageErrorEvent

@new external makeWorker: string => worker = "Worker"
@send external postMessage: (worker, 'a) => unit = "postMessage"
@send external terminate: (worker, unit) => unit = "terminate"
@set external setOnMessage: (worker, workerMessageEvent => unit) => unit = "onmessage"
@set external setOnError: (worker, workerErrorEvent => unit) => unit = "onerror"
@set
external setOnMessageError: (worker, workerMessageErrorEvent => unit) => unit = "onmessageerror"
@get external getEventData: workerMessageEvent => 'a = "data"
@get external getErrorMessage: workerErrorEvent => string = "message"
@get external getErrorFilename: workerErrorEvent => string = "filename"
@get external getErrorLineno: workerErrorEvent => int = "lineno"
@get external getErrorColno: workerErrorEvent => int = "colno"

@send external preventDefaultError: workerErrorEvent => unit = "preventDefault"
@send external preventDefaultMessageError: workerMessageErrorEvent => unit = "preventDefault"
@send external stopPropagationError: workerErrorEvent => unit = "stopPropagation"
@send external stopPropagationMessageError: workerMessageErrorEvent => unit = "stopPropagation"

type fingerprintResponse = {id: string, ok: bool, checksum: option<string>}
type validateImageResponse = {id: string, ok: bool, isImage: option<bool>}
type generateTinyResponse = {id: string, ok: bool, tiny: option<BrowserBindings.Blob.t>}
type exifResponse = {id: string, ok: bool, width: option<int>, height: option<int>}
type processFullResponse = {
  id: string,
  ok: bool,
  blob: option<BrowserBindings.Blob.t>,
  width: option<int>,
  height: option<int>,
  error: option<string>,
}

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
  fullWaitersRef: ref<array<waiter<result<(BrowserBindings.Blob.t, int, int), string>>>>,
}

@scope("navigator") @val @return(nullable)
external hardwareConcurrencyOpt: option<int> = "hardwareConcurrency"
@scope("navigator") @val @return(nullable) external deviceMemoryOpt: option<float> = "deviceMemory"

let createPoolSize = (): int => {
  let cores = hardwareConcurrencyOpt->Option.getOr(2)
  let ramGb = deviceMemoryOpt->Option.getOr(8.0)
  let memoryCap = if ramGb <= 4.0 {
    2
  } else if ramGb <= 8.0 {
    4
  } else {
    8
  }
  let proposed = cores - 1
  let size = Math.min(Int.toFloat(proposed), Int.toFloat(memoryCap))
  if size < 1.0 {
    1
  } else {
    Float.toInt(size)
  }
}

let takeWorker = (pool: state): worker => {
  let idx = pool.nextWorkerIdxRef.contents
  let worker = pool.workers->Belt.Array.getExn(idx)
  let nextIdx = idx + 1
  pool.nextWorkerIdxRef := if nextIdx >= Belt.Array.length(pool.workers) {
      0
    } else {
      nextIdx
    }
  worker
}

let removeWaiter = (waitersRef: ref<array<waiter<'a>>>, id: string): option<waiter<'a>> => {
  let found = ref(None)
  waitersRef :=
    waitersRef.contents->Belt.Array.keep(waiter => {
      if waiter.id == id {
        found := Some(waiter)
        false
      } else {
        true
      }
    })
  found.contents
}

let removeFingerprintWaiter = (pool: state, id: string): option<waiter<option<string>>> =>
  removeWaiter(pool.fingerprintWaitersRef, id)

let removeValidateWaiter = (pool: state, id: string): option<waiter<option<bool>>> =>
  removeWaiter(pool.validateWaitersRef, id)

let removeTinyWaiter = (pool: state, id: string): option<waiter<option<BrowserBindings.Blob.t>>> =>
  removeWaiter(pool.tinyWaitersRef, id)

let removeExifWaiter = (pool: state, id: string): option<waiter<option<(int, int)>>> =>
  removeWaiter(pool.exifWaitersRef, id)

let removeFullWaiter = (pool: state, id: string): option<
  waiter<result<(BrowserBindings.Blob.t, int, int), string>>,
> => removeWaiter(pool.fullWaitersRef, id)

let resolveOptionalWaiter = (
  waiterOpt: option<waiter<option<'a>>>,
  isOk: bool,
  value: option<'a>,
) => {
  switch waiterOpt {
  | Some(waiter) =>
    waiter.resolve(
      if isOk {
        value
      } else {
        None
      },
    )
  | None => ()
  }
}

let resolveAllWaiters = (waitersRef: ref<array<waiter<'a>>>, value: 'a) => {
  let waiters = waitersRef.contents
  waitersRef := []
  waiters->Belt.Array.forEach(waiter => waiter.resolve(value))
}

let invalidatePool = (pool: state, ~reason: string) => {
  if pool.readyRef.contents {
    pool.readyRef := false
    Logger.warn(
      ~module_="WorkerPool",
      ~message="WORKER_POOL_INVALIDATED",
      ~data=Some({"reason": reason}),
      (),
    )
    resolveAllWaiters(pool.fingerprintWaitersRef, None)
    resolveAllWaiters(pool.validateWaitersRef, None)
    resolveAllWaiters(pool.tinyWaitersRef, None)
    resolveAllWaiters(pool.exifWaitersRef, None)
    resolveAllWaiters(pool.fullWaitersRef, Error(reason))
    pool.workers->Belt.Array.forEach(worker => {
      try {
        terminate(worker, ())
      } catch {
      | _ => ()
      }
    })
  }
}

let describeWorkerError = (evt: workerErrorEvent): string => {
  let message = getErrorMessage(evt)
  let filename = getErrorFilename(evt)
  let lineno = getErrorLineno(evt)
  let colno = getErrorColno(evt)
  let parts = []
  if message != "" {
    ignore(Array.push(parts, "message=" ++ message))
  }
  if filename != "" {
    ignore(Array.push(parts, "file=" ++ filename))
  }
  if lineno > 0 {
    ignore(Array.push(parts, "line=" ++ Belt.Int.toString(lineno)))
  }
  if colno > 0 {
    ignore(Array.push(parts, "col=" ++ Belt.Int.toString(colno)))
  }
  if Belt.Array.length(parts) == 0 {
    "unknown"
  } else {
    let first = Belt.Array.getExn(parts, 0)
    Belt.Array.slice(parts, ~offset=1, ~len=Belt.Array.length(parts) - 1)->Belt.Array.reduce(
      first,
      (acc, part) => acc ++ ", " ++ part,
    )
  }
}

let bindWorkerHandlers = (pool: state, worker: worker) => {
  setOnMessage(worker, evt => {
    let payload: {"id": string, "type": option<string>} = getEventData(evt)
    switch payload["type"] {
    | Some("validateImage") =>
      let validatePayload: validateImageResponse = getEventData(evt)
      resolveOptionalWaiter(
        removeValidateWaiter(pool, validatePayload.id),
        validatePayload.ok,
        validatePayload.isImage,
      )
    | Some("generateTiny") =>
      let tinyPayload: generateTinyResponse = getEventData(evt)
      resolveOptionalWaiter(
        removeTinyWaiter(pool, tinyPayload.id),
        tinyPayload.ok,
        tinyPayload.tiny,
      )
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
    | Some("processFull") =>
      let fullPayload: processFullResponse = getEventData(evt)
      switch removeFullWaiter(pool, fullPayload.id) {
      | Some(waiter) =>
        if fullPayload.ok {
          switch (fullPayload.blob, fullPayload.width, fullPayload.height) {
          | (Some(b), Some(w), Some(h)) => waiter.resolve(Ok((b, w, h)))
          | _ => waiter.resolve(Error("Malformed worker response for processFull"))
          }
        } else {
          waiter.resolve(Error(fullPayload.error->Option.getOr("Unknown worker processing error")))
        }
      | None => ()
      }
    | Some("fingerprint") =>
      let fingerprintPayload: fingerprintResponse = getEventData(evt)
      resolveOptionalWaiter(
        removeFingerprintWaiter(pool, fingerprintPayload.id),
        fingerprintPayload.ok,
        fingerprintPayload.checksum,
      )
    | _ => ()
    }
  })
  setOnError(worker, err => {
    preventDefaultError(err)
    stopPropagationError(err)
    invalidatePool(pool, ~reason="Worker error: " ++ describeWorkerError(err))
  })
  setOnMessageError(worker, err => {
    preventDefaultMessageError(err)
    stopPropagationMessageError(err)
    invalidatePool(pool, ~reason="Worker message deserialization failed")
  })
}
