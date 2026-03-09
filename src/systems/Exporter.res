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
  publishProfiles: array<string>,
): result<unit, string> => {
  let exportScenes = scenes->Belt.Array.keep(s => s.floor->String.trim != "")

  let opId =
    ExporterRuntime.resolveOpId(~opId, ~sceneCount=Belt.Array.length(scenes), ~tourName)

  let currentPhase = ref("INITIAL")

  let progress = (p, t, m) => {
    ExporterRuntime.reportProgress(~opId, ~currentPhase, ~onProgress, p, t, m)
  }

  let tourName = if tourName == "" {
    ExporterRuntime.normalizeTourName(tourName)
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
      let msg = "No scenes have a floor set. Assign floors first."
      Logger.warn(
        ~module_="Exporter",
        ~message="EXPORT_BLOCKED_NO_FLOOR_SCENES",
        ~data=Some({"originalSceneCount": Belt.Array.length(scenes)}),
        (),
      )
      JsError.throwWithMessage(msg)
    }

    /* 0. Project Validation: Connectivity and Tags */
    switch ProjectConnectivity.validateProjectForGeneration(exportScenes) {
    | Ok() => ()
    | Error({message, scenes, count}) =>
      Logger.warn(
        ~module_="Exporter",
        ~message="EXPORT_BLOCKED_VALIDATION_FAILED",
        ~data=Some({"count": count, "scenes": scenes}),
        (),
      )
      JsError.throwWithMessage("Export blocked: " ++ message)
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
      ~publishProfiles,
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
    let zipBlob = await ExporterRuntime.uploadWithRetry(
      ~formData,
      ~progress,
      ~backendUrl,
      ~totalScenes,
      ~signal,
      ~opId,
      ~token=finalToken,
      ~retryCount=0,
    )

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
