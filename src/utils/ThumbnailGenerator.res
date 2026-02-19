/* src/utils/ThumbnailGenerator.res */
open ReBindings

/**
 * Generates a rectilinear thumbnail from an equirectangular source.
 * hfov defaults to 90.0 (degrees).
 * Centered at yaw=0, pitch=0 (level scene plane center).
 *
 * The heavy pixel work is done entirely in a single %raw JS function
 * to avoid ReScript variable-name mangling issues with %raw inline blocks.
 */
let _doProjection: (Dom.element, Dom.element, int, int, float) => unit = %raw(`
  function(source, canvas, width, height, hfov) {
    var ctx = canvas.getContext("2d", { alpha: false });

    // Use naturalWidth for <img>, fall back to .width for <canvas>
    var srcW = source.naturalWidth || source.width || 0;
    var srcH = source.naturalHeight || source.height || 0;

    if (srcW === 0 || srcH === 0) {
      ctx.drawImage(source, 0, 0, width, height);
      return;
    }

    // Cap source resolution to 1024px wide for performance
    var maxSrc = 1024;
    var sW = srcW, sH = srcH;
    if (sW > maxSrc) {
      sH = Math.round(sH * maxSrc / sW);
      sW = maxSrc;
    }

    // Draw source into an intermediate canvas at capped resolution
    var srcCanvas = document.createElement("canvas");
    srcCanvas.width = sW;
    srcCanvas.height = sH;
    var srcCtx = srcCanvas.getContext("2d", { alpha: false });
    srcCtx.drawImage(source, 0, 0, sW, sH);
    var srcPixels = srcCtx.getImageData(0, 0, sW, sH).data;

    // Prepare output
    var imageData = ctx.createImageData(width, height);
    var data = imageData.data;

    var PI = Math.PI;
    var hfovRad = hfov * PI / 180.0;
    var halfTanH = Math.tan(hfovRad / 2.0);
    var aspect = width / height;
    var halfTanV = halfTanH / aspect;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var u = (x / width) * 2.0 - 1.0;
        var v = 1.0 - (y / height) * 2.0;

        var theta = Math.atan(u * halfTanH);
        var phi = Math.atan(v * halfTanV * Math.cos(theta));

        var lon = theta / (2.0 * PI) + 0.5;
        var lat = 0.5 - phi / PI;

        var sx = (lon * sW) | 0;
        var sy = (lat * sH) | 0;

        // Clamp
        if (sx < 0) sx = 0;
        if (sx >= sW) sx = sW - 1;
        if (sy < 0) sy = 0;
        if (sy >= sH) sy = sH - 1;

        var di = (y * width + x) * 4;
        var si = (sy * sW + sx) * 4;

        data[di]     = srcPixels[si];
        data[di + 1] = srcPixels[si + 1];
        data[di + 2] = srcPixels[si + 2];
        data[di + 3] = 255;
      }
    }

    ctx.putImageData(imageData, 0, 0);
  }
`)

let generateRectilinearThumbnail = (
  source: Dom.element,
  width: int,
  height: int,
  ~hfov: float=90.0,
): Promise.t<Blob.t> => {
  Promise.make((resolve, _reject) => {
    let canvas = Dom.createElement("canvas")
    Dom.setWidth(canvas, width)
    Dom.setHeight(canvas, height)

    _doProjection(source, canvas, width, height, hfov)

    let toBlob: (Dom.element, Nullable.t<Blob.t> => unit, string, float) => unit = %raw(
      "(el, cb, type, q) => el.toBlob(cb, type, q)"
    )

    toBlob(
      canvas,
      blob => {
        switch Nullable.toOption(blob) {
        | Some(b) => resolve(b)
        | None => resolve(%raw("new Blob([])"))
        }
      },
      "image/webp",
      0.85,
    )
  })
}
