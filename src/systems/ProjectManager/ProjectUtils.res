open ReBindings
open Types

type apiError = string
type onProgress = (int, int, string) => unit

external asJson: 'a => JSON.t = "%identity"

type saveRecoveryContext = {
  sceneCount: option<int>,
  tourName: option<string>,
}

let saveRecoveryContextDecoder = JsonCombinators.Json.Decode.object((
  field
): saveRecoveryContext => {
  {
    sceneCount: field.optional("sceneCount", JsonCombinators.Json.Decode.int),
    tourName: field.optional("tourName", JsonCombinators.Json.Decode.string),
  }
})

let updateSaveContext = (
  ~journalId: string,
  ~state: state,
  ~stage: string,
  ~filename: option<string>=?,
  ~error: option<string>=?,
) => {
  OperationJournal.updateContext(
    journalId,
    asJson({
      "sceneCount": Array.length(state.scenes),
      "tourName": state.tourName,
      "stage": stage,
      "filename": filename->Option.getOr(""),
      "error": error->Option.getOr(""),
      "timestamp": Date.now(),
    }),
  )
}

let classifySaveError = (msg: string) => {
  let lowered = msg->String.toLowerCase
  if String.includes(msg, "AbortError") || String.includes(lowered, "aborted") {
    ("cancelled", "Save cancelled by user.")
  } else if String.includes(msg, "TimeoutError") || String.includes(lowered, "timed out") {
    ("timeout", "Save request timed out while communicating with backend. Please try again.")
  } else if (
    String.includes(lowered, "no space left") ||
    String.includes(lowered, "quota") ||
    String.includes(lowered, "disk")
  ) {
    ("disk", "Save failed because storage appears full or unavailable. Free up space and retry.")
  } else if (
    String.includes(lowered, "network") ||
    String.includes(lowered, "failed to fetch") ||
    String.includes(lowered, "httperror") ||
    String.includes(lowered, "http error")
  ) {
    ("network", "Save failed due to a backend/network issue. Please retry in a moment.")
  } else if (
    String.includes(lowered, "notallowederror") || String.includes(lowered, "securityerror")
  ) {
    ("permission", "Save failed because file write permission was rejected.")
  } else {
    ("unknown", "Save failed due to an unexpected error. Please retry.")
  }
}

let notifySaveFailure = (~message: string, ~details: string) => {
  NotificationManager.dispatch({
    id: "",
    importance: Error,
    context: Operation("project_save"),
    message,
    details: Some(details),
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(Error),
    dismissible: true,
    createdAt: Date.now(),
  })
}

/* Wrappers around ProjectSystem */
module Logic = {
  external asJson: 'a => JSON.t = "%identity"

  // Duplicated to match snapshot signature
  let validationReportWrapperDecoder = JsonCombinators.Json.Decode.object(field => {
    field.required("validationReport", JsonParsers.Shared.validationReport)
  })

  let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
    ProjectSystem.validateProjectStructure(data)
  }

  let createSavePackage = (state: state, ~signal=?, ~onProgress: option<onProgress>=?): Promise.t<
    result<Blob.t, apiError>,
  > => {
    ProjectSystem.createSavePackage(state, ~signal?, ~onProgress?)
  }

  let processLoadedProjectData = (
    resultSessionData: result<(string, JSON.t), apiError>,
    ~loadStartTime: float,
    ~onProgress: option<onProgress>=?,
  ): Promise.t<BackendApi.apiResult<(string, JSON.t)>> => {
    ProjectSystem.processLoadedProjectData(resultSessionData, ~loadStartTime, ~onProgress?)
  }

  let loadProjectZip = (
    zipFile: File.t,
    ~signal: option<BrowserBindings.AbortSignal.t>=?,
    ~onProgress: option<onProgress>=?,
  ) => {
    ProjectSystem.loadProjectZip(zipFile, ~signal?, ~onProgress?)
  }
}
