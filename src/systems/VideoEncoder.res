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
      Logger.debug(
        ~module_="VideoEncoder",
        ~message="TRANSCODE_PROGRESS",
        ~data=Some({"percent": 10.0}),
        (),
      )
    }
  | None => ()
  }

  if Blob.size(webmBlob) < 1024.0 {
    let msg = "Video file is too small. Recording likely failed."
    Logger.error(
      ~module_="VideoEncoder",
      ~message="TRANSCODE_INPUT_TOO_SMALL",
      ~data=Some({"size": Blob.size(webmBlob)}),
      (),
    )
    Promise.resolve(Error(msg))
  } else {
    let formData = FormData.newFormData()
    FormData.appendWithFilename(formData, "file", webmBlob, "input.webm")

    RequestQueue.schedule(() => {
      Fetch.fetch(
        Constants.backendUrl ++ "/api/media/transcode-video",
        Fetch.requestInit(~method="POST", ~body=formData, ()),
      )
      ->Promise.then(BackendApi.handleResponse)
      ->Promise.then(resultResponse => {
        switch resultResponse {
        | Ok(res) => {
            switch progressCallback {
            | Some(cb) => {
                cb(50.0, "Processing...")
                Logger.debug(
                  ~module_="VideoEncoder",
                  ~message="TRANSCODE_PROGRESS",
                  ~data=Some({"percent": 50.0}),
                  (),
                )
              }
            | None => ()
            }
            Fetch.blob(res)->Promise.then(
              mp4Blob => {
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

                DownloadSystem.saveBlob(mp4Blob, filename)
                Promise.resolve(Ok())
              },
            )
          }
        | Error(msg) => Promise.resolve(Error(msg))
        }
      })
    })->Promise.catch(err => {
      let durationMs = Date.now() -. startTime
      let (msg, stack) = Logger.getErrorDetails(err)
      Logger.error(
        ~module_="VideoEncoder",
        ~message="TRANSCODE_FAILED",
        ~data=Some({"durationMs": durationMs, "error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error(msg))
    })
  }
}
