open ReBindings

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
): Promise.t<BackendApi.apiResult<(string, JSON.t)>> => {
  Logic.loadProjectZip(zipFile, ~signal?, ~onProgress?)
}
