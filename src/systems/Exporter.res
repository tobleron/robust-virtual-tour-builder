/* src/systems/Exporter.res */

open ReBindings
open Types

type apiError = {
  error: string,
  details: option<string>,
}

let apiErrorDecoder = JsonCombinators.Json.Decode.object(field => {
  {
    error: field.required("error", JsonCombinators.Json.Decode.string),
    details: field.optional("details", JsonCombinators.Json.Decode.string),
  }
})

// Version is accessed natively

/* Helper to fetch library files */
let fetchLib = async filename => {
  try {
    let response = await Fetch.fetch("/libs/" ++ filename, Fetch.requestInit(~method="GET", ()))

    if !Fetch.ok(response) {
      Error("Missing Library: " ++ filename)
    } else {
      let b = await Fetch.blob(response)
      Ok(b)
    }
  } catch {
  | exn =>
    let (msg, _stack) = Logger.getErrorDetails(exn)
    Error(msg)
  }
}

/* XHR Upload Logic via Raw JS (for progress events) */
/* XHR Upload Logic via Raw JS (for progress events) with Abort Support */
let uploadAndProcessRaw: (
  FormData.t,
  (float, float, string) => unit,
  string,
  ~signal: BrowserBindings.AbortController.signal,
) => Promise.t<Blob.t> = %raw(`
  function(formData, onProgress, backendUrl, signal) {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/api/project/create-tour-package");
        xhr.timeout = 300000; // 5 minutes

        if (signal) {
          signal.addEventListener('abort', () => {
            xhr.abort();
            reject(new Error("AbortError: Export cancelled by user"));
          });
          if (signal.aborted) {
            xhr.abort();
            reject(new Error("AbortError: Export cancelled by user"));
            return;
          }
        }

        xhr.upload.onprogress = (e) => {
            if (e.lengthComputable) {
                const percent = Math.round((e.loaded / e.total) * 50);
                if (onProgress) onProgress(percent, 100, "Uploading: " + Math.round((e.loaded / 1024 / 1024)) + "MB sent");
            }
        };

        xhr.onload = () => {
            if (xhr.status === 200) {
                if (onProgress) onProgress(100, 100, "Download Ready");
                resolve(xhr.response);
            } else {
                try {
                    if (xhr.responseType === "blob") {
                        const reader = new FileReader();
                        reader.onload = () => {
                            // Reject with RAW TEXT so ReScript can parse it safely
                            reject(new Error(reader.result));
                        };
                        reader.readAsText(xhr.response);
                    } else {
                        // Reject with RAW TEXT
                        reject(new Error(xhr.responseText));
                    }
                } catch (e) {
                    reject(new Error("Backend returned status " + xhr.status));
                }
            }
        };

        xhr.onerror = () => reject(new Error("Network Error - Check Backend Connection"));
        xhr.ontimeout = () => reject(new Error("Request Timed Out (5m limit)"));

        xhr.upload.onload = () => {
            if (onProgress) onProgress(50, 100, "Processing on Server (Please Wait)...");
        };

        xhr.responseType = "blob";
        xhr.send(formData);
    });
  }
`)

