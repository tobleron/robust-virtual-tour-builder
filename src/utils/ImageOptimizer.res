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
let compressToWebPConstrained = (
  file: File.t,
  ~quality: float,
  ~maxWidth: float,
  ~maxHeight as _: float,
): Promise.t<result<Blob.t, string>> => {
  Logger.startOperation(~module_=moduleName, ~operation="COMPRESS_IMAGE_WORKER", ())
  let startTime = Date.now()

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
      Logger.error(
        ~module_=moduleName,
        ~message="WORKER_COMPRESSION_FAILED",
        ~data=Some({"error": msg}),
        (),
      )
      Promise.resolve(Error(msg))
    }
  })
}

let compressToWebP = (file: File.t, quality: float): Promise.t<result<Blob.t, string>> =>
  compressToWebPConstrained(
    file,
    ~quality,
    ~maxWidth=Float.fromInt(Constants.processedImageWidth),
    ~maxHeight=Float.fromInt(Constants.processedImageWidth),
  )
