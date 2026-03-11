open Types

type apiError = string

let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
  switch JsonCombinators.Json.decode(data, JsonParsers.Domain.project) {
  | Ok(_) => Ok(data)
  | Error(e) => Error("Invalid project structure: " ++ e)
  }
}

let dispatchValidationWarning = message => {
  NotificationManager.dispatch({
    id: "",
    importance: Warning,
    context: Operation("project_manager"),
    message,
    details: None,
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(Warning),
    dismissible: true,
    createdAt: Date.now(),
  })
}

let notifyProjectValidationWarnings = (report: SharedTypes.validationReport) => {
  if report.brokenLinksRemoved > 0 {
    dispatchValidationWarning(
      "Project loaded. " ++
      Belt.Int.toString(report.brokenLinksRemoved) ++ " broken link(s) removed.",
    )
  }

  if Array.length(report.orphanedScenes) > 0 {
    dispatchValidationWarning(
      "Warning: " ++
      Belt.Int.toString(Array.length(report.orphanedScenes)) ++ " orphaned scene(s) detected.",
    )
  }

  report.warnings->Belt.Array.forEach(message =>
    dispatchValidationWarning(NotificationTypes.truncateForToast("Project warning: " ++ message))
  )
}

let verifyProjectLoadPolicy = (projectData: JSON.t, ~validationReportWrapperDecoder): result<
  option<SharedTypes.validationReport>,
  apiError,
> => {
  switch JsonCombinators.Json.decode(projectData, validationReportWrapperDecoder) {
  | Ok(decodedReport) =>
    let report: SharedTypes.validationReport = decodedReport
    if Array.length(report.errors) > 0 {
      let firstError = Belt.Array.get(report.errors, 0)->Option.getOr("Unknown validation error")
      Error(
        "Project verification failed: " ++
        firstError ++
        " (" ++
        Belt.Int.toString(Array.length(report.errors)) ++ " blocking issue(s))",
      )
    } else {
      Ok(Some(report))
    }
  | Error(_) =>
    Logger.warn(
      ~module_="ProjectManager",
      ~message="PROJECT_LOAD_VALIDATION_REPORT_MISSING",
      ~data=Some({"reason": "validationReport field missing or invalid"}),
      (),
    )
    Ok(None)
  }
}

let encodeValidationReport = (report: SharedTypes.validationReport): JSON.t =>
  JsonCombinators.Json.Encode.object([
    ("brokenLinksRemoved", JsonCombinators.Json.Encode.int(report.brokenLinksRemoved)),
    (
      "orphanedScenes",
      JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(report.orphanedScenes),
    ),
    (
      "unusedFiles",
      JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(report.unusedFiles),
    ),
    (
      "warnings",
      JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(report.warnings),
    ),
    (
      "errors",
      JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(report.errors),
    ),
  ])

let processLoadedProjectData = (
  resultSessionData: result<(string, JSON.t), apiError>,
  ~loadStartTime: float,
  ~onProgress: option<(int, int, string) => unit>=?,
  ~verifyProjectLoadPolicy: JSON.t => result<option<SharedTypes.validationReport>, apiError>,
  ~notifyProjectValidationWarnings: SharedTypes.validationReport => unit,
  ~mergeValidationReport: (JSON.t, JSON.t) => JSON.t,
  ~encodeValidationReport: SharedTypes.validationReport => JSON.t,
): Promise.t<BackendApi.apiResult<(string, JSON.t)>> => {
  let progress = (curr, total, msg) => {
    switch onProgress {
    | Some(cb) => cb(curr, total, msg)
    | None => ()
    }
  }

  switch resultSessionData {
  | Ok((sessionId, projectData)) =>
    progress(70, 100, "Resolving scenes...")
    progress(75, 100, "Verifying project integrity...")

    switch verifyProjectLoadPolicy(projectData) {
    | Error(msg) => Promise.resolve(Error(msg))
    | Ok(validationReportOpt) =>
      validationReportOpt->Option.forEach(notifyProjectValidationWarnings)

      switch JsonCombinators.Json.decode(projectData, JsonParsers.Domain.project) {
      | Ok(pd) =>
        let allInventoryScenes =
          pd.inventory->Belt.Map.String.toArray->Belt.Array.map(((_id, entry)) => entry.scene)

        let validScenes = ProjectManagerUrl.rebuildSceneUrls(allInventoryScenes, ~sessionId)

        let updatedInventory = validScenes->Belt.Array.reduce(pd.inventory, (acc, s) => {
          switch acc->Belt.Map.String.get(s.id) {
          | Some(entry) => acc->Belt.Map.String.set(s.id, {...entry, scene: s})
          | None => acc
          }
        })

        let finalOrder = if Array.length(pd.sceneOrder) > 0 {
          pd.sceneOrder
        } else {
          validScenes->Belt.Array.map(s => s.id)
        }

        let (inventoryWithSeq, nextSeqId) = SceneNaming.ensureSequenceIds(
          updatedInventory,
          pd.nextSceneSequenceId,
        )

        let loadedProject: Types.project = {
          ...pd,
          inventory: inventoryWithSeq,
          sceneOrder: finalOrder,
          nextSceneSequenceId: nextSeqId,
          sessionId: Some(sessionId),
          logo: pd.logo->Option.map(l => ProjectManagerUrl.rebuildUrl(l, ~sessionId)),
        }

        loadedProject.logo->Option.forEach(l => {
          Logger.debug(
            ~module_="ProjectManager",
            ~message="LOGO_URL_REBUILT",
            ~data=Some({"url": Types.fileToUrl(l)}),
            (),
          )
        })

        progress(85, 100, "Project data parsed")
        Logger.endOperation(
          ~module_="ProjectManager",
          ~operation="PROJECT_LOAD",
          ~data=Some({
            "sceneCount": Array.length(validScenes),
            "durationMs": Date.now() -. loadStartTime,
          }),
          (),
        )

        let encodedProject = JsonParsers.Encoders.project(loadedProject)
        let encodedWithValidation = switch validationReportOpt {
        | Some(report) => mergeValidationReport(encodedProject, encodeValidationReport(report))
        | None => encodedProject
        }

        Promise.resolve(Ok((sessionId, encodedWithValidation)))
      | Error(e) => Promise.resolve(Error("Failed to parse project data: " ++ e))
      }
    }
  | Error(msg) => Promise.resolve(Error(msg))
  }
}