let exportTour = async (
  scenes: array<scene>,
  ~signal: BrowserBindings.AbortController.signal,
  onProgress: option<(float, float, string) => unit>,
): result<unit, string> => {
  let progress = (p, t, m) => {
    switch onProgress {
    | Some(cb) => cb(p, t, m)
    | None => ()
    }
  }

  /* Get Tour Name */
  let tourName = GlobalStateBridge.getState().tourName
  let tourName = if tourName == "" {
    "Virtual_Tour"
  } else {
    tourName
  }
  let safeName = tourName->String.replaceRegExp(/[^a-z0-9]/gi, "_")->String.toLowerCase

  // Progress starts after confirmation in higher level?
  // For Export it starts immediately because there is no file picker BEFORE upload.
  progress(0.0, 100.0, "Preparing assets...")
  let exportStartTime = Date.now()
  let currentPhase = ref("INITIAL")

  Logger.startOperation(
    ~module_="Exporter",
    ~operation="EXPORT",
    ~data=Some({"sceneCount": Belt.Array.length(scenes), "tourName": tourName}),
    (),
  )

  try {
    let formData = FormData.newFormData()
    let version = Version.version

    /* 1. Generate HTML Templates */
    currentPhase := "TEMPLATES"
    Logger.debug(~module_="Exporter", ~message="PHASE_TEMPLATES", ())
    let html4k = TourTemplates.generateTourHTML(scenes, tourName, true, "4k", 120, 60, version)
    let html2k = TourTemplates.generateTourHTML(scenes, tourName, true, "2k", 90, 50, version)
    let htmlHd = TourTemplates.generateTourHTML(scenes, tourName, true, "hd", 60, 40, version)
    let htmlIndex = TourTemplates.generateExportIndex(tourName, version)
    let embed = TourTemplates.generateEmbedCodes(tourName, Version.version)

    FormData.append(formData, "html_4k", html4k)
    FormData.append(formData, "html_2k", html2k)
    FormData.append(formData, "html_hd", htmlHd)
    FormData.append(formData, "html_index", htmlIndex)
    FormData.append(formData, "embed_codes", embed)

    /* 2. Append Libraries */
    currentPhase := "LIBRARIES"
    Logger.debug(~module_="Exporter", ~message="PHASE_LIBRARIES", ())
    try {
      let panJSRes: result<Blob.t, string> = await fetchLib("pannellum.js")
      let panCSSRes: result<Blob.t, string> = await fetchLib("pannellum.css")
      switch (panJSRes, panCSSRes) {
      | (Ok(panJS), Ok(panCSS)) => {
          FormData.appendWithFilename(formData, "pannellum.js", panJS, "pannellum.js")
          FormData.appendWithFilename(formData, "pannellum.css", panCSS, "pannellum.css")
        }
      | (Error(e), _) | (_, Error(e)) =>
        Logger.error(~module_="Exporter", ~message="FETCH_LIBS_FAILED", ~data={"error": e}, ())
      }
    } catch {
    | exn =>
      let (msg, stack) = Logger.getErrorDetails(exn)
      Logger.error(
        ~module_="Exporter",
        ~message="FETCH_LIBS_FAILED",
        ~data={"error": msg, "stack": stack},
        (),
      )
    }

    /* 3. Append Logo */
    currentPhase := "LOGO"
    Logger.debug(~module_="Exporter", ~message="PHASE_LOGO", ())
    try {
      let logoRes = await Fetch.fetchSimple("images/logo.png")
      if Fetch.ok(logoRes) {
        let logoBlob = await Fetch.blob(logoRes)
        FormData.appendWithFilename(formData, "logo.png", logoBlob, "logo.png")
      }
    } catch {
    | _ => Logger.warn(~module_="Exporter", ~message="LOGO_NOT_FOUND", ())
    }

    /* 4. Append Scene Images */
    currentPhase := "SCENES"
    Logger.debug(
      ~module_="Exporter",
      ~message="PHASE_SCENES",
      ~data=Some({"count": Belt.Array.length(scenes)}),
      (),
    )
    Belt.Array.forEachWithIndex(scenes, (idx, s) => {
      let file: Blob.t = switch s.originalFile {
      | Some(f) => UiHelpers.fileToBlob(f)
      | None => UiHelpers.fileToBlob(s.file)
      }
      FormData.appendWithFilename(formData, `scene_${Belt.Int.toString(idx)}`, file, s.name)
    })

    /* 5. Send via XHR */
    currentPhase := "UPLOAD"
    Logger.info(~module_="Exporter", ~message="UPLOAD_START", ())
    let backendUrl = Constants.backendUrl
    let zipBlob = await RequestQueue.schedule(() =>
      uploadAndProcessRaw(formData, progress, backendUrl, ~signal)
    )

    progress(100.0, 100.0, "Saving...")
    let filename = `Export_RMX_${safeName}_v${version}.zip`
    Logger.endOperation(
      ~module_="Exporter",
      ~operation="EXPORT",
      ~data=Some({"filename": filename, "durationMs": Date.now() -. exportStartTime}),
      (),
    )
    Logger.info(
      ~module_="Exporter",
      ~message="DOWNLOAD_TRIGGERED",
      ~data=Some({"filename": filename}),
      (),
    )
    DownloadSystem.saveBlob(zipBlob, filename)
    Ok()
  } catch {
  | exn => {
      let (msg, stack) = Logger.getErrorDetails(exn)

      if String.includes(msg, "AbortError") {
        Logger.info(~module_="Exporter", ~message="EXPORT_CANCELLED", ())
        progress(0.0, 0.0, "Cancelled")
        Error("CANCELLED")
      } else {
        let finalMsg = switch JsonCombinators.Json.parse(msg) {
        | Ok(json) =>
          switch JsonCombinators.Json.decode(json, apiErrorDecoder) {
          | Ok(err) => err.details->Option.getOr(err.error)
          | Error(_) => msg
          }
        | Error(_) => msg
        }

        Logger.error(
          ~module_="Exporter",
          ~message="EXPORT_FAILED",
          ~data={"error": finalMsg, "stack": stack, "phase": currentPhase.contents},
          (),
        )
        // ... dispatch notification ...
        progress(0.0, 0.0, "Failed")
        Error(finalMsg)
      }
    }
  }
}
