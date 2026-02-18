open ReBindings
open Types

/* --- Re-exports to maintain public API --- */
type apiError = ExporterUtils.apiError = {
  error: string,
  details: option<string>,
}

let apiErrorDecoder = ExporterUtils.apiErrorDecoder
let fetchLib = ExporterUtils.fetchLib
let uploadAndProcessRaw = ExporterUpload.uploadAndProcessRaw
let throwableMessageRaw = ExporterUtils.throwableMessageRaw
let normalizeThrowableMessage = ExporterUtils.normalizeThrowableMessage
let isUnauthorizedHttpError = ExporterUtils.isUnauthorizedHttpError
let extractHttpErrorBody = ExporterUtils.extractHttpErrorBody
let backendOfflineExportMessage = ExporterUtils.backendOfflineExportMessage
let fetchSceneUrlBlob = ExporterUtils.fetchSceneUrlBlob
let normalizeLogoExtension = ExporterUtils.normalizeLogoExtension
let filenameFromUrl = ExporterUtils.filenameFromUrl
let isLikelyImageUrl = ExporterUtils.isLikelyImageUrl
let isLikelyImageBlob = ExporterUtils.isLikelyImageBlob

/* --- Main Logic --- */

let exportTour = async (
  scenes: array<scene>,
  ~tourName: string,
  ~logo: option<file>,
  ~projectData: option<JSON.t>=?,
  ~signal: BrowserBindings.AbortSignal.t,
  onProgress: option<(float, float, string) => unit>,
): result<unit, string> => {
  let exportScenes = scenes->Belt.Array.keep(s => s.floor->String.trim != "")

  let progress = (p, t, m) => {
    switch onProgress {
    | Some(cb) => cb(p, t, m)
    | None => ()
    }
  }

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
    ~data=Some({
      "sceneCount": Belt.Array.length(exportScenes),
      "originalSceneCount": Belt.Array.length(scenes),
      "tourName": tourName,
    }),
    (),
  )

  try {
    if Belt.Array.length(exportScenes) == 0 {
      let msg = "No scenes with a floor set were found. Set a floor on at least one scene and export again."
      Logger.warn(
        ~module_="Exporter",
        ~message="EXPORT_BLOCKED_NO_FLOOR_SCENES",
        ~data=Some({"originalSceneCount": Belt.Array.length(scenes)}),
        (),
      )
      JsError.throwWithMessage(msg)
    }

    currentPhase := "HEALTH_CHECK"
    progress(1.0, 100.0, "Checking backend...")
    let backendHealthy = await Resizer.checkBackendHealth()
    if !backendHealthy {
      let msg = backendOfflineExportMessage()
      Logger.warn(
        ~module_="Exporter",
        ~message="EXPORT_BACKEND_UNREACHABLE_PRECHECK",
        ~data=Some({"backendUrl": Constants.backendUrl}),
        (),
      )
      JsError.throwWithMessage(msg)
    }

    let formData = FormData.newFormData()
    let version = Version.version
    let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")
    let finalToken = switch token {
    | Some(t) => Some(t)
    | None if Constants.isDebugBuild() => Some("dev-token")
    | None => None
    }

    /* 1. Set Logo (prioritize custom uploaded logo) */
    currentPhase := "LOGO"
    Logger.debug(~module_="Exporter", ~message="PHASE_LOGO", ())

    let logoFilename = ref(None)

    switch logo {
    | Some(File(f)) => {
        let name = "logo." ++ normalizeLogoExtension(f->File.name)
        FormData.appendWithFilename(formData, name, f, name)
        logoFilename := Some(name)
      }
    | Some(Blob(b)) => {
        let name = "logo.png" // Default extension for blobs if unknown
        FormData.appendWithFilename(formData, name, b, name)
        logoFilename := Some(name)
      }
    | Some(Url(url)) =>
      if url == "" || !isLikelyImageUrl(url) {
        Logger.warn(
          ~module_="Exporter",
          ~message="LOGO_URL_SKIPPED_INVALID",
          ~data=Some({"url": url}),
          (),
        )
      } else {
        switch await fetchSceneUrlBlob(~url, ~authToken=finalToken) {
        | Ok(logoBlob) =>
          if isLikelyImageBlob(~blob=logoBlob, ~urlHint=Some(url)) {
            let ext = switch filenameFromUrl(url) {
            | Some(fileName) => normalizeLogoExtension(fileName)
            | None => "png"
            }
            let name = "logo." ++ ext
            FormData.appendWithFilename(formData, name, logoBlob, name)
            logoFilename := Some(name)
          } else {
            Logger.warn(
              ~module_="Exporter",
              ~message="LOGO_URL_NOT_IMAGE",
              ~data=Some({"url": url, "blobType": logoBlob->Blob.type_}),
              (),
            )
          }
        | Error(msg) =>
          Logger.warn(
            ~module_="Exporter",
            ~message="LOGO_URL_FETCH_FAILED",
            ~data=Some({"url": url, "error": msg}),
            (),
          )
        }
      }
    | None => ()
    }

    if logoFilename.contents == None {
      try {
        let extensions = ["png", "jpg", "jpeg", "webp"]
        let rec findLogo = async exts => {
          switch exts {
          | list{} => ()
          | list{ext, ...rest} => {
              let filename = "logo." ++ ext
              let path = "/images/" ++ filename
              let res = await Fetch.fetchSimple(path)
              if Fetch.ok(res) {
                let logoBlob = await Fetch.blob(res)
                if isLikelyImageBlob(~blob=logoBlob, ~urlHint=Some(path)) {
                  FormData.appendWithFilename(formData, filename, logoBlob, filename)
                  logoFilename := Some(filename)
                } else {
                  await findLogo(rest)
                }
              } else {
                await findLogo(rest)
              }
            }
          }
        }
        await findLogo(Belt.List.fromArray(extensions))
      } catch {
      | _ => Logger.warn(~module_="Exporter", ~message="LOGO_NOT_FOUND", ())
      }
    }

    /* 2. Generate HTML Templates */
    currentPhase := "TEMPLATES"
    Logger.debug(~module_="Exporter", ~message="PHASE_TEMPLATES", ())
    let html4k = TourTemplates.generateTourHTML(
      exportScenes,
      tourName,
      logoFilename.contents,
      "4k",
      28,
      54,
      version,
    )
    let html2k = TourTemplates.generateTourHTML(
      exportScenes,
      tourName,
      logoFilename.contents,
      "2k",
      28,
      50,
      version,
    )
    let htmlHd = TourTemplates.generateTourHTML(
      exportScenes,
      tourName,
      logoFilename.contents,
      "hd",
      28,
      40,
      version,
    )
    let htmlIndex = TourTemplates.generateExportIndex(tourName, version, logoFilename.contents)
    let embed = TourTemplates.generateEmbedCodes(tourName, Version.version)

    FormData.append(formData, "html_4k", html4k)
    FormData.append(formData, "html_2k", html2k)
    FormData.append(formData, "html_hd", htmlHd)
    FormData.append(formData, "html_index", htmlIndex)
    FormData.append(formData, "embed_codes", embed)
    projectData->Option.forEach(data =>
      FormData.append(formData, "project_data", JsonCombinators.Json.stringify(data))
    )

    /* 3. Append Libraries */
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

    /* 4. Append Scene Images */
    currentPhase := "SCENES"
    Logger.debug(
      ~module_="Exporter",
      ~message="PHASE_SCENES",
      ~data=Some({"count": Belt.Array.length(exportScenes)}),
      (),
    )
    let rec appendScenes = async (sceneList, idx) => {
      switch sceneList {
      | list{} => Ok()
      | list{s, ...rest} => {
          let sourceFile = switch s.originalFile {
          | Some(f) => f
          | None => s.file
          }

          let blobResult = switch sourceFile {
          | Blob(b) => Ok(b)
          | File(f) => Ok(UiHelpers.fileToBlob(File(f)))
          | Url(url) =>
            let initial = await fetchSceneUrlBlob(~url, ~authToken=finalToken)
            switch initial {
            | Ok(_) => initial
            | Error(msg) =>
              let usingDevToken = switch finalToken {
              | Some(t) => t == "dev-token"
              | None => false
              }
              if Constants.isDebugBuild() && !usingDevToken && isUnauthorizedHttpError(msg) {
                await fetchSceneUrlBlob(~url, ~authToken=Some("dev-token"))
              } else {
                initial
              }
            }
          }

          switch blobResult {
          | Ok(fileBlob) =>
            FormData.appendWithFilename(
              formData,
              `scene_${Belt.Int.toString(idx)}`,
              fileBlob,
              s.name,
            )
            await appendScenes(rest, idx + 1)
          | Error(msg) => Error("Scene packaging failed for '" ++ s.name ++ "': " ++ msg)
          }
        }
      }
    }
    switch await appendScenes(Belt.List.fromArray(exportScenes), 0) {
    | Ok() => ()
    | Error(msg) => JsError.throwWithMessage(msg)
    }

    /* 5. Send via XHR */
    currentPhase := "UPLOAD"
    Logger.info(~module_="Exporter", ~message="UPLOAD_START", ())
    let backendUrl = Constants.backendUrl

    let rec uploadWithRetry = async (retryCount, token) => {
      try {
        let result = await uploadAndProcessRaw(formData, progress, backendUrl, ~signal, ~token)
        CircuitBreaker.recordSuccess(AuthenticatedClient.circuitBreaker)
        result
      } catch {
      | exn =>
        let msg = normalizeThrowableMessage(exn)
        let isLegacyNetworkOffline = String.includes(msg, "NetworkOffline")
        let isAbort = String.includes(msg, "AbortError")
        let isUnauthorized = isUnauthorizedHttpError(msg)
        let isTransportNetworkError = String.includes(msg, "NetworkError") || isLegacyNetworkOffline
        let backendStillReachable = if isTransportNetworkError {
          await Resizer.checkBackendHealth()
        } else {
          true
        }

        let usingDevToken = switch token {
        | Some(t) => t == "dev-token"
        | None => false
        }
        let shouldRetryWithDevToken = Constants.isDebugBuild() && !usingDevToken && isUnauthorized

        if shouldRetryWithDevToken {
          Logger.warn(
            ~module_="Exporter",
            ~message="EXPORT_RETRY_WITH_DEV_TOKEN",
            ~data=Some({"reason": "401 Unauthorized", "hadAuthToken": token != None}),
            (),
          )
          await uploadWithRetry(0, Some("dev-token"))
        } else if isTransportNetworkError && !backendStillReachable {
          let message = backendOfflineExportMessage()
          Logger.warn(
            ~module_="Exporter",
            ~message="EXPORT_BACKEND_UNREACHABLE_DURING_UPLOAD",
            ~data=Some({"backendUrl": Constants.backendUrl, "error": msg}),
            (),
          )
          CircuitBreaker.recordFailure(AuthenticatedClient.circuitBreaker)
          JsError.throwWithMessage(message)
        } else if retryCount < 2 && !isAbort && !isUnauthorized {
          Logger.warn(
            ~module_="Exporter",
            ~message="EXPORT_RETRY",
            ~data=Some(Logger.castToJson({"attempt": retryCount + 1, "error": msg})),
            (),
          )
          progress(0.0, 100.0, "Retrying export upload...")
          let _ = await Promise.make((resolve, _) => {
            let _ = ReBindings.Window.setTimeout(() => resolve(), 2000)
          })
          await uploadWithRetry(retryCount + 1, token)
        } else {
          CircuitBreaker.recordFailure(AuthenticatedClient.circuitBreaker)
          if isLegacyNetworkOffline {
            JsError.throwWithMessage(
              "NetworkError: Export upload was interrupted. Please retry export.",
            )
          } else {
            JsError.throwWithMessage(msg)
          }
        }
      }
    }

    let zipBlob = await uploadWithRetry(0, finalToken)

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
      let (msgFromLogger, stack) = Logger.getErrorDetails(exn)
      let msg = normalizeThrowableMessage(exn)
      let normalizedStack = if stack != "" {
        stack
      } else {
        msgFromLogger
      }

      if String.includes(msg, "AbortError") {
        Logger.info(~module_="Exporter", ~message="EXPORT_CANCELLED", ())
        progress(0.0, 0.0, "Cancelled")
        Error("CANCELLED")
      } else {
        let payload = extractHttpErrorBody(msg)
        let finalMsg = switch JsonCombinators.Json.parse(payload) {
        | Ok(json) =>
          switch JsonCombinators.Json.decode(json, apiErrorDecoder) {
          | Ok(err) => err.details->Option.getOr(err.error)
          | Error(_) => payload
          }
        | Error(_) => payload
        }

        Logger.error(
          ~module_="Exporter",
          ~message="EXPORT_FAILED",
          ~data={"error": finalMsg, "stack": normalizedStack, "phase": currentPhase.contents},
          (),
        )
        // ... dispatch notification ...
        progress(0.0, 0.0, "Failed")
        Error(finalMsg)
      }
    }
  }
}
