/* src/systems/ProjectManager.res */

open ReBindings
open Types
open EventBus

// VersionData is accessed natively

type onProgress = (int, int, string) => unit
type apiError = string

external castToDict: JSON.t => dict<JSON.t> = "%identity"
external castToJson: 'a => JSON.t = "%identity"

/* --- PURE TRANSFORMATIONS --- */

let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
  let obj = castToDict(data)

  // Basic validation check
  switch (Dict.get(obj, "scenes"), Dict.get(obj, "tourName")) {
  | (Some(_), Some(_)) => Ok(data)
  | _ => Error("Invalid project structure: missing scenes or tourName")
  }
}

/* --- ASYNC OPERATIONS --- */

let createSavePackage = (state: state, ~onProgress: option<onProgress>=?): Promise.t<
  result<Blob.t, apiError>,
> => {
  let progress = (curr, total, msg) => {
    switch onProgress {
    | Some(cb) => cb(curr, total, msg)
    | None => ()
    }
  }

  progress(0, 100, "Preparing metadata...")

  let projectData = ProjectData.toJSON(state)
  let formData = FormData.newFormData()

  // Create project_data JSON string
  let jsonStr = JSON.stringify(castToJson(projectData))
  FormData.append(formData, "project_data", jsonStr)

  // Append files
  Belt.Array.forEachWithIndex(state.scenes, (_index, scene) => {
    // scene is of type Types.scene
    switch scene.file {
    | File(f) => FormData.appendWithFilename(formData, "files", f, scene.name)
    | Blob(b) => FormData.appendWithFilename(formData, "files", b, scene.name)
    | Url(_) => () // Skip URLs as they are reconstructed from backend
    }
  })

  progress(10, 100, "Uploading to backend...")

  Fetch.fetch(
    Constants.backendUrl ++ "/api/project/save",
    Fetch.requestInit(~method="POST", ~body=formData, ()),
  )
  ->Promise.then(BackendApi.handleResponse)
  ->Promise.then(Fetch.blob)
  ->Promise.then(blob => {
    progress(100, 100, "Package created!")
    Promise.resolve(Ok(blob))
  })
  ->Promise.catch(err => {
    let msg = switch JsExn.fromException(err) {
    | Some(e) => JsExn.message(e)->Option.getOr("Unknown error creating save package")
    | None => "Unknown error creating save package"
    }
    Promise.resolve(Error(msg))
  })
}

let loadProjectZip = (zipFile: File.t, ~onProgress: option<onProgress>=?): Promise.t<
  result<JSON.t, apiError>,
