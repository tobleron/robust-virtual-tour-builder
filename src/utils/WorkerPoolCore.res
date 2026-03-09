/* src/utils/WorkerPoolCore.res */

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

let removeFullWaiter = (
  pool: state,
  id: string,
): option<waiter<result<(BrowserBindings.Blob.t, int, int), string>>> =>
  removeWaiter(pool.fullWaitersRef, id)

let resolveOptionalWaiter = (
  waiterOpt: option<waiter<option<'a>>>,
  isOk: bool,
  value: option<'a>,
) => {
  switch waiterOpt {
  | Some(waiter) => waiter.resolve(if isOk { value } else { None })
  | None => ()
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
      resolveOptionalWaiter(removeTinyWaiter(pool, tinyPayload.id), tinyPayload.ok, tinyPayload.tiny)
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
  setOnError(worker, _err => ())
}
