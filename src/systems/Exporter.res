/* src/systems/Exporter.res */

open ReBindings
open Types
open EventBus

module Version = {
  @module("../version.js") external version: string = "VERSION"
}

/* Helper to fetch library files */
let fetchLib = async filename => {
  let {result, durationMs: _} = await Logger.timedAsync(
    ~module_="Exporter",
    ~operation=`FETCH_LIB:${filename}`,
    async () => {
      let response = await Fetch.fetch(
        "/libs/" ++ filename,
        {
          method: "GET",
          body: Obj.magic(Nullable.null),
          headers: Nullable.null,
        },
      )

      if !Fetch.ok(response) {
        JsError.throwWithMessage("Missing Library: " ++ filename)
      }

      await Fetch.blob(response)
    },
  )

  result
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
        xhr.open("POST", backendUrl + "/create-tour-package");
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
) => {
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
    let version = Version.version

    /* 1. Generate HTML Templates */
    currentPhase := "TEMPLATES"
    Logger.debug(~module_="Exporter", ~message="PHASE_TEMPLATES", ())
    let html4k = TourTemplates.generateTourHTML(scenes, tourName, true, "4k", 120, 60, version)
    let html2k = TourTemplates.generateTourHTML(scenes, tourName, true, "2k", 90, 50, version)
    let htmlHd = TourTemplates.generateTourHTML(scenes, tourName, true, "hd", 60, 40, version)
    let htmlIndex = TourTemplates.generateExportIndex(tourName, version)
    let embed = TourTemplates.generateEmbedCodes(tourName, version)

    FormData.append(formData, "html_4k", html4k)
    FormData.append(formData, "html_2k", html2k)
    FormData.append(formData, "html_hd", htmlHd)
    FormData.append(formData, "html_index", htmlIndex)
    FormData.append(formData, "embed_codes", embed)

    /* 2. Append Libraries */
    currentPhase := "LIBRARIES"
    Logger.debug(~module_="Exporter", ~message="PHASE_LIBRARIES", ())
    try {
      let panJS = await fetchLib("pannellum.js")
      let panCSS = await fetchLib("pannellum.css")
      FormData.appendWithFilename(formData, "pannellum.js", panJS, "pannellum.js")
      FormData.appendWithFilename(formData, "pannellum.css", panCSS, "pannellum.css")
    } catch {
    | JsExn(e) =>
      Logger.error(
        ~module_="Exporter",
        ~message="FETCH_LIBS_FAILED",
        ~data=Some({"error": Option.getOr(JsExn.message(e), "Unknown")}),
        (),
      )
    | _ => Logger.error(~module_="Exporter", ~message="FETCH_LIBS_FAILED", ())
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
      | Some(f) => Obj.magic(f)
      | None => Obj.magic(s.file)
      }
      FormData.appendWithFilename(formData, `scene_${Belt.Int.toString(idx)}`, file, s.name)
    })

    /* 5. Send via XHR */
    currentPhase := "UPLOAD"
    Logger.info(~module_="Exporter", ~message="UPLOAD_START", ())
    let backendUrl = Constants.backendUrl
    let zipBlob = await uploadAndProcessRaw(formData, progress, backendUrl)

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
  } catch {
  | JsExn(e) => {
      let msg = Option.getOr(JsExn.message(e), "Unknown Error")
      Logger.error(
        ~module_="Exporter",
        ~message="EXPORT_FAILED",
        ~data=Some({"error": msg, "phase": currentPhase.contents}),
        (),
      )
      EventBus.dispatch(ShowNotification(`Export Failed: ${msg}`, #Error))
      progress(0.0, 0.0, "Failed")
    }
  | _ => {
      Logger.error(
        ~module_="Exporter",
        ~message="EXPORT_FAILED",
        ~data=Some({"error": "Unknown", "phase": currentPhase.contents}),
        (),
      )
      EventBus.dispatch(ShowNotification("Export Failed: Unknown Error", #Error))
      progress(0.0, 0.0, "Failed")
    }
  }
}
