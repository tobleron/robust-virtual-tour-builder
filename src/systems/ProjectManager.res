open ReBindings
open Logger

type onProgress = ProjectUtils.onProgress
type apiError = ProjectUtils.apiError
type saveRecoveryContext = ProjectUtils.saveRecoveryContext

module Logic = ProjectUtils.Logic

/* --- Re-exports to maintain public API --- */
external asJson: 'a => JSON.t = "%identity"

let saveRecoveryContextDecoder = ProjectUtils.saveRecoveryContextDecoder
let updateSaveContext = ProjectUtils.updateSaveContext
let classifySaveError = ProjectUtils.classifySaveError
let notifySaveFailure = ProjectUtils.notifySaveFailure

let saveProject = ProjectSave.saveProject
let recoverSaveProject = ProjectRecovery.recoverSaveProject

let loadProject = (
  zipFile: File.t,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~onProgress: option<onProgress>=?,
  ~opId: option<OperationLifecycle.operationId>=?,
): Promise.t<BackendApi.apiResult<(string, JSON.t)>> => {
  let callMeta = Logger.castToJson({
    "filename": File.name(zipFile),
    "size": File.size(zipFile),
  })
  info(
    ~module_="ProjectManager",
    ~message="LOAD_PROJECT_CALLED",
    ~data=Some(callMeta),
    (),
  )

  Logic.loadProjectZip(zipFile, ~signal?, ~onProgress?, ~opId?)
  ->Promise.then(result => {
    let logData = Logger.castToJson({
      "status": switch result {
      | Ok(_) => "ok"
      | Error(_) => "error"
      },
    })
    info(
      ~module_="ProjectManager",
      ~message="LOAD_PROJECT_RESULT",
      ~data=Some(logData),
      (),
    )
    Promise.resolve(result)
  })
}
