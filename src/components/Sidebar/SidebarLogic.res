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

let updateProgress = (
  ~dispatch: Actions.action => unit,
  ~onCancel=() => (),
  pct,
  msg,
  active,
  phase,
) => {
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
    dispatch(DispatchAppFsmEvent(UploadProgress(pct)))
  }
}

let performUpload = async (
  files,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let fileArray = JsHelpers.from(files)

  try {
    let result: UploadTypes.processResult = await UploadProcessor.processUploads(
      fileArray,
      Some(
        (pct, msg, isProc, phase) => {
          updateProgress(~dispatch, pct, msg, isProc, phase)
        },
      ),
      ~getState,
      ~dispatch,
    )

    let qualityResults = result.qualityResults
    let report = result.report

    dispatch(DispatchAppFsmEvent(UploadComplete(report, qualityResults)))
    UploadReport.show(report, qualityResults, ~getState, ~dispatch)
    NotificationManager.dispatch({
      id: "",
      importance: Success,
      context: Operation("sidebar_upload"),
      message: "Upload Complete",
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Success),
      dismissible: true,
      createdAt: Date.now(),
    })
  } catch {
  | JsExn(obj) =>
    let msg = switch JsExn.message(obj) {
    | Some(m) => m
    | None => "Unknown error"
    }
    dispatch(Actions.DispatchAppFsmEvent(CriticalErrorOccurred("Upload Failed: " ++ msg)))
    NotificationManager.dispatch({
      id: "",
      importance: Error,
      context: Operation("sidebar_upload"),
      message: "Upload failed: " ++ msg,
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Error),
      dismissible: true,
      createdAt: Date.now(),
    })
    updateProgress(~dispatch, 0.0, "Error: " ++ msg, false, "")
  | _ => dispatch(Actions.DispatchAppFsmEvent(CriticalErrorOccurred("Unknown Upload Error")))
  }
}

let handleUpload = async (
  filesOpt,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  switch filesOpt {
  | Some(files) if FileList.length(files) > 0 =>
    let state = getState()
    // Guard: Only start if not already blocking
    switch state.appMode {
    | SystemBlocking(Uploading(_))
    | SystemBlocking(Summary(_))
    | SystemBlocking(ProjectLoading(_))
    | SystemBlocking(Exporting(_)) =>
      NotificationManager.dispatch({
        id: "",
        importance: Warning,
        context: Operation("sidebar_upload"),
        message: "Please wait for current operation to finish",
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Warning),
        dismissible: true,
        createdAt: Date.now(),
      })
    | _ =>
      dispatch(DispatchAppFsmEvent(StartUpload))
      NotificationManager.dispatch({
        id: "",
        importance: Info,
        context: Operation("sidebar_upload"),
        message: "Upload Started...",
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Info),
        dismissible: true,
        createdAt: Date.now(),
      })
      await performUpload(files, ~getState, ~dispatch)
    }
  | _ => ()
  }
}

