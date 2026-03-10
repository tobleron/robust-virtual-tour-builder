/* src/components/Sidebar/SidebarLogicHandler.res */
open ReBindings

let uploadProgressToastId = "sidebar-upload-progress"
let exportProgressToastId = "sidebar-export-progress"

module UploadLogic = SidebarUploadLogic
module SceneActions = SidebarSceneActions
module ExportLogic = SidebarExportLogic

let getActiveSceneId = (state: Types.state): option<string> =>
  SidebarProjectLoadSupport.getActiveSceneId(state)

let isProjectViewerReady = (~getState: unit => Types.state): bool =>
  SidebarProjectLoadSupport.isProjectViewerReady(~getState)

let delayMs = (ms: int): Promise.t<unit> => SidebarProjectLoadSupport.delayMs(ms)

let waitForProjectReady = (
  ~getState: unit => Types.state,
  ~opId: OperationLifecycle.operationId,
  ~maxWaitMs=25000,
  ~pollIntervalMs=80,
): Promise.t<result<unit, string>> =>
  SidebarProjectLoadSupport.waitForProjectReady(~getState, ~opId, ~maxWaitMs, ~pollIntervalMs)

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

let handleLoadProject = async (filesOpt, ~getState, ~dispatch, _sceneCount, target) =>
  await SidebarProjectLoadSupport.handleLoadProject(
    filesOpt,
    ~getState,
    ~dispatch,
    ~sceneCount=_sceneCount,
    target,
  )

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
