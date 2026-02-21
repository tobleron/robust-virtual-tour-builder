/* src/components/Sidebar/SidebarLogicHandler.res */

open SidebarBase
open ReBindings

@get external value: 'a => string = "value"
@set external set_value: ('a, string) => unit = "value"

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
    let canUpload = Capability.Policy.evaluate(
      ~capability=CanUpload,
      ~appMode=state.appMode,
      OperationLifecycle.getOperations(),
    )

    if !canUpload {
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
    } else {
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
        let controller = BrowserBindings.AbortController.make()
        let signal = BrowserBindings.AbortController.signal(controller)
        let loadSettled = ref(false)
        let timeoutMs = 120000
        let abortRequest = () => BrowserBindings.AbortController.abort(controller)
        let onCancel = () => {
          if !loadSettled.contents {
            loadSettled := true
            updateProgress(~dispatch, 0.0, "Cancelled", false, "")
            dispatch(Actions.DispatchAppFsmEvent(ProjectLoadError("Cancelled")))
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
          }
          abortRequest()
        }
        dispatch(Actions.DispatchAppFsmEvent(StartProjectLoad({name: File.name(file)})))

        let opId = OperationLifecycle.start(
          ~type_=ProjectLoad,
          ~scope=Blocking,
          ~phase="Loading",
          ~meta=Logger.castToJson({
            "filename": File.name(file),
            "size": File.size(file),
          }),
          (),
        )
        OperationLifecycle.registerCancel(opId, onCancel)

        let finalizeFailure = (msg: string) => {
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

        updateProgress(~dispatch, ~onCancel, 0.0, "Loading Project...", true, "Loading")

        Logger.startOperation(
          ~module_="Sidebar",
          ~operation="PROJECT_LOAD",
          ~data={
            "filename": File.name(file),
            "size": File.size(file),
          },
          (),
        )

        let timeoutId = ReBindings.Window.setTimeout(() => {
          abortRequest()
          finalizeFailure("Project load timed out. Please retry.")
        }, timeoutMs)

        try {
          let projectDataResult = await ProjectManager.loadProject(
            file,
            ~signal,
            ~onProgress=(pct, _t, msg) => {
              if !loadSettled.contents {
                updateProgress(~dispatch, pct->Int.toFloat, msg, true, "Loading")
              }
            },
            ~opId,
          )

          ReBindings.Window.clearTimeout(timeoutId)

          if !loadSettled.contents {
            switch projectDataResult {
            | Ok((sessionId, projectData)) => {
                loadSettled := true
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
            | Error(msg) =>
              Logger.info(
                ~module_="SidebarLogic",
                ~message="PROJECT_LOAD_FAILED_DISPATCHING_NOTIF",
                ~data=Some({"error": msg}),
                (),
              )
              finalizeFailure(msg)
            }
          }
        } catch {
        | JsExn(exn) =>
          ReBindings.Window.clearTimeout(timeoutId)
          let msg = exn->JsExn.message->Option.getOr("Unexpected project load error")
          finalizeFailure(msg)
        | _ =>
          ReBindings.Window.clearTimeout(timeoutId)
          finalizeFailure("Unexpected project load error")
        }
      | None => ()
      }
    } catch {
    | _ => updateProgress(~dispatch, 0.0, "Error", false, "")
    }
    set_value(target, "")
  | _ => ()
  }
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

let isMissingPanoramaFile = (f: Types.file) => {
  switch f {
  | Url(u) => u == ""
  | Blob(_) | File(_) => false
  }
}

let repairRestoredState = (~restoredState: Types.state, ~currentState: Types.state) => {
  let repairedInventory =
    restoredState.inventory
    ->Belt.Map.String.toArray
    ->Belt.Array.reduce(Belt.Map.String.empty, (acc, (id, entry)) => {
      let restoredScene = entry.scene
      let repairedFile = if !isMissingPanoramaFile(restoredScene.file) {
        restoredScene.file
      } else {
        switch currentState.inventory->Belt.Map.String.get(id) {
        | Some(currentEntry) if !isMissingPanoramaFile(currentEntry.scene.file) =>
          currentEntry.scene.file
        | _ =>
          switch restoredScene.originalFile {
          | Some(f) if !isMissingPanoramaFile(f) => f
          | _ =>
            switch restoredScene.tinyFile {
            | Some(f) if !isMissingPanoramaFile(f) => f
            | _ => restoredScene.file
            }
          }
        }
      }

      let repairedScene = {...restoredScene, file: repairedFile}
      acc->Belt.Map.String.set(id, {...entry, scene: repairedScene})
    })

  let rebuilt = {...restoredState, inventory: repairedInventory}->SceneInventory.rebuildLegacyFields
  let sceneCount = Belt.Array.length(rebuilt.scenes)
  let activeIndex = if sceneCount == 0 {
    -1
  } else {
    let boundedHigh = rebuilt.activeIndex > sceneCount - 1 ? sceneCount - 1 : rebuilt.activeIndex
    boundedHigh < 0 ? 0 : boundedHigh
  }

  {
    ...rebuilt,
    activeIndex,
    activeYaw: activeIndex == -1 ? 0.0 : rebuilt.activeYaw,
    activePitch: activeIndex == -1 ? 0.0 : rebuilt.activePitch,
  }
}

let handleDeleteSceneWithUndo = (
  index: int,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let state = getState()
  let action = Actions.DeleteScene(index)

  // 1. Capture state for potential undo
  let snapId = StateSnapshot.capture(state, action)

  // 2. Perform optimistic delete (local only)
  dispatch(action)

  let undoCalled = ref(false)

  let performUndo = () => {
    if !undoCalled.contents {
      undoCalled := true
      switch StateSnapshot.rollback(snapId) {
      | Some(restoredState) =>
        let repaired = repairRestoredState(~restoredState, ~currentState=getState())
        AppContext.restoreState(repaired)
        NotificationManager.dismiss("undo-delete-" ++ snapId)
        NotificationManager.dispatch({
          id: "undone-notif-" ++ snapId,
          importance: Info,
          context: UserAction("undo"),
          message: "Scene deletion undone",
          details: None,
          action: None,
          duration: 3000,
          dismissible: true,
          createdAt: Date.now(),
        })
      | None => ()
      }
    }
  }

  // 3. Set timer for backend synchronization (9.5s to give buffer for 9s notification)
  let _ = Window.setTimeout(() => {
    if !undoCalled.contents {
      let currentState = getState()
      switch currentState.sessionId {
      | Some(sid) =>
        let projectData = getProjectData(currentState)
        Api.ProjectApi.saveProject(sid, projectData)->ignore
      | None => ()
      }
    }
  }, 9500)

  // 4. Show notification with 9s timer and Undo shortcut
  NotificationManager.dispatch({
    id: "undo-delete-" ++ snapId,
    importance: Success,
    context: UserAction("delete_scene"),
    message: "Scene deleted. Press U to undo.",
    details: None,
    action: Some({
      label: "Undo",
      onClick: performUndo,
      shortcut: Some("u"),
    }),
    duration: 9000,
    dismissible: true,
    createdAt: Date.now(),
  })
}

let handleClearLinksWithUndo = (
  index: int,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let state = getState()
  let action = Actions.ClearHotspots(index)

  // 1. Capture state for potential undo
  let snapId = StateSnapshot.capture(state, action)

  // 2. Perform optimistic clear (local only)
  dispatch(action)

  let undoCalled = ref(false)

  let performUndo = () => {
    if !undoCalled.contents {
      undoCalled := true
      switch StateSnapshot.rollback(snapId) {
      | Some(restoredState) =>
        let repaired = repairRestoredState(~restoredState, ~currentState=getState())
        AppContext.restoreState(repaired)
        NotificationManager.dismiss("undo-clear-" ++ snapId)
        NotificationManager.dispatch({
          id: "undone-clear-notif-" ++ snapId,
          importance: Info,
          context: UserAction("undo"),
          message: "Hotspots restored",
          details: None,
          action: None,
          duration: 3000,
          dismissible: true,
          createdAt: Date.now(),
        })
      | None => ()
      }
    }
  }

  // 3. Set timer for backend synchronization
  let _ = Window.setTimeout(() => {
    if !undoCalled.contents {
      let currentState = getState()
      switch currentState.sessionId {
      | Some(sid) =>
        let projectData = getProjectData(currentState)
        Api.ProjectApi.saveProject(sid, projectData)->ignore
      | None => ()
      }
    }
  }, 9500)

  // 4. Show notification with 9s timer and Undo shortcut
  NotificationManager.dispatch({
    id: "undo-clear-" ++ snapId,
    importance: Success,
    context: UserAction("clear_links"),
    message: "Links cleared. Press U to undo.",
    details: None,
    action: Some({
      label: "Undo",
      onClick: performUndo,
      shortcut: Some("u"),
    }),
    duration: 9000,
    dismissible: true,
    createdAt: Date.now(),
  })
}

let handleExport = async (
  scenes,
  ~tourName: string,
  ~projectData: option<JSON.t>=?,
  ~dispatch: Actions.action => unit=AppContext.getBridgeDispatch(),
  ~signal,
  ~onCancel,
) => {
  dispatch(DispatchAppFsmEvent(StartExport))

  let opId = OperationLifecycle.start(
    ~type_=Export,
    ~scope=Blocking,
    ~phase="Preparing",
    ~meta=Logger.castToJson({
      "tourName": tourName,
    }),
    (),
  )
  OperationLifecycle.registerCancel(opId, onCancel)

  updateProgress(~dispatch, ~onCancel, 0.0, "Starting export...", true, "Export")
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
      ~projectData?,
      ~signal,
      Some((pct, _, msg) => updateProgress(~dispatch, ~onCancel, pct, msg, true, "Export")),
      ~opId,
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
        Logger.info(~module_="SidebarLogicHandler", ~message="EXPORT_CANCELLED_HANDLED", ())
        updateProgress(~dispatch, 0.0, "Cancelled", false, "")
        dispatch(DispatchAppFsmEvent(ExportComplete))
      }
    | Error(msg) => {
        Logger.error(
          ~module_="SidebarLogicHandler",
          ~message="EXPORT_FAILED",
          ~data=Some({"error": msg}),
          (),
        )
        dispatch(DispatchAppFsmEvent(ExportComplete))
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
  | JsExn(exn) =>
    let msg = exn->JsExn.message->Option.getOr("Unexpected Error")
    Logger.error(
      ~module_="SidebarLogicHandler",
      ~message="EXPORT_FAILED_UNCAUGHT",
      ~data=Some({"error": msg}),
      (),
    )
    dispatch(DispatchAppFsmEvent(ExportComplete))
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
  | _ =>
    dispatch(DispatchAppFsmEvent(ExportComplete))
    updateProgress(~dispatch, 0.0, "Error: Unexpected Error", false, "")
  }
}
