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
    let renderGroup = (label, count, color, icon) => {
      `<div style="background: white; border: 1px solid #f1f5f9; padding: 8px 4px; border-radius: 10px; text-align: center;">
         <div style="font-size: 14px; margin-bottom: 1px;">${icon}</div>
         <div style="font-size: 14px; font-weight: 800; color: ${color}">${Int.toString(
          count,
        )}</div>
         <div style="font-size: 8px; font-weight: 700; color: #64748b; text-transform: uppercase;">${label}</div>
       </div>`
    }

    let htmlStart = `<div style="background: #f8fafc; border-radius: 12px; padding: 14px; border: 1px solid #e2e8f0; margin-bottom: 16px; text-align: left;">
       <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
          <div style="font-weight: 800; color: #1e293b; font-size: 10px; text-transform: uppercase; letter-spacing: 0.1em;">Batch Health</div>
          <div style="font-size: 18px; font-weight: 900; color: #0f172a;">${Float.toFixed(
        avgScore.contents,
        ~digits=1,
      )} <span style="font-size: 10px; color: #475569; font-weight: 500;">/ 10</span></div>
       </div>
       
       <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px;">
          ${renderGroup("Excellent", Array.length(groups.ex), "#047857", "🌟")}
          ${renderGroup("Moderate", Array.length(groups.md), "#b45309", "📈")}
          ${renderGroup("Review", Array.length(groups.pr), "#dc2626", "⚠️")}
       </div>
    </div>`

    let htmlAction = if Array.length(groups.pr) > 0 {
      let itemsHtml = Belt.Array.map(groups.pr, r => {
        let analysis = switch Nullable.toOption(r.quality.analysis) {
        | Some(a) =>
          `<div style="font-size: 9px; color: #b91c1c; line-height: 1.2; margin-top: 2px;">${a}</div>`
        | None => ""
        }
        `<div style="padding: 8px 10px; background: #fff1f2; border-radius: 8px; border: 1px solid #fecaca;">
              <div style="display: flex; align-items: center; justify-content: space-between; gap: 8px;">
                <span style="font-family: monospace; font-size: 10px; font-weight: 700; color: #991b1b; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${r.newName}</span>
                <span style="font-weight: 900; color: #ef4444; font-size: 12px; flex-shrink: 0;">${Float.toString(
            r.quality.score,
          )}</span>
              </div>
              ${analysis}
            </div>`
      })->Js.Array.joinWith("", _)

      `<div style="margin-bottom: 16px; text-align: left;">
        <div style="font-weight: 800; color: #991b1b; font-size: 10px; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 8px; display: flex; align-items: center; gap: 4px;">
          🚩 Action Required (${Int.toString(Array.length(groups.pr))})
        </div>
        <div style="display: flex; flex-direction: column; gap: 5px; max-height: 120px; overflow-y: auto; padding-right: 2px;">
          ${itemsHtml}
        </div>
      </div>`
    } else {
      ""
    }

    let htmlSkipped = if Array.length(report.skipped) > 0 {
      `<div style="margin-bottom: 20px; text-align: center;">
           <div style="display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; background: #f1f5f9; border-radius: 20px; font-size: 10px; font-weight: 700; color: #64748b; border: 1px solid #e2e8f0;">
             <span style="font-size: 12px;">📑</span> ${Int.toString(
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
        | None => EventBus.dispatch(ShowNotification("Report is still generating... please wait a moment.", #Info))
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
    let finalHtml = switch Some(`<div style="font-size: 48px; margin-bottom: 8px;">✨</div>`) {
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
