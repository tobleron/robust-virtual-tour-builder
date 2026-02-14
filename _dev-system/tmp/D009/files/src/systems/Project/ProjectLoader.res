open ReBindings
open Types

type onProgress = (int, int, string) => unit
type apiError = string

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
    switch JsonCombinators.Json.decode(
      projectData,
      ProjectValidator.validationReportWrapperDecoder,
    ) {
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
      let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")
      let finalToken = switch token {
      | Some(t) => t
      | None => "dev-token" // Professional fallback for local development automation
      }
      let tokenQuery = "?token=" ++ finalToken

      // Rebuild URLs for ALL scenes in the inventory (Active and Deleted)
      let allInventoryScenes =
        pd.inventory->Belt.Map.String.toArray->Belt.Array.map(((_id, entry)) => entry.scene)

      let validScenes = ProjectManagerUrl.rebuildSceneUrls(
        allInventoryScenes,
        ~sessionId,
        ~tokenQuery,
      )

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
      ProjectValidator.validateProjectStructure(response.projectData)
      ->Belt.Result.map(pd => (response.sessionId, pd))
      ->Promise.resolve
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.then(resultSessionData =>
    processLoadedProjectData(resultSessionData, ~loadStartTime, ~onProgress?)
  )
}
