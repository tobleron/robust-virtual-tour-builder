/* src/utils/ThumbnailGenerator.res */
open ReBindings

let degToRad = Math.Constants.pi /. 180.0

/**
 * Generates a rectilinear thumbnail from an equirectangular source.
 * hfov defaults to 90.0 as requested.
 * centered at yaw=0, pitch=0 (level scene plane center).
 */
let generateRectilinearThumbnail = (
  source: Dom.element, // HTMLImageElement or HTMLCanvasElement
  width: int,
  height: int,
  ~hfov: float=90.0,
): Promise.t<Blob.t> => {
  Promise.make((resolve, _reject) => {
    let canvas = Dom.createElement("canvas")
    Dom.setWidth(canvas, width)
    Dom.setHeight(canvas, height)
    let ctx = Canvas.getContext2d(canvas, "2d", {"alpha": false})

    let srcW = Float.fromInt(Dom.getWidth(source))
    let srcH = Float.fromInt(Dom.getHeight(source))

    if srcW == 0.0 || srcH == 0.0 {
      // Fallback: just draw it scaled if source size is unknown
      Canvas.drawImage(ctx, source, 0.0, 0.0, Float.fromInt(width), Float.fromInt(height))
    } else {
      let imageData = ctx->Canvas.createImageData(width, height)
      let _data = %raw("imageData.data")

      // Optimization: Load source data into a temporary canvas to get pixel access
      let srcCanvas = Dom.createElement("canvas")
      Dom.setWidth(srcCanvas, Float.toInt(srcW))
      Dom.setHeight(srcCanvas, Float.toInt(srcH))
      let srcCtx = Canvas.getContext2d(srcCanvas, "2d", {"alpha": false})
      Canvas.drawImage(srcCtx, source, 0.0, 0.0, srcW, srcH)
      let _srcImageData = srcCtx->Canvas.getImageData(0.0, 0.0, srcW, srcH)
      let _srcPixelsCursor = %raw("_srcImageData.data")

      let hfovRad = hfov *. degToRad
      let halfTanHfov = Math.tan(hfovRad /. 2.0)
      let aspectRatio = Float.fromInt(width) /. Float.fromInt(height)
      let halfTanVfov = halfTanHfov /. aspectRatio

      for y in 0 to height - 1 {
        for x in 0 to width - 1 {
          // 1. Normalized Device Coordinates [-1, 1]
          let u = Float.fromInt(x) /. Float.fromInt(width) *. 2.0 -. 1.0
          let v = 1.0 -. Float.fromInt(y) /. Float.fromInt(height) *. 2.0

          // 2. Rectilinear -> Spherical (theta, phi)
          let theta = Math.atan(u *. halfTanHfov)
          let phi = Math.atan(v *. halfTanVfov *. Math.cos(theta))

          // 3. Spherical -> Equirectangular (Longitude, Latitude normalized)
          // Longitude theta is in range [-pi, pi], 0 is center.
          // Latitude phi is in range [-pi/2, pi/2], 0 is center.
          let lon = theta /. (2.0 *. Math.Constants.pi) +. 0.5
          let lat = 0.5 -. phi /. Math.Constants.pi

          // 4. Map to source pixel coordinates
          let sx = Float.toInt(lon *. srcW)
          let sy = Float.toInt(lat *. srcH)

          // 5. Clamp
          let sx = Math.Int.max(0, Math.Int.min(Float.toInt(srcW) - 1, sx))
          let sy = Math.Int.max(0, Math.Int.min(Float.toInt(srcH) - 1, sy))

          let _destIdx = (y * width + x) * 4
          let _srcIdx = (sy * Float.toInt(srcW) + sx) * 4

          let _ = %raw(`
            (_data[_destIdx] = _srcPixelsCursor[_srcIdx],
             _data[_destIdx + 1] = _srcPixelsCursor[_srcIdx + 1],
             _data[_destIdx + 2] = _srcPixelsCursor[_srcIdx + 2],
             _data[_destIdx + 3] = 255)
          `)
        }
      }
      ctx->Canvas.putImageData(imageData, 0.0, 0.0)
    }

    let toBlob: (Dom.element, Nullable.t<Blob.t> => unit, string, float) => unit = %raw(
      "(el, cb, type, q) => el.toBlob(cb, type, q)"
    )

    toBlob(
      canvas,
      blob => {
        switch Nullable.toOption(blob) {
        | Some(b) => resolve(b)
        | None =>
          // Last resort fallback: should not happen
          resolve(%raw("new Blob([])"))
        }
      },
      "image/webp",
      0.85,
    )
  })
}
