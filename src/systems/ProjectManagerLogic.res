/* src/systems/ProjectManagerLogic.res */

open ReBindings
open Types
open EventBus
open ProjectManagerTypes

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

  switch state.sessionId {
  | Some(id) => FormData.append(formData, "session_id", id)
  | None => ()
  }

  progress(10, 100, "Uploading to backend...")

  RequestQueue.schedule(() => {
    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/save",
      Fetch.requestInit(~method="POST", ~body=formData, ()),
    )
    ->Promise.then(BackendApi.handleResponse)
    ->Promise.then(result => {
      switch result {
      | Ok(res) => Fetch.blob(res)->Promise.then(blob => Promise.resolve(Ok(blob)))
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
  })
  ->Promise.then(blobResult => {
    switch blobResult {
    | Ok(blob) => {
        progress(100, 100, "Package created!")
        Promise.resolve(Ok(blob))
      }
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.catch(err => {
    let (msg, stack) = Logger.getErrorDetails(err)
    Logger.error(
      ~module_="ProjectManager",
      ~message="CREATE_SAVE_PACKAGE_FAILED",
      ~data={"error": msg, "stack": stack},
      (),
    )
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
  | Ok((sessionId, projectData)) => {
      progress(70, 100, "Resolving scenes...")
      let pd = JSON.Decode.object(projectData)->Option.getOr(Dict.make())
      let scenesArray = Dict.get(pd, "scenes")->Option.flatMap(JSON.Decode.array)->Option.getOr([])

      let validScenes = Belt.Array.map(scenesArray, item => {
        let sceneDict = JSON.Decode.object(item)->Option.getOr(Dict.make())
        let name =
          Dict.get(sceneDict, "name")
          ->Option.flatMap(JSON.Decode.string)
          ->Option.getOr("unknown")

        let fileUrl =
          Constants.backendUrl ++ "/api/session/" ++ sessionId ++ "/" ++ encodeURIComponent(name)

        let newSceneDict = Dict.fromArray(Dict.toArray(sceneDict))

        Dict.set(newSceneDict, "file", JSON.Encode.string(fileUrl))
        Dict.set(newSceneDict, "originalFile", JSON.Encode.string(fileUrl))

        JSON.Encode.object(newSceneDict)
      })

      let validationReport: option<SharedTypes.validationReport> = switch Dict.get(
        pd,
        "validationReport",
      ) {
      | Some(report) => Some(JsonTypes.castToValidationReport(report))
      | None => None
      }

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
    }
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
  ->Promise.then(result => {
    switch result {
    | Ok(response) =>
      progress(50, 100, "Processing response...")
      let sessionId = response.sessionId
      let projectData = response.projectData

      switch validateProjectStructure(projectData) {
      | Error(e) => Promise.resolve(Error(e))
      | Ok(_) => Promise.resolve(Ok((sessionId, projectData)))
      }
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.then(resultSessionData =>
    processLoadedProjectData(resultSessionData, ~loadStartTime, ~onProgress?)
  )
}
