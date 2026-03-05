/* src/components/Sidebar/SidebarLogicHandler.res */

open SidebarBase
open ReBindings

@get external value: 'a => string = "value"
@set external set_value: ('a, string) => unit = "value"
external unknownToString: unknown => string = "%identity"
external unknownToBool: unknown => bool = "%identity"

let uploadProgressToastId = "sidebar-upload-progress"
let exportProgressToastId = "sidebar-export-progress"

module UploadLogic = SidebarUploadLogic
module SceneActions = SidebarSceneActions
module ExportLogic = SidebarExportLogic

let getActiveSceneId = (state: Types.state): option<string> => {
  let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  Belt.Array.get(scenes, state.activeIndex)->Option.map(scene => scene.id)
}

let isProjectViewerReady = (~getState: unit => Types.state): bool => {
  let state = getState()
  switch getActiveSceneId(state) {
  | None => true
  | Some(sceneId) =>
    let fsmIdle = switch state.navigationState.navigationFsm {
    | IdleFsm => true
    | _ => false
    }
    let supervisorIdle = NavigationSupervisor.isIdle()
    let viewerReady = switch ViewerSystem.getActiveViewer()->Nullable.toOption {
    | Some(viewer) =>
      let loadedSceneId =
        ViewerSystem.Adapter.getMetaData(viewer, "sceneId")
        ->Option.map(unknownToString)
        ->Option.getOr("")
      let loadedFlag =
        ViewerSystem.Adapter.getMetaData(viewer, "isLoaded")
        ->Option.map(unknownToBool)
        ->Option.getOr(false)
      loadedFlag && loadedSceneId == sceneId
    | None => false
    }
    fsmIdle && supervisorIdle && viewerReady
  }
}

let delayMs = (ms: int): Promise.t<unit> =>
  Promise.make((resolve, _reject) => {
    ignore(ReBindings.Window.setTimeout(() => resolve(), ms))
  })

let waitForProjectReady = (
  ~getState: unit => Types.state,
  ~opId: OperationLifecycle.operationId,
  ~maxWaitMs=25000,
  ~pollIntervalMs=80,
): Promise.t<result<unit, string>> => {
  let startedAt = Date.now()

  let rec poll = (): Promise.t<result<unit, string>> => {
    if isProjectViewerReady(~getState) {
      Promise.resolve(Ok())
    } else {
      let elapsed = Date.now() -. startedAt
      if elapsed >= maxWaitMs->Int.toFloat {
        Promise.resolve(Error("Viewer readiness timed out; continuing with current state."))
      } else {
        if OperationLifecycle.isActive(opId) {
          let pct = 90.0 +. Math.min(9.0, elapsed /. maxWaitMs->Int.toFloat *. 9.0)
          OperationLifecycle.progress(
            opId,
            pct,
            ~message="Finalizing viewer...",
            ~phase="Project Load",
            (),
          )
        }
        delayMs(pollIntervalMs)->Promise.then(_ => poll())
      }
    }
  }

  poll()
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
      EtaSupport.dispatchCalculatingEtaToast(
        ~id=uploadProgressToastId,
        ~contextOperation="eta_upload",
        ~prefix="Uploading",
        (),
      )
      let _ = await UploadLogic.performUpload(
        ~progressToastId=uploadProgressToastId,
        files,
        ~getState,
        ~dispatch,
      )
    }
  | _ => ()
  }
}

let handleLoadProject = async (filesOpt, ~getState, ~dispatch, _sceneCount, target) => {
  switch filesOpt {
  | Some(files) if FileList.length(files) > 0 =>
    let handlerMeta = Logger.castToJson({
      "fileCount": FileList.length(files),
      "sceneCount": _sceneCount,
    })
    Logger.info(
      ~module_="SidebarLogic",
      ~message="PROJECT_LOAD_HANDLER_INVOKED",
      ~data=Some(handlerMeta),
      (),
    )
    SessionStore.clearState()
    try {
      switch FileList.item(files, 0) {
      | Some(file) =>
        let controller = BrowserBindings.AbortController.make()
        let signal = BrowserBindings.AbortController.signal(controller)
        let loadSettled = ref(false)
        let finalizeStageStarted = ref(false)
        let timeoutMs = 120000
        let abortRequest = () => {
          if !BrowserBindings.AbortSignal.aborted(signal) {
            BrowserBindings.AbortController.abort(controller)
          }
        }
        dispatch(Actions.DispatchAppFsmEvent(StartProjectLoad({name: File.name(file)})))

        let opId = OperationLifecycle.start(
          ~type_=ProjectLoad,
          ~scope=Blocking,
          ~phase="Project Load",
          ~meta=Logger.castToJson({
            "filename": File.name(file),
            "size": File.size(file),
          }),
          (),
        )

        let onCancel = () => {
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

        updateProgress(~dispatch, ~onCancel, 0.0, "Loading project...", true, "Project Load")

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
                updateProgress(~dispatch, pct->Int.toFloat, msg, true, "Project Load")
              }
            },
            ~opId,
          )

          ReBindings.Window.clearTimeout(timeoutId)

          if !loadSettled.contents {
            switch projectDataResult {
            | Ok((sessionId, projectData)) => {
                ViewerSystem.resetState()
                if OperationLifecycle.isActive(opId) {
                  OperationLifecycle.progress(
                    opId,
                    88.0,
                    ~message="Applying project state...",
                    ~phase="Project Load",
                    (),
                  )
                }
                dispatch(Actions.SetSessionId(sessionId))
                dispatch(Actions.LoadProject(projectData))
                UploadReport.showFromProjectData(projectData, ~getState, ~dispatch)

                finalizeStageStarted := true
                let readyResult = await waitForProjectReady(~getState, ~opId)

                if !loadSettled.contents {
                  loadSettled := true
                  switch readyResult {
                  | Ok(_) =>
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
                    Logger.endOperation(
                      ~module_="Sidebar",
                      ~operation="PROJECT_LOAD",
                      ~data={"success": true},
                      (),
                    )
                  | Error(waitMsg) =>
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
                }
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

let handleDeleteScene = SceneActions.handleDeleteScene
let handleDeleteSceneWithUndo = SceneActions.handleDeleteSceneWithUndo
let handleClearLinksWithUndo = SceneActions.handleClearLinksWithUndo

let handleExport = async (
  scenes: array<Types.scene>,
  ~publishOptions: SidebarBase.SidebarTypes.publishOptions,
  ~tourName: string,
  ~projectData: option<JSON.t>=?,
  ~dispatch: Actions.action => unit=AppContext.getBridgeDispatch(),
  ~signal,
  ~onCancel,
) => {
  await ExportLogic.handleExport(
    ~progressToastId=exportProgressToastId,
    scenes,
    ~publishOptions,
    ~tourName,
    ~projectData?,
    ~dispatch,
    ~signal,
    ~onCancel,
  )
}
