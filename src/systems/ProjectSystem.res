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

let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> =>
  ProjectSystemLoad.validateProjectStructure(data)

let notifyProjectValidationWarnings = (report: SharedTypes.validationReport) =>
  ProjectSystemLoad.notifyProjectValidationWarnings(report)

let verifyProjectLoadPolicy = (
  projectData: JSON.t,
): result<option<SharedTypes.validationReport>, apiError> =>
  ProjectSystemLoad.verifyProjectLoadPolicy(projectData, ~validationReportWrapperDecoder)

let mergeValidationReport: (
  JSON.t,
  JSON.t,
) => JSON.t = %raw(`(projectJson, validationReport) => ({...projectJson, validationReport})`)

let encodeValidationReport = (report: SharedTypes.validationReport): JSON.t =>
  ProjectSystemLoad.encodeValidationReport(report)

/* --- Loader --- */

let processLoadedProjectData = (
  resultSessionData: result<(string, JSON.t), apiError>,
  ~loadStartTime: float,
  ~onProgress: option<onProgress>=?,
): Promise.t<BackendApi.apiResult<(string, JSON.t)>> => {
  ProjectSystemLoad.processLoadedProjectData(
    resultSessionData,
    ~loadStartTime,
    ~onProgress?,
    ~verifyProjectLoadPolicy,
    ~notifyProjectValidationWarnings,
    ~mergeValidationReport,
    ~encodeValidationReport,
  )
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
  ProjectSystemSave.createSavePackage(
    state,
    ~encodeProjectFromState,
    ~signal?,
    ~onProgress?,
    ~opId?,
  )
}
