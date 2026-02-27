/* src/components/Sidebar/SidebarLogicHandler.res */

open SidebarBase
open ReBindings

@get external value: 'a => string = "value"
@set external set_value: ('a, string) => unit = "value"

let uploadProgressToastId = "sidebar-upload-progress"
let exportProgressToastId = "sidebar-export-progress"

module UploadLogic = SidebarUploadLogic
module SceneActions = SidebarSceneActions
module ExportLogic = SidebarExportLogic

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
      await UploadLogic.performUpload(~progressToastId=uploadProgressToastId, files, ~getState, ~dispatch)
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

let handleDeleteScene = SceneActions.handleDeleteScene
let handleDeleteSceneWithUndo = SceneActions.handleDeleteSceneWithUndo
let handleClearLinksWithUndo = SceneActions.handleClearLinksWithUndo

let handleExport = async (
  scenes: array<Types.scene>,
  ~tourName: string,
  ~projectData: option<JSON.t>=?,
  ~dispatch: Actions.action => unit=AppContext.getBridgeDispatch(),
  ~signal,
  ~onCancel,
) => {
  await ExportLogic.handleExport(
    ~progressToastId=exportProgressToastId,
    scenes,
    ~tourName,
    ~projectData?,
    ~dispatch,
    ~signal,
    ~onCancel,
  )
}
