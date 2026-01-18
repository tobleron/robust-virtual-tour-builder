/* src/utils/ImageOptimizer.res */
open ReBindings

let moduleName = "ImageOptimizer"

let init = () => {
  Logger.initialized(~module_=moduleName)
}

/**
 * Compresses a File/Blob to WebP format using the browser's Canvas API.
 * This saves bandwidth by sending optimized images to the backend.
 */
let compressToWebP = (file: File.t, quality: float): Promise.t<Blob.t> => {
  Logger.startOperation(~module_=moduleName, ~operation="COMPRESS_WEBP", ())
  let startTime = Date.now()

  Promise.make((resolve, reject) => {
    let img = Dom.createElement("img")
    let url = UrlUtils.safeCreateObjectURL(file)
    if url == "" {
      reject(JsError.throwWithMessage("Failed to create object URL"))
    }

    let onLoad = () => {
      URL.revokeObjectURL(url)
      let maxWidth = 4096.0
      let srcW = Float.fromInt(Dom.getWidth(img))
      let srcH = Float.fromInt(Dom.getHeight(img))

      let (width, height) = if srcW > maxWidth {
        let ratio = maxWidth /. srcW
        (maxWidth, srcH *. ratio)
      } else {
        (srcW, srcH)
      }

      let canvas = Dom.createElement("canvas")
      Dom.setWidth(canvas, Float.toInt(width))
      Dom.setHeight(canvas, Float.toInt(height))

      let ctx = Canvas.getContext2d(canvas, "2d", %raw("{}"))
      // Using imageSmoothingQuality for better results
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
            Logger.endOperation(
              ~module_=moduleName,
              ~operation="COMPRESS_WEBP",
              ~data=Some({
                "originalSize": File.size(file),
                "newSize": Blob.size(b),
                "durationMs": duration,
                "reduction": Float.toFixed(
                  100.0 *. (1.0 -. Blob.size(b) /. File.size(file)),
                  ~digits=1,
                ) ++ "%",
              }),
              (),
            )
            resolve(b)
          | None =>
            let error = "WebP compression failed (null blob)"
            Logger.error(
              ~module_=moduleName,
              ~message="COMPRESSION_FAILED",
              ~data=Some({"error": error}),
              (),
            )
            reject(JsError.throwWithMessage(error))
          }
        },
        "image/webp",
        quality,
      )
    }

    let onError = () => {
      URL.revokeObjectURL(url)
      let error = "Failed to load image for compression"
      Logger.error(
        ~module_=moduleName,
        ~message="IMAGE_LOAD_FAILED",
        ~data=Some({"error": error}),
        (),
      )
      reject(JsError.throwWithMessage(error))
    }

    Dom.addEventListenerNoEv(img, "load", onLoad)
    Dom.addEventListenerNoEv(img, "error", onError)
    Dom.setAttribute(img, "src", url)
  })
}
