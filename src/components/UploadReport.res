/* src/components/UploadReport.res */

open Types

type qualityItem = {
  quality: SharedTypes.qualityAnalysis,
  newName: string,
}

type qualityGroups = {
  ex: array<qualityItem>,
  md: array<qualityItem>,
  pr: array<qualityItem>,
}

let show = (report: uploadReport, qualityResults: array<qualityItem>) => {
  if Array.length(report.success) == 0 && Array.length(report.skipped) == 0 {
    ()
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
        if r.quality.score >= 8.5 {
          Array.push(groups.ex, r)
        } else if r.quality.score >= 6.5 {
          Array.push(groups.md, r)
        } else {
          Array.push(groups.pr, r)
        }
      })
    }

    /* Component Generation */
    let renderGroup = (label, count, className, icon) => {
      <div key=label className="upload-report-group">
        <div className="upload-report-icon"> {React.string(icon)} </div>
        <div className={className ++ " upload-report-count"}>
          {React.string(Int.toString(count))}
        </div>
        <div className="upload-report-label"> {React.string(label)} </div>
      </div>
    }

    let content =
      <div className="upload-report-container">
        <div className="upload-report-main-icon"> {React.string("\u2728")} </div>
        <div className="upload-report-card">
          <div className="upload-report-header">
            <div className="upload-report-title"> {React.string("Batch Health")} </div>
            <div className="upload-report-score">
              {React.string(Float.toFixed(avgScore.contents, ~digits=1))}
              <span className="upload-report-score-total"> {React.string(" / 10")} </span>
            </div>
          </div>
          <div className="upload-report-grid">
            {renderGroup("Excellent", Array.length(groups.ex), "text-success", "\u{1F31F}")}
            {renderGroup("Moderate", Array.length(groups.md), "text-warning", "\u{1F4C8}")}
            {renderGroup("Review", Array.length(groups.pr), "text-danger", "\u26A0\uFE0F")}
          </div>
        </div>
        {if Array.length(groups.pr) > 0 {
          <div className="upload-report-action-container">
            <div className="upload-report-action-title">
              {React.string(`\u{1F6A9} Action Required (${Int.toString(Array.length(groups.pr))})`)}
            </div>
            <div className="upload-report-action-list">
              {groups.pr
              ->Belt.Array.map(r => {
                <div key={r.newName} className="upload-report-item">
                  <div className="upload-report-item-header">
                    <span className="upload-report-filename"> {React.string(r.newName)} </span>
                    <span className="upload-report-item-score">
                      {React.string(Float.toString(r.quality.score))}
                    </span>
                  </div>
                  {switch Nullable.toOption(r.quality.analysis) {
                  | Some(a) => <div className="upload-report-analysis"> {React.string(a)} </div>
                  | None => React.null
                  }}
                </div>
              })
              ->React.array}
            </div>
          </div>
        } else {
          React.null
        }}
        {if Array.length(report.skipped) > 0 {
          <div className="upload-report-skipped-container">
            <div className="upload-report-skipped-badge">
              <span className="upload-report-skipped-icon"> {React.string("\u{1F4D1}")} </span>
              {React.string(` ${Int.toString(Array.length(report.skipped))} Duplicates Skipped`)}
            </div>
          </div>
        } else {
          React.null
        }}
      </div>

    let btnDownload: EventBus.button = {
      label: "Download Data Report",
      class_: "bg-slate-100 text-slate-700 hover:bg-slate-200",
      onClick: () => {
        let state = GlobalStateBridge.getState()
        switch state.exifReport {
        | Some(reportJson) =>
          switch JSON.Decode.string(reportJson) {
          | Some(content) =>
            let _ = ExifReportGenerator.downloadExifReport(content)
          | None => ()
          }
        | None =>
          EventBus.dispatch(
            ShowNotification("Report is still generating... please wait a moment.", #Info),
          )
        }
      },
      autoClose: Some(false),
    }

    let btnStart: EventBus.button = {
      label: "Start Building",
      class_: "btn-blue",
      onClick: () => {
        let state = GlobalStateBridge.getState()
        if Array.length(state.scenes) > 0 {
          GlobalStateBridge.dispatch(Actions.SetActiveScene(0, 0.0, 0.0, None))
        }
      },
      autoClose: Some(true),
    }

    let options: EventBus.modalConfig = {
      title: "Upload Summary",
      description: Some("Intelligent quality evaluation"),
      icon: None,
      content: Some(content),
      buttons: [btnDownload, btnStart],
      onClose: None,
      allowClose: Some(true),
      className: Some("modal-blue"),
    }
    EventBus.dispatch(ShowModal(options))
  }
}

let showFromProjectData = (projectDataJson: JSON.t) => {
  let project = JsonTypes.castToProject(projectDataJson)
  let successNames = Belt.Array.map(project.scenes, s => s.name)
  let qualityResults = Belt.Array.map(project.scenes, s => {
    let q = switch Nullable.toOption(s.quality) {
    | Some(qJson) => JsonTypes.castToQualityAnalysis(qJson)
    | None => {
        SharedTypes.score: 0.0,
        isBlurry: false,
        isDim: false,
        isSeverelyDark: false,
        stats: {
          avgLuminance: 0,
          sharpnessVariance: 0,
          blackClipping: 0.0,
          whiteClipping: 0.0,
        },
        analysis: Nullable.null,
        histogram: [],
        colorHist: {r: [], g: [], b: []},
        isSoft: false,
        isSeverelyBright: false,
        hasBlackClipping: false,
        hasWhiteClipping: false,
        issues: 0,
        warnings: 0,
      }
    }
    {quality: q, newName: s.name}
  })
  show({success: successNames, skipped: []}, qualityResults)
}
