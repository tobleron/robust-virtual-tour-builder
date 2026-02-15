/* src/systems/ProjectSystem.res - Consolidated Project System */
open ReBindings
open Types

type onProgress = (int, int, string) => unit
type apiError = string

/* --- Validator --- */

let validationReportWrapperDecoder = JsonCombinators.Json.Decode.object(field => {
  field.required("validationReport", JsonParsers.Shared.validationReport)
})

let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
  switch JsonCombinators.Json.decode(data, JsonParsers.Domain.project) {
  | Ok(_) => Ok(data)
  | Error(e) => Error("Invalid project structure: " ++ e)
  }
}

/* --- Loader --- */

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

    // Check validation report
    switch JsonCombinators.Json.decode(projectData, validationReportWrapperDecoder) {
    | Ok(r) =>
      if r.brokenLinksRemoved > 0 {
        NotificationManager.dispatch({
          id: "",
          importance: Warning,
          context: Operation("project_manager"),
          message: "Project loaded. " ++
          Belt.Int.toString(r.brokenLinksRemoved) ++ " broken link(s) removed.",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Warning),
          dismissible: true,
          createdAt: Date.now(),
        })
      }
      if Array.length(r.orphanedScenes) > 0 {
        NotificationManager.dispatch({
          id: "",
          importance: Warning,
          context: Operation("project_manager"),
          message: "Warning: " ++
          Belt.Int.toString(Array.length(r.orphanedScenes)) ++ " orphaned scene(s) detected.",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Warning),
          dismissible: true,
          createdAt: Date.now(),
        })
      }
      r.errors->Belt.Array.forEach(error =>
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: Operation("project_manager"),
          message: "Error: " ++ error,
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
      )
    | Error(_) => ()
    }

    switch JsonCombinators.Json.decode(projectData, JsonParsers.Domain.project) {
    | Ok(pd) =>
      // Rebuild URLs for ALL scenes in the inventory (Active and Deleted)
      let allInventoryScenes =
        pd.inventory->Belt.Map.String.toArray->Belt.Array.map(((_id, entry)) => entry.scene)

      let validScenes = ProjectManagerUrl.rebuildSceneUrls(allInventoryScenes, ~sessionId)

      // Sync valid scenes back into inventory, preserving their original status
      let updatedInventory = validScenes->Belt.Array.reduce(pd.inventory, (acc, s) => {
        switch acc->Belt.Map.String.get(s.id) {
        | Some(entry) => acc->Belt.Map.String.set(s.id, {...entry, scene: s})
        | None => acc // Should not happen if we rebuilt from inventory
        }
      })

      // Ensure sceneOrder is populated from validScenes if it was empty
      let finalOrder = if Array.length(pd.sceneOrder) > 0 {
        pd.sceneOrder
      } else {
        validScenes->Belt.Array.map(s => s.id)
      }

      // Filter active scenes for the legacy array and order verification
      let resolvedActiveScenes = finalOrder->Belt.Array.keepMap(id => {
        switch updatedInventory->Belt.Map.String.get(id) {
        | Some({scene, status: Active}) => Some(scene)
        | _ => None
        }
      })

      let loadedProject: Types.project = {
        ...pd,
        scenes: resolvedActiveScenes,
        inventory: updatedInventory,
        sceneOrder: finalOrder,
      }

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
      Promise.resolve(Ok((sessionId, JsonParsers.Encoders.project(loadedProject))))
    | Error(e) => Promise.resolve(Error("Failed to parse project data: " ++ e))
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

/* --- Saver --- */

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
