open ReBindings
open Types

type onProgress = (int, int, string) => unit
type apiError = string

let createSavePackage = (state: state, ~signal=?, ~onProgress: option<onProgress>=?): Promise.t<
  result<Blob.t, apiError>,
> => {
  let progress = (curr, total, msg) => {
    switch onProgress {
    | Some(cb) => cb(curr, total, msg)
    | None => ()
    }
  }
  progress(0, 100, "Preparing metadata...")

  let project: Types.project = {
    tourName: state.tourName,
    scenes: state.scenes,
    inventory: state.inventory,
    sceneOrder: state.sceneOrder,
    lastUsedCategory: state.lastUsedCategory,
    exifReport: state.exifReport,
    sessionId: state.sessionId,
    deletedSceneIds: state.deletedSceneIds,
    timeline: state.timeline,
    logo: state.logo,
  }

  let jsonStr = JsonCombinators.Json.stringify(JsonParsers.Encoders.project(project))
  let formData = FormData.newFormData()
  FormData.append(formData, "project_data", jsonStr)

  Belt.Array.forEachWithIndex(state.scenes, (_index, scene) => {
    switch scene.file {
    | File(f) => FormData.appendWithFilename(formData, "files", f, scene.name)
    | Blob(b) => FormData.appendWithFilename(formData, "files", b, scene.name)
    | Url(_) => ()
    }
  })
  state.sessionId->Option.forEach(id => FormData.append(formData, "session_id", id))

  progress(10, 100, "Uploading to backend...")
  RequestQueue.schedule(() => {
    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/save",
      ~method="POST",
      ~formData,
      ~signal?,
      (),
    )->Promise.then(retryResult => {
      switch retryResult {
      | Retry.Success(response, _att) =>
        AuthenticatedClient.fetchBlob(response)->Promise.then(blob => Promise.resolve(Ok(blob)))
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
  })
  ->Promise.then(blobResult => {
    switch blobResult {
    | Ok(blob) =>
      progress(100, 100, "Package created!")
      Promise.resolve(Ok(blob))
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.catch(err => {
    let (msg, _) = Logger.getErrorDetails(err)
    Promise.resolve(Error(msg))
  })
}
