/* src/systems/ProjectManager.res */

open ReBindings
open Types
open EventBus

@module("../version.js") external version: string = "VERSION"

type onProgress = (int, int, string) => unit
type apiError = string

/* --- PURE TRANSFORMATIONS --- */

let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
  let obj = (Obj.magic(data): {..})

  // Basic validation check
  if (
    Obj.magic(obj["scenes"]) == Nullable.undefined ||
      Obj.magic(obj["tourName"]) == Nullable.undefined
  ) {
    Error("Invalid project structure: missing scenes or tourName")
  } else {
    Ok(data)
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
  let jsonStr = JSON.stringify(Obj.magic(projectData))
  FormData.append(formData, "project_data", jsonStr)

  // Append files
  Belt.Array.forEachWithIndex(state.scenes, (_index, scene) => {
    let sceneObj: {..} = Obj.magic(scene)
    let file = sceneObj["file"]

    // Check if file is actually a Blob/File object
    if Nullable.make(file) != Nullable.null {
      let fileType: string = %raw("typeof file")
      if fileType != "string" {
        // It's a binary object (File/Blob)
        FormData.appendWithFilename(formData, "files", file, scene.name)
      } else {
        Logger.warn(
          ~module_="ProjectManager",
          ~message="INVALID_FILE_TYPE",
          ~data=Some({"scene": scene.name, "type": fileType}),
          (),
        )
      }
    }
  })

  progress(10, 100, "Uploading to backend...")

  Fetch.fetch(
    Constants.backendUrl ++ "/save-project",
    {
      method: "POST",
      body: formData,
      headers: Nullable.null,
    },
  )
  ->Promise.then(BackendApi.handleResponse)
  ->Promise.then(Fetch.blob)
  ->Promise.then(blob => {
    progress(100, 100, "Package created!")
    Promise.resolve(Ok(blob))
  })
  ->Promise.catch(err => {
    let msg = switch (Obj.magic(err): {..})["message"] {
    | Some(m) => m
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
  ->Promise.then(response => {
    progress(50, 100, "Processing response...")
    let sessionId = response.sessionId
    let projectData = response.projectData

    // Basic Validation
    switch validateProjectStructure(projectData) {
    | Error(e) => Promise.reject(JsError.throwWithMessage(e))
    | Ok(_) => Promise.resolve((sessionId, projectData))
    }
  })
  ->Promise.then(((sessionId, projectData)) => {
    progress(70, 100, "Resolving scenes...")
    let pd: {..} = Obj.magic(projectData)
    let scenesArray: array<JSON.t> = pd["scenes"]

    // Map scenes to point to backend URL
    let validScenes = Belt.Array.map(scenesArray, item => {
      let scene: {..} = Obj.magic(item)
      let name: string = scene["name"]
      
      let fileUrl = Constants.backendUrl ++ "/api/session/" ++ sessionId ++ "/" ++ encodeURIComponent(name)
      
      // Clone scene object (shallow copy)
      let newScene = Object.assign(Object.make(), scene)
      let newSceneDict: {..} = Obj.magic(newScene)
      
      newSceneDict["file"] = fileUrl
      newSceneDict["originalFile"] = fileUrl
      
      // Note: tinyFile handling could be added here if backend generates it
      
      newSceneDict
    })

    // Extract validation report if present
    let validationReport: option<BackendApi.validationReport> = switch Nullable.toOption(
      pd["validationReport"],
    ) {
    | Some(report) => Some(Obj.magic(report))
    | None => None
    }

    // Display validation notifications
    switch validationReport {
    | Some(report) => {
        if report.brokenLinksRemoved > 0 {
          EventBus.dispatch(ShowNotification(
            "Project loaded. " ++
            Belt.Int.toString(
              report.brokenLinksRemoved,
            ) ++ " broken link(s) were automatically removed.",
            #Warning,
          ))
        }

        if Array.length(report.orphanedScenes) > 0 {
          EventBus.dispatch(ShowNotification(
            "Warning: " ++
            Belt.Int.toString(
              Array.length(report.orphanedScenes),
            ) ++ " orphaned scene(s) detected (no incoming links).",
            #Warning,
          ))
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
          Belt.Array.forEach(
            report.errors,
            error => {
              EventBus.dispatch(ShowNotification("Error: " ++ error, #Error))
            },
          )
        }
      }
    | None => ()
    }

    // Reconstruct the full project data object
    let loadedProject = {
      "tourName": switch Nullable.toOption(pd["tourName"]) {
      | Some(n) => n
      | None => "Imported Tour"
      },
      "scenes": validScenes,
      "deletedSceneIds": switch Nullable.toOption(pd["deletedSceneIds"]) {
      | Some(a) => a
      | None => []
      },
      "timeline": switch Nullable.toOption(pd["timeline"]) {
      | Some(t) => t
      | None => []
      },
      "activeIndex": 0,
    }

    progress(100, 100, "Project Loaded!")
    Logger.endOperation(
      ~module_="ProjectManager",
      ~operation="PROJECT_LOAD",
      ~data=Some({
        "sceneCount": Array.length(validScenes), 
        "durationMs": Date.now() -. loadStartTime
      }),
      (),
    )
    Promise.resolve(Ok((Obj.magic(loadedProject): JSON.t)))
  })
  ->Promise.catch(err => {
    Logger.error(~module_="ProjectManager", ~message="PROJECT_LOAD_FAILED", ~data=Some({"error": err}), ())
    progress(0, 100, "Load Failed")

    let msg = switch (Obj.magic(err): {..})["message"] {
    | Some(m) => m
    | None => "Unknown load error"
    }
    Promise.resolve(Error(msg))
  })
}

/* --- ORCHESTRATOR (Backward Compatibility / Convenience) --- */

let saveProject = (state: state, ~onProgress: option<onProgress>=?) => {
  if Array.length(state.scenes) == 0 {
    Logger.warn(~module_="ProjectManager", ~message="SAVE_ABORTED", ~data=Some({"reason": "No scenes"}), ())
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
    let dateStr = Belt.Array.get(dateParts, 0)->Belt.Option.getWithDefault("unknown_date")
    let filename = "Saved_RMX_" ++ safeName ++ "_v" ++ version ++ "_" ++ dateStr ++ ".vt.zip"

    let useFileHandle = Obj.magic(Window.window)["showSaveFilePicker"] != undefined

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
          Logger.info(~module_="ProjectManager", ~message="PACKAGE_CREATED", ~data=Some({"size": Blob.size(blob)}), ())
          
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
          }
          ->Promise.then(success => {
            if success {
               Logger.endOperation(
                ~module_="ProjectManager",
                ~operation="PROJECT_SAVE",
                ~data=Some({"durationMs": Date.now() -. saveStartTime}),
                (),
              )
            }
            Promise.resolve(success)
          })
        | Error(msg) =>
          Logger.error(~module_="ProjectManager", ~message="PROJECT_SAVE_FAILED", ~data=Some({"error": msg}), ())
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
