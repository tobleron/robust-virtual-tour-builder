/* src/systems/ProjectSystem.res - Consolidated Project System */
open ReBindings
open Types

type onProgress = (int, int, string) => unit
type apiError = string

let projectFromState = (state: state): Types.project => {
  {
    tourName: state.tourName,
    inventory: state.inventory,
    sceneOrder: state.sceneOrder,
    lastUsedCategory: state.lastUsedCategory,
    exifReport: state.exifReport,
    sessionId: state.sessionId,
    timeline: state.timeline,
    logo: state.logo,
    marketingComment: state.marketingComment,
    marketingPhone1: state.marketingPhone1,
    marketingPhone2: state.marketingPhone2,
    marketingForRent: state.marketingForRent,
    marketingForSale: state.marketingForSale,
    nextSceneSequenceId: state.nextSceneSequenceId,
  }
}

let encodeProjectFromState = (state: state): JSON.t => {
  JsonParsers.Encoders.project(projectFromState(state))
}

/* --- Validator --- */

let validationReportWrapperDecoder = JsonCombinators.Json.Decode.object(field => {
  field.required("validationReport", JsonParsers.Shared.validationReport)
})

let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
  switch JsonCombinators.Json.decode(data, JsonParsers.Domain.project) {
  | Ok(_) => Ok(data)
  | Error(e) => Error("Invalid project structure: " ++ e)
  }
}

let notifyProjectValidationWarnings = (report: SharedTypes.validationReport) => {
  if report.brokenLinksRemoved > 0 {
    NotificationManager.dispatch({
      id: "",
      importance: Warning,
      context: Operation("project_manager"),
      message: "Project loaded. " ++
      Belt.Int.toString(report.brokenLinksRemoved) ++ " broken link(s) removed.",
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Warning),
      dismissible: true,
      createdAt: Date.now(),
    })
  }
  if Array.length(report.orphanedScenes) > 0 {
    NotificationManager.dispatch({
      id: "",
      importance: Warning,
      context: Operation("project_manager"),
      message: "Warning: " ++
      Belt.Int.toString(Array.length(report.orphanedScenes)) ++ " orphaned scene(s) detected.",
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Warning),
      dismissible: true,
      createdAt: Date.now(),
    })
  }
  report.warnings->Belt.Array.forEach(message =>
    NotificationManager.dispatch({
      id: "",
      importance: Warning,
      context: Operation("project_manager"),
      message: NotificationTypes.truncateForToast("Project warning: " ++ message),
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Warning),
      dismissible: true,
      createdAt: Date.now(),
    })
  )
}

let verifyProjectLoadPolicy = (projectData: JSON.t): result<
  option<SharedTypes.validationReport>,
  apiError,
