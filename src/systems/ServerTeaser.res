/* src/systems/ServerTeaser.res */
open ReBindings

open Types

external anyToUnknown: 'a => 'b = "%identity"

let generateServerTeaser = (state: state, onProgress) => {
  let progress = (p, m) => onProgress->Option.forEach(cb => cb(p, m))
  progress(0, "Preparing Project Data...")
  let project: Types.project = {
    tourName: state.tourName,
    scenes: state.scenes,
    lastUsedCategory: state.lastUsedCategory,
    exifReport: state.exifReport,
    sessionId: state.sessionId,
    deletedSceneIds: state.deletedSceneIds,
    timeline: state.timeline,
  }
  // CSP SAFE FIX
  let jsonStr = JSON.stringifyAny(project)->Option.getOr("{}")
  let formData = FormData.newFormData()
  FormData.append(formData, "project_data", jsonStr)
  FormData.append(formData, "width", "1920")
  FormData.append(formData, "height", "1080")
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
  RequestQueue.schedule(() => {
    Fetch.fetch(
      Constants.backendUrl ++ "/api/media/generate-teaser",
      Fetch.requestInit(~method="POST", ~body=formData, ()),
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
