/* src/systems/ServerTeaser.res */
open ReBindings

open Types

external anyToUnknown: 'a => 'b = "%identity"

let generateServerTeaser = (
  state: state,
  format: string,
  onProgress,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
) => {
  let boolJson = b => b ? "true" : "false"
  let progress = (p, m) => onProgress->Option.forEach(cb => cb(p, m))
  progress(0, "Preparing Project Data...")
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

  // Encoded with strict combinators
  let jsonStr = JsonCombinators.Json.stringify(JsonParsers.Encoders.project(project))
  let formData = FormData.newFormData()
  FormData.append(formData, "project_data", jsonStr)
  FormData.append(formData, "format", format)
  FormData.append(formData, "width", "1920")
  FormData.append(formData, "height", "1080")
  let motionProfileJson =
    "{\"skipAutoForward\":" ++
    boolJson(Constants.Teaser.HeadlessMotion.skipAutoForward) ++
    ",\"startAtWaypoint\":" ++
    boolJson(Constants.Teaser.HeadlessMotion.startAtWaypoint) ++
    ",\"includeIntroPan\":" ++
    boolJson(Constants.Teaser.HeadlessMotion.includeIntroPan) ++ "}"
  FormData.append(formData, "motion_profile", motionProfileJson)
  let added = ref(0)
  state.scenes->Belt.Array.forEach(s => {
    switch s.file {
    | File(f) =>
      FormData.appendWithFilename(formData, "files", f, s.name)
      added := added.contents + 1
    | Blob(f) =>
      FormData.appendWithFilename(formData, "files", f, s.name)
      added := added.contents + 1
    | _ => ()
    }
  })
  progress(10, "Uploading " ++ Belt.Int.toString(added.contents) ++ " scenes...")
  let headers = Dict.make()
  let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")
  let finalToken = switch token {
  | Some(t) => Some(t)
  | None if Constants.isDebugBuild() => Some("dev-token")
  | None => None
  }
  finalToken->Option.forEach(t => {
    Dict.set(headers, "Authorization", "Bearer " ++ t)
    // Keep media GET routes compatible with cookie-based auth middleware.
    let cookieValue = "auth_token=" ++ t ++ "; path=/; SameSite=Strict"
    let _ = %raw(`(val) => { document.cookie = val }`)(cookieValue)
  })

  RequestQueue.schedule(() => {
    Fetch.fetch(
      Constants.backendUrl ++ "/api/media/generate-teaser",
      Fetch.requestInit(~method="POST", ~body=formData, ~headers, ~signal?, ()),
    )
    ->Promise.then(BackendApi.handleResponse)
    ->Promise.then(resResult => {
      switch resResult {
      | Ok(res) =>
        progress(50, "Rendering on Server...")
        Fetch.blob(res)->Promise.then(blob => Promise.resolve(Ok(blob)))
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
  })
  ->Promise.then(blobRes => {
    switch blobRes {
    | Ok(blob) =>
      progress(100, "Done!")
      Promise.resolve(Ok(blob))
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.catch(err => {
    let (msg, _) = Logger.getErrorDetails(err)
    Promise.resolve(Error(msg))
  })
}

module Server = {
  let generateServerTeaser = generateServerTeaser
}
