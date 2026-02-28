/* src/core/SceneCache.res */
open ReBindings

type t = LruCache.t<string>

let snapshotMax = 50
let sourceMax = 30
let thumbMax = 100

let revokeIfBlobUrl = (url: string) => {
  if String.startsWith(url, "blob:") {
    URL.revokeObjectURL(url)
  }
}

/* Map of sceneId -> blobUrl for pre-calculated snapshots */
let cache: t = LruCache.make(~maxEntries=snapshotMax, ~onEvict=(_, url) => revokeIfBlobUrl(url))

/* Map of sceneId -> blobUrl for source files */
let sourceUrls: t = LruCache.make(~maxEntries=sourceMax, ~onEvict=(_, url) => revokeIfBlobUrl(url))

/* Map of sceneId -> blobUrl for thumbnails */
let thumbUrls: t = LruCache.make(~maxEntries=thumbMax, ~onEvict=(_, url) => revokeIfBlobUrl(url))

@val
external measureUserAgentSpecificMemory: unit => Promise.t<{..}> =
  "performance.measureUserAgentSpecificMemory"
let memoryPollTimer: ref<option<int>> = ref(None)
let memoryHighWatermarkBytes = 500.0 *. 1024.0 *. 1024.0

@get external bytesOrUndefined: {..} => option<float> = "bytes"

let getBytesUsed = (memObj: {..}): option<float> => bytesOrUndefined(memObj)

let applyMemoryPressure = () => {
  // Aggressive shrink profile used by StateDensityMonitor high mode and memory pressure.
  LruCache.shrinkTo(sourceUrls, 10)
  LruCache.shrinkTo(thumbUrls, 30)
  LruCache.shrinkTo(cache, 20)
}

let getSnapshot = (sceneId: string) => {
  LruCache.get(cache, sceneId)
}

let setSnapshot = (sceneId: string, url: string) => {
  /* Revoke existing if we overwrite to prevent memory leaks */
  switch LruCache.get(cache, sceneId) {
  | Some(oldUrl) if oldUrl != url => URL.revokeObjectURL(oldUrl)
  | _ => ()
  }
  LruCache.set(cache, sceneId, url)
}

let getSourceUrl = (sceneId: string, file: Types.file) => {
  switch LruCache.get(sourceUrls, sceneId) {
  | Some(url) if url != "" => url
  | Some(_) =>
    LruCache.remove(sourceUrls, sceneId)
    let url = UrlUtils.fileToUrl(file)
    if url != "" {
      LruCache.set(sourceUrls, sceneId, url)
    }
    url
  | None =>
    let url = UrlUtils.fileToUrl(file)
    if url != "" {
      LruCache.set(sourceUrls, sceneId, url)
    }
    url
  }
}

let getThumbUrl = (sceneId: string, file: Types.file) => {
  switch LruCache.get(thumbUrls, sceneId) {
  | Some(url) => url
  | None =>
    let url = UrlUtils.fileToUrl(file)
    LruCache.set(thumbUrls, sceneId, url)
    url
  }
}

let clearThumbUrl = (sceneId: string) => {
  switch LruCache.get(thumbUrls, sceneId) {
  | Some(url) => URL.revokeObjectURL(url)
  | None => ()
  }
  LruCache.remove(thumbUrls, sceneId)
}

let removeKeyOnly = (sceneId: string) => {
  // Key-only removal used by undo flows; do not revoke object URL here.
  switch LruCache.get(cache, sceneId) {
  | Some(_) =>
    Belt.MutableMap.String.remove(cache.map, sceneId)
    cache.orderRef := cache.orderRef.contents->Belt.Array.keep(k => k != sceneId)
  | None => ()
  }
}

let clearSnapshot = (sceneId: string) => {
  switch LruCache.get(cache, sceneId) {
  | Some(oldUrl) => URL.revokeObjectURL(oldUrl)
  | None => ()
  }
  LruCache.remove(cache, sceneId)
}

let clearAll = () => {
  LruCache.clear(cache)
  LruCache.clear(sourceUrls)
  LruCache.clear(thumbUrls)
}

let startMemoryMonitoring = () => {
  switch memoryPollTimer.contents {
  | Some(_) => ()
  | None => memoryPollTimer := Some(Window.setInterval(() => {
          try {
            let _ =
              measureUserAgentSpecificMemory()
              ->Promise.then(memObj => {
                let bytesUsed = getBytesUsed(memObj)->Option.getOr(0.0)
                if bytesUsed > memoryHighWatermarkBytes {
                  applyMemoryPressure()
                }
                Promise.resolve()
              })
              ->Promise.catch(_ => Promise.resolve())
          } catch {
          | _ => ()
          }
        }, 10000))
  }
}

let stopMemoryMonitoring = () => {
  switch memoryPollTimer.contents {
  | Some(timerId) =>
    Window.clearInterval(timerId)
    memoryPollTimer := None
  | None => ()
  }
}

let _ = startMemoryMonitoring()
