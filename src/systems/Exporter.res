/* src/systems/Exporter.res */
open ReBindings
open Types

/* --- Main Logic --- */

let exportTour = async (
  scenes: array<scene>,
  ~tourName: string,
  ~logo: option<file>,
  ~projectData: option<JSON.t>=?,
  ~signal: BrowserBindings.AbortSignal.t,
  onProgress: option<(float, float, string) => unit>,
  ~opId: option<OperationLifecycle.operationId>=?,
): result<unit, string> => {
  let exportScenes = scenes->Belt.Array.keep(s => s.floor->String.trim != "")

  let opId = switch opId {
  | Some(id) => id
  | None =>
    OperationLifecycle.start(
      ~type_=Export,
      ~scope=Blocking,
      ~phase="Preparing",
      ~meta=Logger.castToJson({
        "sceneCount": Belt.Array.length(scenes),
        "tourName": tourName,
      }),
      (),
    )
  }

  let currentPhase = ref("INITIAL")

  let progress = (p, t, m) => {
    let pct = if t > 0.0 {
      p /. t *. 100.0
    } else {
      0.0
    }
    OperationLifecycle.progress(opId, pct, ~message=m, ~phase=currentPhase.contents, ())
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

  progress(0.0, 100.0, "Preparing export...")
  let exportStartTime = Date.now()

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
    progress(1.0, 100.0, "Verifying connection...")
    if !NetworkStatus.isOnline() {
      let msg = "NetworkOffline: " ++ ExporterUtils.backendOfflineExportMessage()
      JsError.throwWithMessage(msg)
    }
    let backendHealthy = await Resizer.checkBackendHealth()
    if !backendHealthy {
      let msg = ExporterUtils.backendOfflineExportMessage()
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
    progress(3.0, 100.0, "Packaging logo...")
    Logger.debug(~module_="Exporter", ~message="PHASE_LOGO", ())

    let logoFilename = await ExporterPackaging.appendLogo(
      ~formData,
      ~logo,
      ~authToken=finalToken,
      ~signal=Some(signal),
    )

    /* 2. Generate HTML Templates */
    currentPhase := "TEMPLATES"
    progress(7.0, 100.0, "Generating tour pages...")
    Logger.debug(~module_="Exporter", ~message="PHASE_TEMPLATES", ())
    ExporterPackaging.appendTemplates(
      ~formData,
      ~exportScenes,
      ~tourName,
      ~logoFilename,
      ~version,
      ~projectData?,
    )

    /* 3. Append Libraries */
    currentPhase := "LIBRARIES"
    progress(12.0, 100.0, "Bundling viewer engine...")
    Logger.debug(~module_="Exporter", ~message="PHASE_LIBRARIES", ())
    await ExporterPackaging.appendLibraries(~formData, ~signal=Some(signal))

    /* 4. Append Scene Images */
    currentPhase := "SCENES"
    let totalScenes = Belt.Array.length(exportScenes)
    progress(15.0, 100.0, "Packaging scenes...")
    Logger.debug(
      ~module_="Exporter",
      ~message="PHASE_SCENES",
      ~data=Some({"count": totalScenes}),
      (),
    )
    switch await ExporterPackaging.appendScenes(
      ~formData,
      ~exportScenes,
      ~authToken=finalToken,
      ~progress,
      ~signal=Some(signal),
    ) {
    | Ok() => ()
    | Error(msg) => JsError.throwWithMessage(msg)
    }

    /* 5. Send via XHR */
    currentPhase := "UPLOAD"
    progress(40.0, 100.0, "Starting upload...")
    Logger.info(~module_="Exporter", ~message="UPLOAD_START", ())
    let backendUrl = Constants.backendUrl

    let rec uploadWithRetry = async (retryCount, token) => {
      try {
        let result = await ExporterUpload.uploadAndProcessRaw(
          formData,
          progress,
          backendUrl,
          Constants.Exporter.uploadTimeoutMs,
          ~signal,
          ~token,
          ~operationId=Some(opId),
        )
        CircuitBreaker.recordSuccess(AuthenticatedClient.circuitBreaker)
        result
      } catch {
      | exn =>
        let msg = ExporterUtils.normalizeThrowableMessage(exn)
        let isLegacyNetworkOffline = String.includes(msg, "NetworkOffline")
        let isAbort = String.includes(msg, "AbortError")
        let isUnauthorized = ExporterUtils.isUnauthorizedHttpError(msg)
        let isTimeout = String.includes(msg, "TimeoutError")
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
          let message = ExporterUtils.backendOfflineExportMessage()
          Logger.warn(
            ~module_="Exporter",
            ~message="EXPORT_BACKEND_UNREACHABLE_DURING_UPLOAD",
            ~data=Some({"backendUrl": Constants.backendUrl, "error": msg}),
            (),
          )
          CircuitBreaker.recordFailure(AuthenticatedClient.circuitBreaker)
          JsError.throwWithMessage(message)
        } else if retryCount < 2 && !isAbort && !isUnauthorized && !isTimeout {
          Logger.warn(
            ~module_="Exporter",
            ~message="EXPORT_RETRY",
            ~data=Some(Logger.castToJson({"attempt": retryCount + 1, "error": msg})),
            (),
          )
          progress(40.0, 100.0, "Retrying upload...")
          let _ = await Promise.make((resolve, _) => {
            let _ = ReBindings.Window.setTimeout(() => resolve(), Constants.Exporter.retryDelayMs)
          })
          await uploadWithRetry(retryCount + 1, token)
        } else if isTimeout {
          Logger.warn(
            ~module_="Exporter",
            ~message="EXPORT_TIMEOUT_NO_RETRY",
            ~data=Some({"timeoutMs": Constants.Exporter.uploadTimeoutMs, "error": msg}),
            (),
          )
          JsError.throwWithMessage(msg)
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

    progress(100.0, 100.0, "Export complete")
    let filename = `Export_RMX_${safeName}_v${version}.zip`
    OperationLifecycle.complete(opId, ~result=filename, ())
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
      let msg = ExporterUtils.normalizeThrowableMessage(exn)
      let normalizedStack = if stack != "" {
        stack
      } else {
        msgFromLogger
      }

      if String.includes(msg, "AbortError") {
        Logger.info(~module_="Exporter", ~message="EXPORT_CANCELLED", ())
        OperationLifecycle.cancel(opId)
        progress(0.0, 0.0, "Cancelled")
        Error("CANCELLED")
      } else {
        let payload = ExporterUtils.extractHttpErrorBody(msg)
        let finalMsg = switch JsonCombinators.Json.parse(payload) {
        | Ok(json) =>
          switch JsonCombinators.Json.decode(json, ExporterUtils.apiErrorDecoder) {
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
        OperationLifecycle.fail(opId, finalMsg)
        progress(0.0, 0.0, "Failed")
        Error(finalMsg)
      }
    }
  }
}
