/* src/components/UploadReport.res */

open Types

type qualityGroups = {
  ex: array<qualityItem>,
  md: array<qualityItem>,
  pr: array<qualityItem>,
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
    let avgScore = ref(0.0)
    let groups = {
      ex: [],
      md: [],
      pr: [],
    }

    if Array.length(qualityResults) > 0 {
      let totalScore = Belt.Array.reduce(qualityResults, 0.0, (acc, r) => acc +. r.quality.score)
      avgScore := totalScore /. Int.toFloat(Array.length(qualityResults))

      Belt.Array.forEach(qualityResults, r => {
        if r.quality.score >= 8.0 {
          Array.push(groups.ex, r)
        } else if r.quality.score >= 6.0 {
          Array.push(groups.md, r)
        } else {
          Array.push(groups.pr, r)
        }
      })
    }

    /* Component Generation */
    let renderGroup = (label, count, className, icon) => {
      <div key=label className="upload-report-group">
        <div className="upload-report-icon"> icon </div>
        <div className={className ++ " upload-report-count"}>
          {React.string(Int.toString(count))}
        </div>
        <div className="upload-report-label"> {React.string(label)} </div>
      </div>
    }

    let content =
      <div className="upload-report-container">
        <div className="upload-report-grid">
          {renderGroup(
            "Excellent",
            Array.length(groups.ex),
            "text-success",
            <LucideIcons.Sparkles size=16 strokeWidth=2.0 />,
          )}
          {renderGroup(
            "Moderate",
            Array.length(groups.md),
            "text-warning",
            <LucideIcons.BarChart3 size=16 strokeWidth=2.0 />,
          )}
          {renderGroup(
            "Review",
            Array.length(groups.pr),
            "text-danger",
            <LucideIcons.TriangleAlert size=16 strokeWidth=2.0 />,
          )}
        </div>

        {if Array.length(report.skipped) > 0 {
          <div className="upload-report-skipped-container">
            <div className="upload-report-skipped-badge">
              <LucideIcons.Copy size=12 className="mr-1" />
              {React.string(`${Int.toString(Array.length(report.skipped))} Duplicates Skipped`)}
            </div>
          </div>
        } else {
          React.null
        }}

        <div className="upload-report-footer-score">
          <div className="upload-report-title"> {React.string("Batch Health")} </div>
          <div className="upload-report-score">
            {React.string(Float.toFixed(avgScore.contents, ~digits=1))}
            <span className="upload-report-score-total"> {React.string(" / 10")} </span>
          </div>
        </div>
      </div>

    let btnDownload: EventBus.button = {
      label: "Download Data Report",
      class_: "bg-slate-100/10 text-white hover:bg-white/20",
      onClick: () => {
        let state = getState()
        switch state.exifReport {
        | Some(reportJson) =>
          switch JsonCombinators.Json.decode(reportJson, JsonCombinators.Json.Decode.string) {
          | Ok(content) =>
            let _ = ExifReportGenerator.downloadExifReport(content)
          | Error(_) => ()
          }
        | None =>
          NotificationManager.dispatch({
            id: "",
            importance: Info,
            context: Operation("upload_report"),
            message: "Report is still generating... please wait a moment.",
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
        if state.activeIndex == -1 && Array.length(SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)) > 0 {
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
  show({success: successNames, skipped: []}, qualityResults, ~getState, ~dispatch)
}
