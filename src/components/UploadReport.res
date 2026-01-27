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
        {if Array.length(groups.pr) > 0 {
          <div className="upload-report-action-container">
            <div className="upload-report-action-title">
              <LucideIcons.Flag size=12 className="mr-1" />
              {React.string(`Action Required (${Int.toString(Array.length(groups.pr))})`)}
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
              <LucideIcons.Copy size=12 className="mr-1" />
              {React.string(`${Int.toString(Array.length(report.skipped))} Duplicates Skipped`)}
            </div>
          </div>
        } else {
          React.null
        }}

        /* Batch Health moved to bottom */
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
      class_: "bg-blue-500/20 text-white hover:bg-blue-500/40",
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
      description: None,
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
  let project = Schemas.castToProject(projectDataJson)
  let successNames = Belt.Array.map(project.scenes, s => s.name)
  let qualityResults = Belt.Array.map(project.scenes, s => {
    let q = switch s.quality {
    | Some(qJson) => Schemas.castToQualityAnalysis(qJson)
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
