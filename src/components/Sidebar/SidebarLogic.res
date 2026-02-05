// @efficiency-role: ui-component

external asDynamic: 'a => {..} = "%identity"

module SidebarTypes = {
  type procState = {
    active: bool,
    progress: float,
    message: string,
    phase: string,
    error: bool,
  }

  type file = ReBindings.File.t

  type processingPayload = {
    "active": bool,
    "progress": float,
    "message": string,
    "phase": string,
    "error": bool,
    "onCancel": unit => unit,
  }
}

open ReBindings

let updateProgress = (~onCancel=() => (), pct, msg, active, phase) => {
  EventBus.dispatch(
    UpdateProcessing({
      "active": active,
      "progress": pct,
      "message": msg,
      "phase": phase,
      "error": false,
      "onCancel": onCancel,
    }),
  )
  if active {
    GlobalStateBridge.dispatch(DispatchAppFsmEvent(UploadProgress(pct)))
  }
}

let performUpload = async files => {
  let fileArray = JsHelpers.from(files)

  try {
    let result: UploadTypes.processResult = await UploadProcessor.processUploads(
      fileArray,
      Some(
        (pct, msg, isProc, phase) => {
          updateProgress(pct, msg, isProc, phase)
        },
      ),
    )

    let qualityResults = result.qualityResults
    let report = result.report

    GlobalStateBridge.dispatch(DispatchAppFsmEvent(UploadComplete(report, qualityResults)))
    UploadReport.show(report, qualityResults)
    EventBus.dispatch(ShowNotification("Upload Complete", #Success, None))
  } catch {
  | JsExn(obj) =>
    let msg = switch JsExn.message(obj) {
    | Some(m) => m
    | None => "Unknown error"
    }
    let data = Some(
      Logger.castToJson({
        "error": msg,
        "stack": JsExn.stack(obj)->Option.getOr(""),
      }),
    )
    GlobalStateBridge.dispatch(
      Actions.DispatchAppFsmEvent(CriticalErrorOccurred("Upload Failed: " ++ msg)),
    )
    EventBus.dispatch(ShowNotification("Upload failed: " ++ msg, #Error, data))
    updateProgress(0.0, "Error: " ++ msg, false, "")
  | _ =>
    GlobalStateBridge.dispatch(
      Actions.DispatchAppFsmEvent(CriticalErrorOccurred("Unknown Upload Error")),
    )
  }
}

let handleUpload = async filesOpt => {
  switch filesOpt {
  | Some(files) if FileList.length(files) > 0 =>
    let state = GlobalStateBridge.getState()
    // Guard: Only start if not already blocking
    switch state.appMode {
    | SystemBlocking(Uploading(_))
    | SystemBlocking(Summary(_))
    | SystemBlocking(ProjectLoading(_)) =>
      EventBus.dispatch(
        ShowNotification("Please wait for current operation to finish", #Warning, None),
      )
    | _ =>
      GlobalStateBridge.dispatch(DispatchAppFsmEvent(StartUpload))
      EventBus.dispatch(ShowNotification("Upload Started...", #Info, None))
      await performUpload(files)
    }
  | _ => ()
  }
}

let handleLoadProject = async (filesOpt, dispatch, _sceneCount, target) => {
  switch filesOpt {
  | Some(files) if FileList.length(files) > 0 =>
    SessionStore.clearState()
    try {
      switch FileList.item(files, 0) {
      | Some(file) =>
        dispatch(Actions.DispatchAppFsmEvent(StartProjectLoad({name: File.name(file)})))
        updateProgress(0.0, "Loading Project...", true, "Loading")

        Logger.startOperation(
          ~module_="Sidebar",
          ~operation="PROJECT_LOAD",
          ~data={
            "filename": File.name(file),
            "size": File.size(file),
          },
          (),
        )
        let projectDataResult = await ProjectManager.loadProject(file, ~onProgress=(
          pct,
          _t,
          msg,
        ) => {
          updateProgress(pct->Int.toFloat, msg, true, "Loading")
        })

        switch projectDataResult {
        | Ok((sessionId, projectData)) => {
            ViewerSystem.resetState()
            dispatch(Actions.SetSessionId(sessionId))
            dispatch(Actions.LoadProject(projectData))
            UploadReport.showFromProjectData(projectData)

            Logger.endOperation(
              ~module_="Sidebar",
              ~operation="PROJECT_LOAD",
              ~data={"success": true},
              (),
            )
            updateProgress(100.0, "Done", false, "")
            dispatch(Actions.DispatchAppFsmEvent(ProjectLoadComplete))
            EventBus.dispatch(ShowNotification("Project Loaded", #Success, None))
          }
        | Error(msg) => {
            dispatch(Actions.DispatchAppFsmEvent(ProjectLoadError(msg)))
            EventBus.dispatch(
              ShowNotification(
                "Load failed: " ++ msg,
                #Error,
                Some(Logger.castToJson({"error": msg})),
              ),
            )
            updateProgress(0.0, "Error: " ++ msg, false, "")
            Logger.endOperation(
              ~module_="Sidebar",
              ~operation="PROJECT_LOAD",
              ~data={"success": false, "error": msg},
              (),
            )
          }
        }
      | None => ()
      }
    } catch {
    | _ => updateProgress(0.0, "Error", false, "")
    }
    asDynamic(target)["value"] = ""
  | _ => ()
  }
}

let getProjectData = (state: Types.state) => {
  let project: Types.project = {
    tourName: state.tourName,
    scenes: state.scenes,
    lastUsedCategory: state.lastUsedCategory,
    exifReport: state.exifReport,
    sessionId: state.sessionId,
    deletedSceneIds: state.deletedSceneIds,
    timeline: state.timeline,
  }
  JsonParsers.Encoders.project(project)
}

let handleDeleteScene = async (index: int) => {
  let _ = await OptimisticAction.execute(~action=Actions.DeleteScene(index), ~apiCall=() => {
    let state = GlobalStateBridge.getState()
    switch state.sessionId {
    | Some(sid) =>
      let projectData = getProjectData(state)
      Api.ProjectApi.saveProject(sid, projectData)
    | None => Promise.resolve(Error("No active session"))
    }
  })
}

let handleExport = async (scenes, ~signal, ~onCancel) => {
  GlobalStateBridge.dispatch(DispatchAppFsmEvent(StartExport))
  updateProgress(~onCancel, 0.0, "Exporting...", true, "Export")
  EventBus.dispatch(ShowNotification("Export Started...", #Info, None))
  try {
    let exportResult = await Exporter.exportTour(
      scenes,
      ~signal,
      Some((pct, _, msg) => updateProgress(~onCancel, pct, msg, true, "Export")),
    )
    switch exportResult {
    | Ok() => {
        EventBus.dispatch(ShowNotification("Export complete", #Success, None))
        updateProgress(100.0, "Done", false, "")
        GlobalStateBridge.dispatch(DispatchAppFsmEvent(ExportComplete))
      }
    | Error("CANCELLED") => {
        Logger.info(~module_="SidebarLogic", ~message="EXPORT_CANCELLED_HANDLED", ())
        updateProgress(0.0, "Cancelled", false, "")
        GlobalStateBridge.dispatch(DispatchAppFsmEvent(ExportComplete))
      }
    | Error(msg) => {
        GlobalStateBridge.dispatch(DispatchAppFsmEvent(ExportError(msg)))
        EventBus.dispatch(
          ShowNotification(
            "Export failed: " ++ msg,
            #Error,
            Some(Logger.castToJson({"error": msg})),
          ),
        )
        updateProgress(0.0, "Error: " ++ msg, false, "")
      }
    }
  } catch {
  | _ =>
    GlobalStateBridge.dispatch(DispatchAppFsmEvent(ExportError("Unexpected Error")))
    updateProgress(0.0, "Error", false, "")
  }
}