> => {
  switch JsonCombinators.Json.decode(projectData, validationReportWrapperDecoder) {
  | Ok(r) =>
    if Array.length(r.errors) > 0 {
      let firstError = Belt.Array.get(r.errors, 0)->Option.getOr("Unknown validation error")
      Error(
        "Project verification failed: " ++
        firstError ++
        " (" ++
        Belt.Int.toString(Array.length(r.errors)) ++ " blocking issue(s))",
      )
    } else {
      Ok(Some(r))
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

let mergeValidationReport: (
  JSON.t,
  JSON.t,
) => JSON.t = %raw(`(projectJson, validationReport) => ({...projectJson, validationReport})`)

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

/* --- Loader --- */

let processLoadedProjectData = (
  resultSessionData: result<(string, JSON.t), apiError>,
  ~loadStartTime: float,
  ~onProgress: option<onProgress>=?,
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
        // Rebuild URLs for ALL scenes in the inventory (Active and Deleted)
        let allInventoryScenes =
          pd.inventory->Belt.Map.String.toArray->Belt.Array.map(((_id, entry)) => entry.scene)

        let validScenes = ProjectManagerUrl.rebuildSceneUrls(allInventoryScenes, ~sessionId)

        // Sync valid scenes back into inventory, preserving their original status
        let updatedInventory = validScenes->Belt.Array.reduce(pd.inventory, (acc, s) => {
          switch acc->Belt.Map.String.get(s.id) {
          | Some(entry) => acc->Belt.Map.String.set(s.id, {...entry, scene: s})
          | None => acc // Should not happen if we rebuilt from inventory
          }
        })

        // Ensure sceneOrder is populated from validScenes if it was empty
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

let loadProjectZip = (
  zipFile: File.t,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~onProgress: option<onProgress>=?,
  ~opId: option<OperationLifecycle.operationId>=?,
) => {
  let ownsLifecycle = opId->Option.isNone
  let opId = switch opId {
  | Some(id) => id
  | None =>
    OperationLifecycle.start(
      ~type_=ProjectLoad,
      ~scope=Blocking,
      ~phase="Project Load",
      ~meta=Logger.castToJson({"filename": File.name(zipFile), "size": File.size(zipFile)}),
      (),
    )
  }

  let progress = (curr, total, msg, ~phase: option<string>=?) => {
    let pct = if total > 0 {
      Float.fromInt(curr) /. Float.fromInt(total) *. 100.0
    } else {
      0.0
    }
    let phaseName = phase->Option.getOr("Project Load")
    OperationLifecycle.progress(opId, pct, ~message=msg, ~phase=phaseName, ())
    switch onProgress {
    | Some(cb) => cb(curr, total, msg)
    | None => ()
    }
  }

  progress(0, 100, "Uploading project...", ~phase="Project Load")
  let loadStartTime = Date.now()
  Logger.startOperation(
    ~module_="ProjectManager",
    ~operation="PROJECT_LOAD",
    ~data=Some({"filename": File.name(zipFile), "size": File.size(zipFile)}),
    (),
  )

  BackendApi.importProject(zipFile, ~signal?, ~operationId=opId)
  ->Promise.then(resultRes => {
    switch resultRes {
    | Ok(response) =>
      OperationLifecycle.progress(
        opId,
        50.0,
        ~message="Processing response...",
        ~phase="Project Load",
        (),
      )
      progress(50, 100, "Processing response...", ~phase="Project Load")
      validateProjectStructure(response.projectData)
      ->Belt.Result.map(pd => (response.sessionId, pd))
      ->Promise.resolve
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.then(resultSessionData =>
    processLoadedProjectData(resultSessionData, ~loadStartTime, ~onProgress=(curr, total, msg) =>
      progress(curr, total, msg)
    )
  )
  ->Promise.then(result => {
    if ownsLifecycle {
      switch result {
      | Ok(_) => OperationLifecycle.complete(opId, ~result="Success", ())
      | Error(msg) => OperationLifecycle.fail(opId, msg)
      }
    }
    Promise.resolve(result)
  })
  ->Promise.catch(err => {
    let (msg, _) = Logger.getErrorDetails(err)
    if ownsLifecycle {
      OperationLifecycle.fail(opId, msg)
    }
    Promise.resolve(Error(msg))
  })
}

/* --- Saver --- */

let createSavePackage = (
  state: state,
  ~signal=?,
  ~onProgress: option<onProgress>=?,
  ~opId: option<OperationLifecycle.operationId>=?,
): Promise.t<result<Blob.t, apiError>> => {
  let ownsLifecycle = switch opId {
  | Some(_) => false
  | None => true
  }

  let opId = switch opId {
  | Some(id) => id
  | None =>
    OperationLifecycle.start(
      ~type_=ProjectSave,
      ~scope=Blocking,
      ~phase="Preparing",
      ~meta=Logger.castToJson({
        "sceneCount": Array.length(
          SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
        ),
      }),
      (),
    )
  }

  let progress = (curr, total, msg) => {
    let pct = if total > 0 {
      Float.fromInt(curr) /. Float.fromInt(total) *. 100.0
    } else {
      0.0
    }
    OperationLifecycle.progress(opId, pct, ~message=msg, ())
    switch onProgress {
    | Some(cb) => cb(curr, total, msg)
    | None => ()
    }
  }
  progress(0, 100, "Preparing metadata...")

  let jsonStr = JsonCombinators.Json.stringify(encodeProjectFromState(state))
  let formData = FormData.newFormData()
  FormData.append(formData, "project_data", jsonStr)

  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  Belt.Array.forEachWithIndex(activeScenes, (_index, scene) => {
    switch scene.file {
    | File(f) => FormData.appendWithFilename(formData, "files", f, scene.name)
    | Blob(b) => FormData.appendWithFilename(formData, "files", b, scene.name)
    | Url(_) => ()
    }
  })
  state.sessionId->Option.forEach(id => FormData.append(formData, "session_id", id))

  // Include Logo in the package (handles Url variant for save/load cycle persistence)
  let appendLogoPromise = switch state.logo {
  | Some(File(f)) =>
    FormData.appendWithFilename(formData, "files", f, "logo_upload")
    Promise.resolve()
  | Some(Blob(b)) =>
    FormData.appendWithFilename(formData, "files", b, "logo_upload")
    Promise.resolve()
  | Some(Url(u)) if u != "" =>
    let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")
    let authToken = switch token {
    | Some(t) => Some(t)
    | None if Constants.isDebugBuild() => Some("dev-token")
    | None => None
    }
    ExporterUtils.fetchSceneUrlBlob(~url=u, ~authToken)
    ->Promise.then(result => {
      switch result {
      | Ok(blob) =>
        FormData.appendWithFilename(formData, "files", blob, "logo_upload")
        Logger.debug(
          ~module_="ProjectSystem",
          ~message="LOGO_URL_RESOLVED_FOR_SAVE",
          ~data=Some({"url": u}),
          (),
        )
      | Error(msg) =>
        Logger.warn(
          ~module_="ProjectSystem",
          ~message="LOGO_URL_FETCH_FAILED_FOR_SAVE",
          ~data=Some({"url": u, "error": msg}),
          (),
        )
      }
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      Logger.warn(
        ~module_="ProjectSystem",
        ~message="LOGO_URL_FETCH_EXCEPTION_FOR_SAVE",
        ~data=Some({"url": u}),
        (),
      )
      Promise.resolve()
    })
  | _ => Promise.resolve()
  }

  appendLogoPromise
  ->Promise.then(_ => {
    progress(10, 100, "Uploading to backend...")
    OperationLifecycle.progress(
      opId,
      10.0,
      ~message="Uploading to backend...",
      ~phase="Uploading",
      (),
    )

    RequestQueue.schedule(() => {
      AuthenticatedClient.requestWithRetry(
        Constants.backendUrl ++ "/api/project/save",
        ~method="POST",
        ~formData,
        ~signal?,
        ~operationId=opId,
        ~dedupeKey="project-save-op:" ++ opId,
        (),
      )->Promise.then(
        retryResult => {
          switch retryResult {
          | Retry.Success(response, _att) =>
            AuthenticatedClient.fetchBlob(response)->Promise.then(blob => Promise.resolve(Ok(blob)))
          | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
          }
        },
      )
    })
  })
  ->Promise.then(blobResult => {
    switch blobResult {
    | Ok(blob) =>
      progress(100, 100, "Package created!")
      if ownsLifecycle {
        OperationLifecycle.complete(opId, ~result="Saved", ())
      }
      Promise.resolve(Ok(blob))
    | Error(msg) =>
      if ownsLifecycle {
        OperationLifecycle.fail(opId, msg)
      }
      Promise.resolve(Error(msg))
    }
  })
  ->Promise.catch(err => {
    let (msg, _) = Logger.getErrorDetails(err)
    if ownsLifecycle {
      OperationLifecycle.fail(opId, msg)
    }
    Promise.resolve(Error(msg))
  })
}
