open SidebarBase

module UploadLogic = SidebarUploadLogic

let profileToKey = (profile: SidebarBase.SidebarTypes.publishProfile): string =>
  switch profile {
  | #hd => "hd"
  | #k2 => "2k"
  | #k4 => "4k"
  | #standalone2k => "desktop_blob_2k"
  | #standaloneHdLandscapeTouch => "desktop_blob_hd_landscape_touch"
  | #standalone2kLandscapeTouch => "desktop_blob_2k_landscape_touch"
  | #standalone4kLandscapeTouch => "desktop_blob_4k_landscape_touch"
  }

let handleExport = async (
  ~progressToastId,
  scenes: array<Types.scene>,
  ~publishOptions: SidebarBase.SidebarTypes.publishOptions,
  ~tourName: string,
  ~projectData: option<JSON.t>=?,
  ~dispatch: Actions.action => unit=AppContext.getBridgeDispatch(),
  ~signal,
  ~onCancel,
) => {
  let selectedProfiles = publishOptions.selectedProfiles->Belt.Array.map(profileToKey)

  if Belt.Array.length(selectedProfiles) == 0 {
    NotificationManager.dispatch({
      id: "",
      importance: Warning,
      context: Operation("sidebar_export"),
      message: "Publish cancelled: select at least one output format.",
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Warning),
      dismissible: true,
      createdAt: Date.now(),
    })
    updateProgress(~dispatch, 0.0, "Cancelled", false, "")
  } else {
    dispatch(DispatchAppFsmEvent(StartExport))
    let exportSceneCount =
      scenes->Belt.Array.keep(s => s.floor->String.trim != "")->Belt.Array.length
    let tracker = SidebarExportSupport.makeTracker(~progressToastId, ~exportSceneCount)

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
    EtaSupport.dispatchCalculatingEtaToast(
      ~id=progressToastId,
      ~contextOperation="eta_export",
      ~prefix="Exporting",
      ~details=Some("Preparing export package"),
      (),
    )

    let handleExportProgress = (pct: float, _total: float, msg: string) => {
      updateProgress(~dispatch, ~onCancel, pct, msg, true, "Export")
      SidebarExportSupport.updateProgressEta(~tracker, ~pct, ~msg)
    }

    try {
      let publishProjectData = SidebarExportSupport.sanitizePublishProjectData(
        ~projectData,
        ~includeMarketing=publishOptions.includeMarketing,
      )

      let logoToUse = if publishOptions.includeLogo {
        AppContext.getBridgeState().logo
      } else {
        None
      }

      let exportResult = await FeatureLoaders.exportTourLazy(
        scenes,
        tourName,
        logoToUse,
        publishOptions.includeLogo,
        publishProjectData,
        signal,
        Some(handleExportProgress),
        opId,
        selectedProfiles,
      )
      switch exportResult {
      | Ok() => {
          EtaSupport.dismissEtaToast(progressToastId)
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
          EtaSupport.dismissEtaToast(progressToastId)
          Logger.info(~module_="SidebarLogicHandler", ~message="EXPORT_CANCELLED_HANDLED", ())
          NotificationManager.dispatch({
            id: "",
            importance: Info,
            context: Operation("sidebar_export"),
            message: "Export cancelled",
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Info),
            dismissible: true,
            createdAt: Date.now(),
          })
          updateProgress(~dispatch, 0.0, "Cancelled", false, "")
          dispatch(DispatchAppFsmEvent(ExportComplete))
        }
      | Error(msg) => {
          EtaSupport.dismissEtaToast(progressToastId)
          Logger.error(
            ~module_="SidebarLogicHandler",
            ~message="EXPORT_FAILED",
            ~data=Some({"error": msg}),
            (),
          )
          dispatch(DispatchAppFsmEvent(ExportComplete))
          let finalMsg = if String.startsWith(msg, "Export blocked") {
            msg
          } else {
            "Export failed: " ++ msg
          }
          NotificationManager.dispatch({
            id: "",
            importance: Error,
            context: Operation("sidebar_export"),
            message: NotificationTypes.truncateForToast(finalMsg),
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
      EtaSupport.dismissEtaToast(progressToastId)
      let msg = exn->JsExn.message->Option.getOr("Unexpected Error")
      Logger.error(
        ~module_="SidebarLogicHandler",
        ~message="EXPORT_FAILED_UNCAUGHT",
        ~data=Some({"error": msg}),
        (),
      )
      dispatch(DispatchAppFsmEvent(ExportComplete))
      let finalMsg = if String.startsWith(msg, "Export blocked") {
        msg
      } else {
        "Export failed: " ++ msg
      }
      NotificationManager.dispatch({
        id: "",
        importance: Error,
        context: Operation("sidebar_export"),
        message: NotificationTypes.truncateForToast(finalMsg),
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Error),
        dismissible: true,
        createdAt: Date.now(),
      })
      updateProgress(~dispatch, 0.0, "Error: " ++ msg, false, "")
    | _ =>
      EtaSupport.dismissEtaToast(progressToastId)
      dispatch(DispatchAppFsmEvent(ExportComplete))
      updateProgress(~dispatch, 0.0, "Error: Unexpected Error", false, "")
    }
  }
}
