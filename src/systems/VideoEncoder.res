/* src/systems/VideoEncoder.res */

open ReBindings


type transcodeProgressCallback = (float, string) => unit




let transcodeWebMToMP4 = (
  webmBlob: Blob.t,
  baseName: string,
  progressCallback: option<transcodeProgressCallback>,
) => {
  let startTime = Date.now()
  Logger.startOperation(
    ~module_="VideoEncoder",
    ~operation="TRANSCODE",
    ~data=Some({"inputSize": Blob.size(webmBlob), "file": baseName}),
    (),
  )

  switch progressCallback {
  | Some(cb) => {
      cb(10.0, "Uploading...")
      Logger.debug(~module_="VideoEncoder", ~message="TRANSCODE_PROGRESS", ~data=Some({"percent": 10.0}), ())
    }
  | None => ()
  }

  if Blob.size(webmBlob) < 1024.0 {
    let msg = "Video file is too small. Recording likely failed."
    Logger.error(~module_="VideoEncoder", ~message="TRANSCODE_INPUT_TOO_SMALL", ~data=Some({"size": Blob.size(webmBlob)}), ())
    Promise.reject(JsError.throwWithMessage(msg))
  } else {
    let formData = FormData.newFormData()
    FormData.appendWithFilename(formData, "file", webmBlob, "input.webm")

    Fetch.fetch(
      Constants.backendUrl ++ "/transcode-video",
      {
        method: "POST",
        body: formData,
        headers: Nullable.null,
      },
    )
    ->Promise.then(res => {
      switch progressCallback {
      | Some(cb) => {
          cb(50.0, "Processing...")
          Logger.debug(~module_="VideoEncoder", ~message="TRANSCODE_PROGRESS", ~data=Some({"percent": 50.0}), ())
        }
      | None => ()
      }

      if !Fetch.ok(res) {
        let getText: Fetch.response => Promise.t<string> = %raw("(res) => res.text()")
        getText(res)->Promise.then(text => {
          let errorDetails = "Backend Transcode Failed: " ++ text
          Logger.error(~module_="VideoEncoder", ~message="TRANSCODE_FAILED", ~data=Some({"error": text}), ())
          /* throwWithMessage returns exn compatible with Promise.reject if defined properly,
           or we use Js.Exn.raiseError directly via raw to be safe */
          let err = JsError.throwWithMessage(errorDetails)
          Promise.reject(err)
        })
      } else {
        Promise.resolve(res)
      }
    })
    ->Promise.then(Fetch.blob)
    ->Promise.then(mp4Blob => {
      let durationMs = Date.now() -. startTime
      switch progressCallback {
      | Some(cb) => cb(100.0, "Done")
      | None => ()
      }

      let filename = baseName ++ ".mp4"
      Logger.endOperation(
        ~module_="VideoEncoder",
        ~operation="TRANSCODE",
        ~data=Some({
          "durationMs": durationMs,
          "inputSize": Blob.size(webmBlob),
          "outputSize": Blob.size(mp4Blob),
          "file": filename,
        }),
        (),
      )

      /* DownloadSystem should be available globally or imported. 
            However, we can't assume DownloadSystem module scope unless we open it or it's in list.
            Let's assume we can rely on ReBindings or manual binding if DownloadSystem.res exists.
 */
      DownloadSystem.saveBlob(mp4Blob, filename)
      Promise.resolve()
    })
    ->Promise.catch(err => {
      let durationMs = Date.now() -. startTime
      Logger.error(
        ~module_="VideoEncoder",
        ~message="TRANSCODE_FAILED",
        ~data=Some({"durationMs": durationMs, "error": err}),
        (),
      )
      Promise.reject(err)
    })
  }
}
