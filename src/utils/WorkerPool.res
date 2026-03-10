/* src/utils/WorkerPool.res */

type worker = WorkerPoolCore.worker
type waiter<'a> = WorkerPoolCore.waiter<'a> = {
  id: string,
  resolve: 'a => unit,
}
type state = WorkerPoolCore.state = {
  workers: array<worker>,
  readyRef: ref<bool>,
  nextWorkerIdxRef: ref<int>,
  fingerprintWaitersRef: ref<array<waiter<option<string>>>>,
  validateWaitersRef: ref<array<waiter<option<bool>>>>,
  tinyWaitersRef: ref<array<waiter<option<BrowserBindings.Blob.t>>>>,
  exifWaitersRef: ref<array<waiter<option<(int, int)>>>>,
  fullWaitersRef: ref<array<waiter<result<(BrowserBindings.Blob.t, int, int), string>>>>,
}

let poolRef: ref<option<state>> = ref(None)

let createPoolSize = (): int => {
  WorkerPoolCore.createPoolSize()
}

let takeWorker = (pool: state): worker => {
  WorkerPoolCore.takeWorker(pool)
}

let removeFingerprintWaiter = (pool: state, id: string): option<waiter<option<string>>> =>
  WorkerPoolCore.removeFingerprintWaiter(pool, id)

let removeValidateWaiter = (pool: state, id: string): option<waiter<option<bool>>> =>
  WorkerPoolCore.removeValidateWaiter(pool, id)

let removeTinyWaiter = (pool: state, id: string): option<waiter<option<BrowserBindings.Blob.t>>> =>
  WorkerPoolCore.removeTinyWaiter(pool, id)

let removeExifWaiter = (pool: state, id: string): option<waiter<option<(int, int)>>> =>
  WorkerPoolCore.removeExifWaiter(pool, id)

let removeFullWaiter = (
  pool: state,
  id: string,
): option<waiter<result<(BrowserBindings.Blob.t, int, int), string>>> =>
  WorkerPoolCore.removeFullWaiter(pool, id)

let bindWorkerHandlers = (pool: state, worker: worker) => {
  WorkerPoolCore.bindWorkerHandlers(pool, worker)
}

let ensurePool = (): option<state> => {
  switch poolRef.contents {
  | Some(pool) if pool.readyRef.contents => Some(pool)
  | _ =>
    try {
      let size = createPoolSize()
      let workers = Belt.Array.makeBy(size, _ => WorkerPoolCore.makeWorker("/workers/image-worker.js"))
      let pool = {
        workers,
        readyRef: ref(true),
        nextWorkerIdxRef: ref(0),
        fingerprintWaitersRef: ref([]),
        validateWaitersRef: ref([]),
        tinyWaitersRef: ref([]),
        exifWaitersRef: ref([]),
        fullWaitersRef: ref([]),
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

let processFullWithWorker = (
  blob: BrowserBindings.Blob.t,
  ~width: int=4096,
  ~quality: float=0.92,
  ~format: string="image/webp",
  ~preserveAlpha: bool=false,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
): Promise.t<result<(BrowserBindings.Blob.t, int, int), string>> => {
  switch ensurePool() {
  | None => Promise.resolve(Error("Worker pool not available"))
  | Some(pool) =>
    WorkerPoolRequests.runRequest(
      pool,
      ~signal?,
      ~waitersRef=pool.fullWaitersRef,
      ~removeWaiter=removeFullWaiter,
      ~abortValue=Error("Processing cancelled by user"),
      ~send=(worker, id) =>
        WorkerPoolCore.postMessage(
          worker,
          {
            "id": id,
            "type": "processFull",
            "blob": blob,
            "width": width,
            "quality": quality,
            "format": format,
            "preserveAlpha": preserveAlpha,
          },
        ),
    )
  }
}

let fingerprintWithWorker = (
  file: BrowserBindings.File.t,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
): Promise.t<option<string>> => {
  switch ensurePool() {
  | None => Promise.resolve(None)
  | Some(pool) =>
    WorkerPoolRequests.runRequest(
      pool,
      ~signal?,
      ~waitersRef=pool.fingerprintWaitersRef,
      ~removeWaiter=removeFingerprintWaiter,
      ~abortValue=None,
      ~send=(worker, id) => WorkerPoolCore.postMessage(worker, {"id": id, "type": "fingerprint", "file": file}),
    )
  }
}

let validateImageWithWorker = (
  file: BrowserBindings.File.t,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
): Promise.t<option<bool>> => {
  switch ensurePool() {
  | None => Promise.resolve(None)
  | Some(pool) =>
    WorkerPoolRequests.runRequest(
      pool,
      ~signal?,
      ~waitersRef=pool.validateWaitersRef,
      ~removeWaiter=removeValidateWaiter,
      ~abortValue=None,
      ~send=(worker, id) =>
        WorkerPoolCore.postMessage(worker, {"id": id, "type": "validateImage", "file": file}),
    )
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
    WorkerPoolRequests.runRequest(
      pool,
      ~signal?,
      ~waitersRef=pool.tinyWaitersRef,
      ~removeWaiter=removeTinyWaiter,
      ~abortValue=None,
      ~send=(worker, id) =>
        WorkerPoolCore.postMessage(
          worker,
          {"id": id, "type": "generateTiny", "blob": blob, "width": width, "height": height},
        ),
    )
  }
}

let shutdown = () => {
  switch poolRef.contents {
  | Some(pool) =>
    pool.workers->Belt.Array.forEach(w => WorkerPoolCore.terminate(w, ()))
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
    WorkerPoolRequests.runRequest(
      pool,
      ~signal?,
      ~waitersRef=pool.exifWaitersRef,
      ~removeWaiter=removeExifWaiter,
      ~abortValue=None,
      ~send=(worker, id) => WorkerPoolCore.postMessage(worker, {"id": id, "type": "extractExif", "file": file}),
    )
  }
}
