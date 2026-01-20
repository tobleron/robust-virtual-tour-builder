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
          let _ = Js.Array.push(r, groups.ex)
        } else if r.quality.score >= 6.5 {
          let _ = Js.Array.push(r, groups.md)
        } else {
          let _ = Js.Array.push(r, groups.pr)
        }
      })
    }

    /* HTML Generation */
    let renderGroup = (label, count, className, icon) => {
      `<div class="upload-report-group">
         <div class="upload-report-icon">${icon}</div>
         <div class="upload-report-count ${className}">${Int.toString(count)}</div>
         <div class="upload-report-label">${label}</div>
       </div>`
    }

    let htmlStart = `<div class="upload-report-card">
       <div class="upload-report-header">
          <div class="upload-report-title">Batch Health</div>
          <div class="upload-report-score">${Float.toFixed(
        avgScore.contents,
        ~digits=1,
      )} <span class="upload-report-score-total">/ 10</span></div>
       </div>
       
       <div class="upload-report-grid">
          ${renderGroup("Excellent", Array.length(groups.ex), "text-success", "🌟")}
          ${renderGroup("Moderate", Array.length(groups.md), "text-warning", "📈")}
          ${renderGroup("Review", Array.length(groups.pr), "text-danger", "⚠️")}
       </div>
    </div>`

    let htmlAction = if Array.length(groups.pr) > 0 {
      let itemsHtml = Belt.Array.map(groups.pr, r => {
        let analysis = switch Nullable.toOption(r.quality.analysis) {
        | Some(a) => `<div class="upload-report-analysis">${a}</div>`
        | None => ""
        }
        `<div class="upload-report-item">
              <div class="upload-report-item-header">
                <span class="upload-report-filename">${r.newName}</span>
                <span class="upload-report-item-score">${Float.toString(r.quality.score)}</span>
              </div>
              ${analysis}
            </div>`
      })->Js.Array.joinWith("", _)

      `<div class="upload-report-action-container">
        <div class="upload-report-action-title">
          🚩 Action Required (${Int.toString(Array.length(groups.pr))})
        </div>
        <div class="upload-report-action-list">
          ${itemsHtml}
        </div>
      </div>`
    } else {
      ""
    }

    let htmlSkipped = if Array.length(report.skipped) > 0 {
      `<div class="upload-report-skipped-container">
           <div class="upload-report-skipped-badge">
             <span class="upload-report-skipped-icon">📑</span> ${Int.toString(
          Array.length(report.skipped),
        )} Duplicates Skipped
           </div>
        </div>`
    } else {
      ""
    }

    let contentHtml = htmlStart ++ htmlAction ++ htmlSkipped

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
      onClick: () => (),
      autoClose: Some(true),
    }

    /* iconHtml support removed from typed ModalConfig, merging into contentHtml or ignoring */
    let finalHtml = switch Some(`<div class="upload-report-main-icon">✨</div>`) {
    | Some(icon) => icon ++ contentHtml
    | None => contentHtml
    }

    let options: EventBus.modalConfig = {
      title: "Upload Summary",
      description: Some("Intelligent quality evaluation"),
      icon: None,
      contentHtml: Some(finalHtml),
      buttons: [btnDownload, btnStart],
      onClose: None,
      allowClose: Some(true),
    }
    EventBus.dispatch(ShowModal(options))
  }
}