let handleLoadProject = async (filesOpt, ~getState, ~dispatch, _sceneCount, target) => {
  switch filesOpt {
  | Some(files) if FileList.length(files) > 0 =>
    SessionStore.clearState()
    try {
      switch FileList.item(files, 0) {
      | Some(file) =>
        dispatch(Actions.DispatchAppFsmEvent(StartProjectLoad({name: File.name(file)})))
        updateProgress(~dispatch, 0.0, "Loading Project...", true, "Loading")

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
          updateProgress(~dispatch, pct->Int.toFloat, msg, true, "Loading")
        })

        switch projectDataResult {
        | Ok((sessionId, projectData)) => {
            ViewerSystem.resetState()
            dispatch(Actions.SetSessionId(sessionId))
            dispatch(Actions.LoadProject(projectData))
            UploadReport.showFromProjectData(projectData, ~getState, ~dispatch)

            Logger.endOperation(
              ~module_="Sidebar",
              ~operation="PROJECT_LOAD",
              ~data={"success": true},
              (),
            )
            updateProgress(~dispatch, 100.0, "Done", false, "")
            dispatch(Actions.DispatchAppFsmEvent(ProjectLoadComplete))
            NotificationManager.dispatch({
              id: "",
              importance: Success,
              context: Operation("sidebar_load_project"),
              message: "Project Loaded",
              details: None,
              action: None,
              duration: NotificationTypes.defaultTimeoutMs(Success),
              dismissible: true,
              createdAt: Date.now(),
            })
          }
        | Error(msg) => {
            Logger.info(
              ~module_="SidebarLogic",
              ~message="PROJECT_LOAD_FAILED_DISPATCHING_NOTIF",
              ~data=Some({"error": msg}),
              (),
            )
            dispatch(Actions.DispatchAppFsmEvent(ProjectLoadError(msg)))
            NotificationManager.dispatch({
              id: "",
              importance: Error,
              context: Operation("sidebar_load_project"),
              message: "Failed to load project: " ++ msg,
              details: None,
              action: None,
              duration: NotificationTypes.defaultTimeoutMs(Error),
              dismissible: true,
              createdAt: Date.now(),
            })
            updateProgress(~dispatch, 0.0, "Error: " ++ msg, false, "")
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
    | _ => updateProgress(~dispatch, 0.0, "Error", false, "")
    }
    asDynamic(target)["value"] = ""
  | _ => ()
  }
}

let getProjectData = (state: Types.state) => {
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
  JsonParsers.Encoders.project(project)
}

let handleDeleteScene = async (index: int, ~getState: unit => Types.state) => {
  let _ = await OptimisticAction.execute(~action=Actions.DeleteScene(index), ~apiCall=() => {
    let state = getState()
    switch state.sessionId {
    | Some(sid) =>
      let projectData = getProjectData(state)
      Api.ProjectApi.saveProject(sid, projectData)
    | None => Promise.resolve(Error("No active session"))
    }
  })
}

let handleExport = async (
  scenes,
  ~tourName: string,
  ~dispatch: Actions.action => unit=AppContext.getBridgeDispatch(),
  ~signal,
  ~onCancel,
) => {
  dispatch(DispatchAppFsmEvent(StartExport))
  updateProgress(~dispatch, ~onCancel, 0.0, "Exporting...", true, "Export")
  NotificationManager.dispatch({
    id: "",
    importance: Info,
    context: Operation("sidebar_export"),
    message: "Export Started...",
    details: None,
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(Info),
    dismissible: true,
    createdAt: Date.now(),
  })
  try {
    let exportResult = await Exporter.exportTour(
      scenes,
      ~tourName,
      ~logo=AppContext.getBridgeState().logo,
      ~signal,
      Some((pct, _, msg) => updateProgress(~dispatch, ~onCancel, pct, msg, true, "Export")),
    )
    switch exportResult {
    | Ok() => {
        NotificationManager.dispatch({
          id: "",
          importance: Success,
          context: Operation("sidebar_export"),
          message: "Export complete",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Success),
          dismissible: true,
          createdAt: Date.now(),
        })
        updateProgress(~dispatch, 100.0, "Done", false, "")
        dispatch(DispatchAppFsmEvent(ExportComplete))
      }
    | Error("CANCELLED") => {
        Logger.info(~module_="SidebarLogic", ~message="EXPORT_CANCELLED_HANDLED", ())
        updateProgress(~dispatch, 0.0, "Cancelled", false, "")
        dispatch(DispatchAppFsmEvent(ExportComplete))
      }
    | Error(msg) => {
        dispatch(DispatchAppFsmEvent(ExportError(msg)))
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: Operation("sidebar_export"),
          message: "Export failed: " ++ msg,
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        updateProgress(~dispatch, 0.0, "Error: " ++ msg, false, "")
      }
    }
  } catch {
  | _ =>
    dispatch(DispatchAppFsmEvent(ExportError("Unexpected Error")))
    updateProgress(~dispatch, 0.0, "Error", false, "")
  }
}
