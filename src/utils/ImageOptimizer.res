/* src/utils/ImageOptimizer.res */
open ReBindings

let moduleName = "ImageOptimizer"

let init = () => {
  Logger.initialized(~module_=moduleName)
}

/**
 * Compresses a File/Blob to WebP format using WorkerPool's OffscreenCanvas implementation.
 * This offloads heavy computation (resizing + encoding) to background threads.
 */
/**
 * Fallback: Compresses a File/Blob using the main-thread Canvas API.
 * Used when OffscreenCanvas or WorkerPool is unavailable.
 */
let compressMainThread = (
  file: File.t,
  ~quality: float,
  ~maxWidth: float,
  ~maxHeight as _: float,
): Promise.t<result<Blob.t, string>> => {
  let startTime = Date.now()
  Promise.make((resolve, _reject) => {
    let img = Dom.createElement("img")
    let url = UrlUtils.safeCreateObjectURL(file)
    if url == "" {
      resolve(Error("Failed to create object URL for fallback"))
    } else {
      let onLoad = () => {
        URL.revokeObjectURL(url)
        let srcW = Float.fromInt(Dom.getWidth(img))
        let srcH = Float.fromInt(Dom.getHeight(img))
        if srcW <= 0.0 || srcH <= 0.0 {
          resolve(Error("Invalid source dimensions in fallback"))
        } else {
          let scale = Math.min(1.0, maxWidth /. srcW)
          let width = srcW *. scale
          let height = srcH *. scale

          let canvas = Dom.createElement("canvas")
          Dom.setWidth(canvas, Float.toInt(width))
          Dom.setHeight(canvas, Float.toInt(height))

          let ctx = Canvas.getContext2d(canvas, "2d", %raw("{}"))
          let _ = %raw("ctx.imageSmoothingQuality = 'high'")
          Canvas.drawImage(ctx, img, 0.0, 0.0, width, height)

          let toBlob: (Dom.element, Nullable.t<Blob.t> => unit, string, float) => unit = %raw(
            "(el, cb, type, q) => el.toBlob(cb, type, q)"
          )

          toBlob(
            canvas,
            blob => {
              switch Nullable.toOption(blob) {
              | Some(b) =>
                let duration = Date.now() -. startTime
                Logger.info(
                  ~module_=moduleName,
                  ~message="COMPRESS_IMAGE_FALLBACK_SUCCESS",
                  ~data=Some({
                    "originalSize": File.size(file),
                    "newSize": Blob.size(b),
                    "durationMs": duration,
                    "engine": "main-thread-canvas",
                  }),
                  (),
                )
                resolve(Ok(b))
              | None => resolve(Error("Fallback compression failed (null blob)"))
              }
            },
            Constants.Media.uploadFormat,
            quality,
          )
        }
      }

      let onError = () => {
        URL.revokeObjectURL(url)
        resolve(Error("Failed to load image for fallback compression"))
      }

      Dom.addEventListenerNoEv(img, "load", onLoad)
      Dom.addEventListenerNoEv(img, "error", onError)
      Dom.setAttribute(img, "src", url)
    }
  })
}

/**
 * Compresses a File/Blob to WebP/JPEG format using WorkerPool's OffscreenCanvas implementation.
 * Automatically falls back to main-thread Canvas if background processing is unsupported.
 */
let compressToWebPConstrained = (
  file: File.t,
  ~quality: float,
  ~maxWidth: float,
  ~maxHeight: float,
): Promise.t<result<Blob.t, string>> => {
  Logger.startOperation(~module_=moduleName, ~operation="COMPRESS_IMAGE_WORKER", ())
  let startTime = Date.now()

  // Detection: Check for OffscreenCanvas support
  let isOffscreenSupported: bool = %raw(`typeof OffscreenCanvas !== 'undefined'`)

  if !isOffscreenSupported {
    Logger.warn(~module_=moduleName, ~message="OFFSCREEN_CANVAS_UNSUPPORTED_FALLBACK", ())
    compressMainThread(file, ~quality, ~maxWidth, ~maxHeight)
  } else {
    WorkerPool.processFullWithWorker(
      %raw("(f) => f")(file),
      ~width=Float.toInt(maxWidth),
      ~quality,
      ~format=Constants.Media.uploadFormat,
    )->Promise.then(res => {
      let duration = Date.now() -. startTime
      switch res {
      | Ok((blob, w, h)) =>
        Logger.endOperation(
          ~module_=moduleName,
          ~operation="COMPRESS_IMAGE_WORKER",
          ~data=Some({
            "originalSize": File.size(file),
            "newSize": Blob.size(blob),
            "durationMs": duration,
            "reduction": Float.toFixed(
              100.0 *. (1.0 -. Blob.size(blob) /. File.size(file)),
              ~digits=1,
            ) ++ "%",
            "engine": "offscreen-canvas-worker",
            "format": Constants.Media.uploadFormat,
            "dimensions": Belt.Int.toString(w) ++ "x" ++ Belt.Int.toString(h),
          }),
          (),
        )
        Promise.resolve(Ok(blob))
      | Error(msg) =>
        if String.includes(msg, "unsupported") || String.includes(msg, "not available") {
          Logger.warn(
            ~module_=moduleName,
            ~message="WORKER_UNSUPPORTED_FALLBACK",
            ~data=Some({"reason": msg}),
            (),
          )
          compressMainThread(file, ~quality, ~maxWidth, ~maxHeight)
        } else {
          Logger.error(
            ~module_=moduleName,
            ~message="WORKER_COMPRESSION_FAILED",
            ~data=Some({"error": msg}),
            (),
          )
          Promise.resolve(Error(msg))
        }
      }
    })
  }
}

let compressToWebP = (file: File.t, quality: float): Promise.t<result<Blob.t, string>> =>
  compressToWebPConstrained(
    file,
    ~quality,
    ~maxWidth=Float.fromInt(Constants.processedImageWidth),
    ~maxHeight=Float.fromInt(Constants.processedImageWidth),
  )
