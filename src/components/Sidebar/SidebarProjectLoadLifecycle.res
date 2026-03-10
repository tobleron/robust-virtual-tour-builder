open SidebarBase

let abortRequest = (~signal, controller) => {
  if !BrowserBindings.AbortSignal.aborted(signal) {
    BrowserBindings.AbortController.abort(controller)
  }
}

let finalizeFailure = (
  ~dispatch: Actions.action => unit,
  ~opId: OperationLifecycle.operationId,
  ~loadSettled: ref<bool>,
  ~msg: string,
) => {
  if !loadSettled.contents {
    loadSettled := true
    if OperationLifecycle.isActive(opId) {
      OperationLifecycle.fail(opId, msg)
    }
    dispatch(Actions.DispatchAppFsmEvent(ProjectLoadError(msg)))
    NotificationManager.dispatch({
      id: "",
      importance: Error,
      context: Operation("sidebar_load_project"),
      message: NotificationTypes.truncateForToast("Failed to load project: " ++ msg),
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

let handleCancel = (
  ~dispatch: Actions.action => unit,
  ~opId: OperationLifecycle.operationId,
  ~loadSettled: ref<bool>,
  ~finalizeStageStarted: ref<bool>,
  ~abortRequest: unit => unit,
) => {
  let _ = opId
  if !loadSettled.contents {
    loadSettled := true
    if finalizeStageStarted.contents {
      updateProgress(~dispatch, 100.0, "Finalized", false, "")
      dispatch(Actions.DispatchAppFsmEvent(ProjectLoadComplete))
      NotificationManager.dispatch({
        id: "",
        importance: Info,
        context: Operation("sidebar_load_project"),
        message: "Project loaded. Finalization wait cancelled.",
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Info),
        dismissible: true,
        createdAt: Date.now(),
      })
      Logger.endOperation(
        ~module_="Sidebar",
        ~operation="PROJECT_LOAD",
        ~data={"success": true, "cancelledDuringFinalize": true},
        (),
      )
    } else {
      updateProgress(~dispatch, 0.0, "Cancelled", false, "")
      dispatch(Actions.DispatchAppFsmEvent(ProjectLoadComplete))
      NotificationManager.dispatch({
        id: "",
        importance: Info,
        context: Operation("sidebar_load_project"),
        message: "Project load cancelled",
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Info),
        dismissible: true,
        createdAt: Date.now(),
      })
      Logger.endOperation(
        ~module_="Sidebar",
        ~operation="PROJECT_LOAD",
        ~data={"success": false, "cancelled": true},
        (),
      )
      abortRequest()
    }
  }
}

let completeReady = (
  ~dispatch: Actions.action => unit,
  ~opId: OperationLifecycle.operationId,
) => {
  if OperationLifecycle.isActive(opId) {
    OperationLifecycle.progress(
      opId,
      100.0,
      ~message="Project ready",
      ~phase="Project Load",
      (),
    )
    OperationLifecycle.complete(opId, ~result="Project ready", ())
  }
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
  Logger.endOperation(~module_="Sidebar", ~operation="PROJECT_LOAD", ~data={"success": true}, ())
}

let completeReadyWarning = (
  ~dispatch: Actions.action => unit,
  ~opId: OperationLifecycle.operationId,
  ~waitMsg: string,
) => {
  Logger.warn(
    ~module_="SidebarLogic",
    ~message="PROJECT_READY_TIMEOUT_CONTINUE",
    ~data=Some({"warning": waitMsg}),
    (),
  )
  if OperationLifecycle.isActive(opId) {
    OperationLifecycle.complete(opId, ~result="Loaded with warning", ())
  }
  updateProgress(~dispatch, 100.0, "Loaded", false, "")
  dispatch(Actions.DispatchAppFsmEvent(ProjectLoadComplete))
  NotificationManager.dispatch({
    id: "",
    importance: Warning,
    context: Operation("sidebar_load_project"),
    message: "Project loaded, viewer still settling. Continue working.",
    details: Some(waitMsg),
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(Warning),
    dismissible: true,
    createdAt: Date.now(),
  })
  Logger.endOperation(
    ~module_="Sidebar",
    ~operation="PROJECT_LOAD",
    ~data={"success": true, "warning": waitMsg},
    (),
  )
}
