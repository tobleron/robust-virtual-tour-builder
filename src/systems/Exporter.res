/* src/systems/Exporter.res */

open ReBindings
open Types
open EventBus

// VersionData is accessed natively

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
let uploadAndProcessRaw: (
  FormData.t,
  (float, float, string) => unit,
  string,
) => Promise.t<Blob.t> = %raw(`
  function(formData, onProgress, backendUrl) {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/api/project/create-tour-package");
        xhr.timeout = 300000; // 5 minutes

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
                            try {
                                const json = JSON.parse(reader.result);
                                reject(new Error(json.details || json.error));
                            } catch (e) {
                                reject(new Error("Backend returned status " + xhr.status));
                            }
                        };
                        reader.readAsText(xhr.response);
                    } else {
                        const json = JSON.parse(xhr.responseText);
                        reject(new Error(json.details || json.error));
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
    let version = VersionData.version

    /* 1. Generate HTML Templates */
    currentPhase := "TEMPLATES"
    Logger.debug(~module_="Exporter", ~message="PHASE_TEMPLATES", ())
    let html4k = TourTemplates.generateTourHTML(scenes, tourName, true, "4k", 120, 60, version)
    let html2k = TourTemplates.generateTourHTML(scenes, tourName, true, "2k", 90, 50, version)
    let htmlHd = TourTemplates.generateTourHTML(scenes, tourName, true, "hd", 60, 40, version)
    let htmlIndex = TourTemplates.generateExportIndex(tourName, version)
    let embed = TourTemplates.generateEmbedCodes(tourName, VersionData.version)

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
      | Some(f) => ReducerHelpers.fileToBlob(f)
      | None => ReducerHelpers.fileToBlob(s.file)
      }
      FormData.appendWithFilename(formData, `scene_${Belt.Int.toString(idx)}`, file, s.name)
    })

    /* 5. Send via XHR */
    currentPhase := "UPLOAD"
    Logger.info(~module_="Exporter", ~message="UPLOAD_START", ())
    let backendUrl = Constants.backendUrl
    let zipBlob = await RequestQueue.schedule(() =>
      uploadAndProcessRaw(formData, progress, backendUrl)
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
      Logger.error(
        ~module_="Exporter",
        ~message="EXPORT_FAILED",
        ~data={"error": msg, "stack": stack, "phase": currentPhase.contents},
        (),
      )
      EventBus.dispatch(ShowNotification(`Export Failed: ${msg}`, #Error))
      progress(0.0, 0.0, "Failed")
      Error(msg)
    }
  }
}
