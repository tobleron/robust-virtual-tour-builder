import { ModalManager } from "../utils/ModalManager.js";

/**
 * UploadReport Component
 * 
 * Renders a dialog box summarizing the results of an image upload batch.
 * Includes quality assessment grouping and duplicate skipping information.
 */
export const UploadReport = {
  /**
   * Display the upload report modal.
   * 
   * @param {Object} report - The report object from store.state.lastUploadReport.
   * @param {Array} qualityResults - Array of quality analysis results.
   */
  show(report, qualityResults = []) {
    if (!report.success.length && !report.skipped.length) return;

    let avgScore = 0;
    const groups = {
      ex: { label: "Excellent", items: [], color: "#10b981", icon: "🌟" },
      md: { label: "Moderate", items: [], color: "#f59e0b", icon: "📈" },
      pr: { label: "Review", items: [], color: "#ef4444", icon: "⚠️" }
    };

    if (qualityResults.length > 0) {
      avgScore = qualityResults.reduce((acc, r) => acc + r.quality.score, 0) / qualityResults.length;
      qualityResults.forEach(r => {
        const score = r.quality?.score || 0;
        if (score >= 8.5) groups.ex.items.push(r);
        else if (score >= 6.5) groups.md.items.push(r);
        else groups.pr.items.push(r);
      });
    }

    let contentHtml = `
            <div style="background: #f8fafc; border-radius: 12px; padding: 14px; border: 1px solid #e2e8f0; margin-bottom: 16px; text-align: left;">
               <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
                  <div style="font-weight: 800; color: #1e293b; font-size: 10px; text-transform: uppercase; letter-spacing: 0.1em;">Batch Health</div>
                  <div style="font-size: 18px; font-weight: 900; color: #0f172a;">${avgScore.toFixed(1)} <span style="font-size: 10px; color: #94a3b8; font-weight: 500;">/ 10</span></div>
               </div>
               
               <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px;">
                  ${Object.values(groups).map(g => `
                    <div style="background: white; border: 1px solid #f1f5f9; padding: 8px 4px; border-radius: 10px; text-align: center;">
                       <div style="font-size: 14px; margin-bottom: 1px;">${g.icon}</div>
                       <div style="font-size: 14px; font-weight: 800; color: ${g.color}">${g.items.length}</div>
                       <div style="font-size: 8px; font-weight: 700; color: #64748b; text-transform: uppercase;">${g.label}</div>
                    </div>
                  `).join('')}
               </div>
            </div>
        `;

    if (groups.pr.items.length > 0) {
      contentHtml += `
              <div style="margin-bottom: 16px; text-align: left;">
                <div style="font-weight: 800; color: #991b1b; font-size: 10px; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 8px; display: flex; align-items: center; gap: 4px;">
                  🚩 Action Required (${groups.pr.items.length})
                </div>
                <div style="display: flex; flex-direction: column; gap: 5px; max-height: 120px; overflow-y: auto; padding-right: 2px;">
                  ${groups.pr.items.map(r => `
                    <div style="padding: 8px 10px; background: #fff1f2; border-radius: 8px; border: 1px solid #fecaca;">
                      <div style="display: flex; align-items: center; justify-content: space-between; gap: 8px;">
                        <span style="font-family: monospace; font-size: 10px; font-weight: 700; color: #991b1b; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${r.newName}</span>
                        <span style="font-weight: 900; color: #ef4444; font-size: 12px; flex-shrink: 0;">${r.quality.score}</span>
                      </div>
                      ${r.quality.analysis ? `<div style="font-size: 9px; color: #b91c1c; line-height: 1.2; margin-top: 2px;">${r.quality.analysis}</div>` : ''}
                    </div>
                  `).join('')}
                </div>
              </div>
            `;
    }

    if (report.skipped.length > 0) {
      contentHtml += `
            <div style="margin-bottom: 20px; text-align: center;">
               <div style="display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; background: #f1f5f9; border-radius: 20px; font-size: 10px; font-weight: 700; color: #64748b; border: 1px solid #e2e8f0;">
                 <span style="font-size: 12px;">📑</span> ${report.skipped.length} Duplicates Skipped
               </div>
            </div>
          `;
    }

    ModalManager.show({
      title: "Upload Summary",
      description: "Intelligent quality evaluation",
      iconHtml: `<div style="font-size: 48px; margin-bottom: 8px;">✨</div>`,
      contentHtml: contentHtml,
      buttons: [
        {
          label: "Download Data Report",
          class: "bg-slate-100 text-slate-700 hover:bg-slate-200",
          onClick: () => {
            // Access report from store if available
            const exifReport = window.store.state.exifReport;
            if (exifReport) {
              import("../systems/ExifReportGenerator.js").then(module => {
                module.downloadExifReport(exifReport);
              });
            } else {
              alert("Report is still generating... please wait a moment.");
            }
          },
          autoClose: false
        },
        { label: "Start Building", class: "btn-blue", autoClose: true }
      ]
    });
  }
};
