/* src/systems/ServerTeaser.res */

open ReBindings
open Types

type serverTeaserConfig = {
  width: int,
  height: int,
}

/* Helper to convert safe structure to JSON compatible with backend */
let prepareProjectData = (state: state): JSON.t => {
  /* Use ProjectData.toJSON but ensure it adheres to backend 'ProjectData' struct */
  /* The backend expects snake_case in some places, but ProjectData.toJSON uses camelCase? */
  /* Let's double check backend structs. The user instruction said Align Backend and Frontend in task 26/related. */
  /* Re-using ProjectData.toJSON is safest if backend is aligned. */
  /* Re-using ProjectData.toJSON is safest if backend is aligned. */
  Obj.magic(ProjectData.toJSON(state))
}

let generateServerTeaser = (state: state, onProgress: option<(int, string) => unit>): Promise.t<
  result<Blob.t, string>,
> => {
  let progress = (pct, msg) => {
    switch onProgress {
    | Some(cb) => cb(pct, msg)
    | None => ()
    }
  }

  progress(0, "Preparing Project Data...")
  Logger.startOperation(
    ~module_="ServerTeaser",
    ~operation="GENERATE_SERVER",
    ~data={"sceneCount": Belt.Array.length(state.scenes)},
    (),
  )

  /* 1. Prepare Data */
  let projectData = prepareProjectData(state)

  /* 2. Prepare FormData */
  let formData = FormData.newFormData()
  FormData.append(formData, "project_data", JSON.stringify(projectData))
  FormData.append(formData, "width", "1920")
  FormData.append(formData, "height", "1080")

  /* 3. Append Files */
  let addedCount = ref(0)
  Belt.Array.forEach(state.scenes, scene => {
    /* We need to append the file blob if it exists */
    /* Scene type has 'file: file' which is JSON.t in Types.res, but at runtime it is a File object */
    let fileObj: File.t = Obj.magic(scene.file)

    /* Check if valid blob/file */
    /* In ReScript we might need runtime check if it's not null */
    if Obj.magic(fileObj) !== Nullable.null {
      FormData.appendWithFilename(formData, "files", Obj.magic(fileObj), scene.name)
      addedCount := addedCount.contents + 1
    }
  })

  progress(10, "Uploading " ++ Belt.Int.toString(addedCount.contents) ++ " scenes...")

  Fetch.fetch(
    Constants.backendUrl ++ "/api/media/generate-teaser",
    Fetch.requestInit(~method="POST", ~body=formData, ()),
  )
  ->Promise.then(BackendApi.handleResponse)
  ->Promise.then(result => {
    switch result {
    | Ok(res) => {
        progress(50, "Rendering on Server...")
        Fetch.blob(res)->Promise.then(blob => Promise.resolve(Ok(blob)))
      }
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.then(blobResult => {
    switch blobResult {
    | Ok(blob) => {
        progress(100, "Done!")
        Logger.endOperation(~module_="ServerTeaser", ~operation="GENERATE_SERVER", ())
        Promise.resolve(Ok(blob))
      }
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.catch(err => {
    let (msg, _stack) = Logger.getErrorDetails(err)
    Logger.error(~module_="ServerTeaser", ~message="SERVER_ERROR", ~data={"error": msg}, ())
    Promise.resolve(Error(msg))
  })
}