> => {
  let progress = (curr, total, msg) => {
    switch onProgress {
    | Some(cb) => cb(curr, total, msg)
    | None => ()
    }
  }

  progress(0, 100, "Uploading project...")

  let loadStartTime = Date.now()
  Logger.startOperation(
    ~module_="ProjectManager",
    ~operation="PROJECT_LOAD",
    ~data=Some({"filename": File.name(zipFile), "size": File.size(zipFile)}),
    (),
  )

  BackendApi.importProject(zipFile)
  ->Promise.then(result => {
    switch result {
    | Ok(response) =>
      progress(50, 100, "Processing response...")
      let sessionId = response.sessionId
      let projectData = response.projectData

      // Basic Validation
      switch validateProjectStructure(projectData) {
      | Error(e) => Promise.reject(JsError.throwWithMessage(e))
      | Ok(_) => Promise.resolve((sessionId, projectData))
      }
    | Error(msg) => Promise.reject(JsError.throwWithMessage(msg))
    }
  })
  ->Promise.then(((sessionId, projectData)) => {
    progress(70, 100, "Resolving scenes...")
    let pd = castToDict(projectData)
    let scenesArray = Dict.get(pd, "scenes")->Option.flatMap(JSON.Decode.array)->Option.getOr([])

    // Map scenes to point to backend URL
    let validScenes = Belt.Array.map(scenesArray, item => {
      let sceneDict = castToDict(item)
      let name =
        Dict.get(sceneDict, "name")
        ->Option.flatMap(JSON.Decode.string)
        ->Option.getOr("unknown")

      let fileUrl =
        Constants.backendUrl ++ "/api/session/" ++ sessionId ++ "/" ++ encodeURIComponent(name)

      // Clone scene object (shallow copy)
      let newSceneDict = Dict.fromArray(Dict.toArray(sceneDict))

      Dict.set(newSceneDict, "file", castToJson(fileUrl))
      Dict.set(newSceneDict, "originalFile", castToJson(fileUrl))

      // Note: tinyFile handling could be added here if backend generates it

      castToJson(newSceneDict)
    })

    // Extract validation report if present
    let validationReport: option<SharedTypes.validationReport> = switch Dict.get(
      pd,
      "validationReport",
    ) {
    | Some(report) => Some(Obj.magic(report)) // Keep one magic here as strict typing large structs is hard or need decoder
    | None => None
    }

    // Display validation notifications
    switch validationReport {
    | Some(report) => {
        if report.brokenLinksRemoved > 0 {
          EventBus.dispatch(
            ShowNotification(
              "Project loaded. " ++
              Belt.Int.toString(
                report.brokenLinksRemoved,
              ) ++ " broken link(s) were automatically removed.",
              #Warning,
            ),
          )
        }

        if Array.length(report.orphanedScenes) > 0 {
          EventBus.dispatch(
            ShowNotification(
              "Warning: " ++
              Belt.Int.toString(
                Array.length(report.orphanedScenes),
              ) ++ " orphaned scene(s) detected (no incoming links).",
              #Warning,
            ),
          )
        }

        if Array.length(report.unusedFiles) > 0 {
          Logger.warn(
            ~module_="ProjectManager",
            ~message="UNUSED_FILES_DETECTED",
            ~data=Some({"count": Array.length(report.unusedFiles)}),
            (),
          )
        }

        if Array.length(report.errors) > 0 {
          Belt.Array.forEach(report.errors, error => {
            EventBus.dispatch(ShowNotification("Error: " ++ error, #Error))
          })
        }
      }
    | None => ()
    }

    // Reconstruct the full project data object
    let loadedProject = Dict.make()
    Dict.set(
      loadedProject,
      "tourName",
      Dict.get(pd, "tourName")->Option.getOr(castToJson("Imported Tour")),
    )
    Dict.set(loadedProject, "scenes", castToJson(validScenes))
    Dict.set(
      loadedProject,
      "deletedSceneIds",
      Dict.get(pd, "deletedSceneIds")->Option.getOr(castToJson([])),
    )
    Dict.set(loadedProject, "timeline", Dict.get(pd, "timeline")->Option.getOr(castToJson([])))
    Dict.set(loadedProject, "activeIndex", castToJson(0))

    progress(100, 100, "Project Loaded!")
    Logger.endOperation(
      ~module_="ProjectManager",
      ~operation="PROJECT_LOAD",
      ~data=Some({
        "sceneCount": Array.length(validScenes),
        "durationMs": Date.now() -. loadStartTime,
      }),
      (),
    )
    Promise.resolve(Ok(castToJson(loadedProject)))
  })
  ->Promise.catch(err => {
    Logger.error(
      ~module_="ProjectManager",
      ~message="PROJECT_LOAD_FAILED",
      ~data=Some({"error": err}),
      (),
    )
    progress(0, 100, "Load Failed")

    let msg = switch JsExn.fromException(err) {
    | Some(e) => JsExn.message(e)->Option.getOr("Unknown load error")
    | None => "Unknown load error"
    }
    Promise.resolve(Error(msg))
  })
}

/* --- ORCHESTRATOR (Backward Compatibility / Convenience) --- */

let saveProject = (state: state, ~onProgress: option<onProgress>=?) => {
  if Array.length(state.scenes) == 0 {
    Logger.warn(
      ~module_="ProjectManager",
      ~message="SAVE_ABORTED",
      ~data=Some({"reason": "No scenes"}),
      (),
    )
    Promise.resolve(false)
  } else {
    let tourName = if state.tourName == "" {
      "Virtual_Tour"
    } else {
      state.tourName
    }
    let safeName = String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")
    let safeName = String.toLowerCase(safeName)
    let dateParts = String.split(Date.toISOString(Date.make()), "T")
    let dateStr = Belt.Array.get(dateParts, 0)->Option.getOr("unknown_date")
    let filename =
      "Saved_RMX_" ++ safeName ++ "_v" ++ VersionData.version ++ "_" ++ dateStr ++ ".vt.zip"

    let useFileHandle = %raw(`typeof window.showSaveFilePicker !== 'undefined'`)

    // Acquire Handle
    let handlePromise = if useFileHandle {
      DownloadSystem.getFileHandle(filename, "application/zip")
      ->Promise.then(h => Promise.resolve(Some(h)))
      ->Promise.catch(_ => Promise.resolve(None)) // Ignore aborts silently or return None
    } else {
      Promise.resolve(None)
    }

    Logger.startOperation(
      ~module_="ProjectManager",
      ~operation="PROJECT_SAVE",
      ~data=Some({"tourName": tourName, "sceneCount": Array.length(state.scenes)}),
      (),
    )
    let saveStartTime = Date.now()

    handlePromise->Promise.then(fileHandle => {
      createSavePackage(state, ~onProgress?)->Promise.then(result => {
        switch result {
        | Ok(blob) =>
          Logger.info(
            ~module_="ProjectManager",
            ~message="PACKAGE_CREATED",
            ~data=Some({"size": Blob.size(blob)}),
            (),
          )

          // Save to disk
          if useFileHandle {
            switch fileHandle {
            | Some(h) =>
              DownloadSystem.writeFileToHandle(h, blob)->Promise.then(() => Promise.resolve(true))
            | None =>
              DownloadSystem.saveBlob(blob, filename)
              Promise.resolve(true)
            }
          } else {
            DownloadSystem.saveBlob(blob, filename)
            Promise.resolve(true)
          }->Promise.then(
            success => {
              if success {
                Logger.endOperation(
                  ~module_="ProjectManager",
                  ~operation="PROJECT_SAVE",
                  ~data=Some({"durationMs": Date.now() -. saveStartTime}),
                  (),
                )
              }
              Promise.resolve(success)
            },
          )
        | Error(msg) =>
          Logger.error(
            ~module_="ProjectManager",
            ~message="PROJECT_SAVE_FAILED",
            ~data=Some({"error": msg}),
            (),
          )
          Promise.resolve(false)
        }
      })
    })
  }
}

// Wrapper to match old load signature mostly, but Sidebar will likely need update if it expects strict promise
// Old: loadProject(zipFile, onProgress) -> Promise(projectData)
// New: returns Promise(result)
// But to keep existing calls working (if they expect promise rejection on fail):
let loadProject = (zipFile: File.t, ~onProgress: option<onProgress>=?): Promise.t<JSON.t> => {
  loadProjectZip(zipFile, ~onProgress?)->Promise.then(result => {
    switch result {
    | Ok(data) => Promise.resolve(data)
    | Error(msg) => Promise.reject(JsError.throwWithMessage(msg))
    }
  })
}
