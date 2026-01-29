/* src/systems/ProjectManager.res - Consolidated Project Manager System */

open ReBindings
open Types

// --- TYPES ---

type onProgress = (int, int, string) => unit
type apiError = string

// --- INTERNAL LOGIC ---

module Logic = {
  let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
    switch JSON.Decode.object(data) {
    | Some(obj) =>
      switch (Dict.get(obj, "scenes"), Dict.get(obj, "tourName")) {
      | (Some(_), Some(_)) => Ok(data)
      | _ => Error("Invalid project structure: missing scenes or tourName")
      }
    | None => Error("Invalid project data: expected object")
    }
  }

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
    let jsonStr = JSON.stringify(Obj.magic(projectData))
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
      Fetch.fetch(
        Constants.backendUrl ++ "/api/project/save",
        Fetch.requestInit(~method="POST", ~body=formData, ()),
      )
      ->Promise.then(BackendApi.handleResponse)
      ->Promise.then(resultRes => {
        switch resultRes {
        | Ok(res) => Fetch.blob(res)->Promise.then(blob => Promise.resolve(Ok(blob)))
        | Error(msg) => Promise.resolve(Error(msg))
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

  let processLoadedProjectData = (
    resultSessionData: result<(string, JSON.t), apiError>,
    ~loadStartTime: float,
    ~onProgress: option<onProgress>=?,
  ): Promise.t<BackendApi.apiResult<(string, JSON.t)>> => {
    let progress = (curr, total, msg) => {
      switch onProgress {
      | Some(cb) => cb(curr, total, msg)
      | None => ()
      }
    }
    switch resultSessionData {
    | Ok((sessionId, projectData)) =>
      progress(70, 100, "Resolving scenes...")
      let pd = JSON.Decode.object(projectData)->Option.getOr(Dict.make())
      let scenesArray = Dict.get(pd, "scenes")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
      let validScenes = Belt.Array.map(scenesArray, item => {
        let sceneDict = JSON.Decode.object(item)->Option.getOr(Dict.make())
        let name =
          Dict.get(sceneDict, "name")->Option.flatMap(JSON.Decode.string)->Option.getOr("unknown")
        let fileUrl =
          Constants.backendUrl ++
          "/api/project/" ++
          sessionId ++
          "/file/" ++
          encodeURIComponent(name)
        let newSceneDict = Dict.fromArray(Dict.toArray(sceneDict))
        Dict.set(newSceneDict, "file", JSON.Encode.string(fileUrl))
        Dict.set(newSceneDict, "originalFile", JSON.Encode.string(fileUrl))
        JSON.Encode.object(newSceneDict)
      })

      switch Dict.get(pd, "validationReport") {
      | Some(report) =>
        let r = Schemas.castToValidationReport(report)
        if r.brokenLinksRemoved > 0 {
          EventBus.dispatch(
            ShowNotification(
              "Project loaded. " ++
              Belt.Int.toString(r.brokenLinksRemoved) ++ " broken link(s) removed.",
              #Warning,
            ),
          )
        }
        if Array.length(r.orphanedScenes) > 0 {
          EventBus.dispatch(
            ShowNotification(
              "Warning: " ++
              Belt.Int.toString(Array.length(r.orphanedScenes)) ++ " orphaned scene(s) detected.",
              #Warning,
            ),
          )
        }
        r.errors->Belt.Array.forEach(error =>
          EventBus.dispatch(ShowNotification("Error: " ++ error, #Error))
        )
      | None => ()
      }

      let loadedProject = Dict.make()
      Dict.set(
        loadedProject,
        "tourName",
        Dict.get(pd, "tourName")->Option.getOr(JSON.Encode.string("Tour Name")),
      )
      Dict.set(loadedProject, "scenes", JSON.Encode.array(validScenes))
      Dict.set(
        loadedProject,
        "deletedSceneIds",
        Dict.get(pd, "deletedSceneIds")->Option.getOr(JSON.Encode.array([])),
      )
      Dict.set(
        loadedProject,
        "timeline",
        Dict.get(pd, "timeline")->Option.getOr(JSON.Encode.array([])),
      )
      Dict.set(loadedProject, "activeIndex", JSON.Encode.float(0.0))

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
      Promise.resolve(Ok((sessionId, JSON.Encode.object(loadedProject))))
    | Error(msg) => Promise.resolve(Error(msg))
    }
  }

  let loadProjectZip = (zipFile: File.t, ~onProgress: option<onProgress>=?) => {
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
    ->Promise.then(resultRes => {
      switch resultRes {
      | Ok(response) =>
        progress(50, 100, "Processing response...")
        validateProjectStructure(response.projectData)
        ->Belt.Result.map(pd => (response.sessionId, pd))
        ->Promise.resolve
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.then(resultSessionData =>
      processLoadedProjectData(resultSessionData, ~loadStartTime, ~onProgress?)
    )
  }
}

// --- FACADE ---

let saveProject = (state: state, ~onProgress: option<onProgress>=?) => {
  if Array.length(state.scenes) == 0 {
    Promise.resolve(false)
  } else {
    let tourName = if state.tourName == "" {
      "Virtual_Tour"
    } else {
      state.tourName
    }
    let safeName = String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")->String.toLowerCase
    let dateParts = String.split(Date.toISOString(Date.make()), "T")
    let dateStr = Belt.Array.get(dateParts, 0)->Option.getOr("unknown_date")
    let filename =
      "Saved_RMX_" ++ safeName ++ "_v" ++ Version.version ++ "_" ++ dateStr ++ ".vt.zip"

    let useFileHandle = %raw(`typeof window.showSaveFilePicker !== 'undefined'`)
    let handlePromise = if useFileHandle {
      DownloadSystem.getFileHandle(filename, "application/zip")
      ->Promise.then(h => Promise.resolve(Some(h)))
      ->Promise.catch(_ => Promise.resolve(None))
    } else {
      Promise.resolve(None)
    }

    let saveStartTime = Date.now()
    handlePromise->Promise.then(fileHandle => {
      Logic.createSavePackage(state, ~onProgress?)->Promise.then(resultRes => {
        switch resultRes {
        | Ok(blob) =>
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
        | Error(_) => Promise.resolve(false)
        }
      })
    })
  }
}

let loadProject = (zipFile: File.t, ~onProgress: option<onProgress>=?): Promise.t<
  BackendApi.apiResult<(string, JSON.t)>,
> => {
  Logic.loadProjectZip(zipFile, ~onProgress?)
}
