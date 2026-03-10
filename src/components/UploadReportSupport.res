open Types

type qualityGroups = {
  ex: array<qualityItem>,
  md: array<qualityItem>,
  pr: array<qualityItem>,
}

let emptyQualityGroups = (): qualityGroups => {
  ex: [],
  md: [],
  pr: [],
}

let summarizeQualityResults = (qualityResults: array<qualityItem>) => {
  let avgScore = ref(0.0)
  let groups = emptyQualityGroups()

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

  (avgScore.contents, groups)
}

let uploadBrief = (report: uploadReport): string => {
  let totalImages = Array.length(report.success) + Array.length(report.skipped)
  if totalImages > 0 {
    "Images: " ++
    Int.toString(totalImages) ++
    " | Ready: " ++
    Int.toString(Array.length(report.success)) ++
    " | Skipped: " ++
    Int.toString(Array.length(report.skipped))
  } else {
    "No images were accepted in this batch."
  }
}

let uploadSummaryContent = (~renderGroup, ~report: uploadReport, ~groups, ~avgScore: float) =>
  <div className="upload-report-container">
    <div className="upload-report-brief"> {React.string(uploadBrief(report))} </div>

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
        {React.string(Float.toFixed(avgScore, ~digits=1))}
        <span className="upload-report-score-total"> {React.string(" / 10")} </span>
      </div>
    </div>
  </div>

let validationHealthScore = (report: SharedTypes.validationReport): float => {
  let issueCount = Array.length(report.warnings) + Array.length(report.errors)
  if issueCount == 0 {
    10.0
  } else {
    let score = 10.0 -. Int.toFloat(issueCount)
    if score < 0.0 {
      0.0
    } else {
      score
    }
  }
}

let validationBrief = (~report: SharedTypes.validationReport, ~sceneCount: int): string =>
  "Scenes: " ++
  Int.toString(sceneCount) ++
  " | Warnings: " ++
  Int.toString(Array.length(report.warnings)) ++
  " | Blockers: " ++
  Int.toString(Array.length(report.errors))

let validationSummaryContent = (~renderGroup, ~report: SharedTypes.validationReport, ~sceneCount) => {
  let healthScore = validationHealthScore(report)
  <div className="upload-report-container">
    <div className="upload-report-brief"> {React.string(validationBrief(~report, ~sceneCount))} </div>

    <div className="upload-report-grid">
      {renderGroup(
        "Cleanups",
        report.brokenLinksRemoved,
        "text-warning",
        <LucideIcons.Settings size=16 strokeWidth=2.0 />,
      )}
      {renderGroup(
        "Orphans",
        Array.length(report.orphanedScenes),
        "text-warning",
        <LucideIcons.Link size=16 strokeWidth=2.0 />,
      )}
      {renderGroup(
        "Warnings",
        Array.length(report.warnings),
        if Array.length(report.warnings) > 0 {
          "text-warning"
        } else {
          "text-success"
        },
        <LucideIcons.TriangleAlert size=16 strokeWidth=2.0 />,
      )}
    </div>

    <div className="upload-report-footer-score">
      <div className="upload-report-title"> {React.string("Load Health")} </div>
      <div className="upload-report-score">
        {React.string(Float.toFixed(healthScore, ~digits=1))}
        <span className="upload-report-score-total"> {React.string(" / 10")} </span>
      </div>
    </div>
  </div>
}
