/* src/components/UploadReport.res */

open Types

let validationReportWrapperDecoder = JsonCombinators.Json.Decode.object(field => {
  field.required("validationReport", JsonParsers.Shared.validationReport)
})

let renderGroup = (label, count, className, icon) => {
  <div key=label className="upload-report-group">
    <div className="upload-report-icon"> icon </div>
    <div className={className ++ " upload-report-count"}> {React.string(Int.toString(count))} </div>
    <div className="upload-report-label"> {React.string(label)} </div>
  </div>
}

let show = (
  report: uploadReport,
  qualityResults: array<qualityItem>,
  ~getState: unit => state,
  ~dispatch: Actions.action => unit,
) => {
  if Array.length(report.success) == 0 && Array.length(report.skipped) == 0 {
    let options: EventBus.modalConfig = {
      title: "Upload Failed",
      description: Some(
        "No files were successfully processed. Please check your files and try again.",
      ),
      icon: Some("alert-circle"),
      content: None,
      buttons: [
        {
          label: "Close",
          class_: "btn-secondary",
          onClick: () => dispatch(DispatchAppFsmEvent(CloseSummary)),
          autoClose: Some(true),
        },
      ],
      onClose: Some(() => dispatch(DispatchAppFsmEvent(CloseSummary))),
      allowClose: Some(true),
      className: None,
    }
    EventBus.dispatch(ShowModal(options))
  } else {
    let (avgScore, groups) = UploadReportSupport.summarizeQualityResults(qualityResults)
    let content = UploadReportSupport.uploadSummaryContent(
      ~renderGroup,
      ~report,
      ~groups,
      ~avgScore,
    )

    let btnDownload: EventBus.button = {
      label: "Download Data Report",
      class_: "bg-slate-100/10 text-white hover:bg-white/20",
      onClick: () => {
        let state = getState()
        switch state.exifReport {
        | Some(reportJson) =>
          switch JsonCombinators.Json.decode(reportJson, JsonCombinators.Json.Decode.string) {
          | Ok(content) =>
            let _ = FeatureLoaders.downloadExifReportLazy(content)
          | Error(_) => ()
          }
        | None =>
          NotificationManager.dispatch({
            id: "",
            importance: Info,
            context: Operation("upload_report"),
            message: "Report still generating. Please wait.",
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Info),
            dismissible: true,
            createdAt: Date.now(),
          })
        }
      },
      autoClose: Some(false),
    }

    let btnStart: EventBus.button = {
      label: "Start Building",
      class_: "bg-blue-500/20 text-white hover:bg-blue-500/40",
      onClick: () => {
        let state = getState()
        dispatch(DispatchAppFsmEvent(CloseSummary))
        if (
          state.activeIndex == -1 &&
            Array.length(SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)) > 0
        ) {
          dispatch(Actions.SetActiveScene(0, 0.0, 0.0, None))
        }
      },
      autoClose: Some(true),
    }

    let options: EventBus.modalConfig = {
      title: "Upload Summary",
      description: None,
      icon: None,
      content: Some(content),
      buttons: [btnDownload, btnStart],
      onClose: Some(() => dispatch(DispatchAppFsmEvent(CloseSummary))),
      allowClose: Some(true),
      className: Some("modal-blue"),
    }
    EventBus.dispatch(ShowModal(options))
  }
}

let showValidationSummary = (
  report: SharedTypes.validationReport,
  ~sceneCount: int,
  ~dispatch: Actions.action => unit,
) => {
  let content = UploadReportSupport.validationSummaryContent(~renderGroup, ~report, ~sceneCount)

  let options: EventBus.modalConfig = {
    title: "Project Validation Summary",
    description: None,
    icon: None,
    content: Some(content),
    buttons: [
      {
        label: "Continue",
        class_: "bg-blue-500/20 text-white hover:bg-blue-500/40",
        onClick: () => dispatch(DispatchAppFsmEvent(CloseSummary)),
        autoClose: Some(true),
      },
    ],
    onClose: Some(() => dispatch(DispatchAppFsmEvent(CloseSummary))),
    allowClose: Some(true),
    className: Some("modal-blue"),
  }
  EventBus.dispatch(ShowModal(options))
}

let showFromProjectData = (projectDataJson: JSON.t, ~getState, ~dispatch) => {
  let project = switch JsonCombinators.Json.decode(projectDataJson, JsonParsers.Domain.project) {
  | Ok(p) => p
  | Error(e) => {
      Logger.error(
        ~module_="UploadReport",
        ~message="Failed to parse project data for report",
        ~data=Logger.castToJson({"error": e}),
        (),
      )
      // Return empty/safe default if parse fails
      {
        tourName: "",
        inventory: Belt.Map.String.empty,
        sceneOrder: [],
        lastUsedCategory: "",
        exifReport: None,
        sessionId: None,
        timeline: [],
        logo: None,
        marketingComment: "",
        marketingPhone1: "",
        marketingPhone2: "",
        marketingForRent: false,
        marketingForSale: false,
        nextSceneSequenceId: getState().nextSceneSequenceId,
      }
    }
  }

  let scenes = SceneInventory.getActiveScenes(project.inventory, project.sceneOrder)
  let successNames = Belt.Array.map(scenes, s => s.name)
  let qualityResults = Belt.Array.map(scenes, s => {
    let q = switch s.quality {
    | Some(qJson) =>
      switch JsonCombinators.Json.decode(qJson, JsonParsers.Shared.qualityAnalysis) {
      | Ok(qa) => qa
      | Error(_) => SharedTypes.defaultQuality("Parse error")
      }
    | None => SharedTypes.defaultQuality("Missing quality data")
    }
    {quality: q, newName: s.name}
  })

  switch JsonCombinators.Json.decode(projectDataJson, validationReportWrapperDecoder) {
  | Ok(report) => showValidationSummary(report, ~sceneCount=Array.length(scenes), ~dispatch)
  | Error(_) => show({success: successNames, skipped: []}, qualityResults, ~getState, ~dispatch)
  }
}
