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

        const modal = document.createElement("div");
        modal.style = "position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(15,23,42,0.6); z-index:11000; display:flex; align-items:center; justify-content:center; backdrop-filter:blur(8px); transition: all 0.3s ease-in-out;";

        const content = document.createElement("div");
        content.style = "background:white; padding:24px; border-radius:20px; max-width:360px; width:95%; box-shadow:0 25px 50px -12px rgba(0,0,0,0.5); font-family:'Outfit',sans-serif; max-height: 90vh; overflow-y: auto; border: 1px solid rgba(255,255,255,0.1); transition: all 0.3s ease; transform: scale(0.95); opacity: 0;";

        // Add entrance animation
        setTimeout(() => {
            content.style.transform = "scale(1)";
            content.style.opacity = "1";
        }, 10);

        let html = `
      <div style="text-align: center; margin-bottom: 20px;">
        <div style="font-size: 28px; margin-bottom: 4px;">✨</div>
        <h2 style="margin:0; color:#0f172a; font-size: 18px; font-weight: 800;">Upload Summary</h2>
        <p style="margin: 2px 0 0 0; color: #64748b; font-size: 12px; font-weight: 500;">Intelligent quality evaluation</p>
      </div>
    `;

        // --- Quality Grouping Logic ---
        if (qualityResults.length > 0) {
            const avgScore = qualityResults.reduce((acc, r) => acc + r.quality.score, 0) / qualityResults.length;

            const groups = {
                ex: { label: "Excellent", items: [], color: "#10b981", icon: "🌟" },
                md: { label: "Moderate", items: [], color: "#f59e0b", icon: "📈" },
                pr: { label: "Review", items: [], color: "#ef4444", icon: "⚠️" }
            };

            qualityResults.forEach(r => {
                if (r.quality.score >= 8.5) groups.ex.items.push(r);
                else if (r.quality.score >= 6.5) groups.md.items.push(r);
                else groups.pr.items.push(r);
            });

            html += `
        <div style="background: #f8fafc; border-radius: 12px; padding: 14px; border: 1px solid #e2e8f0; margin-bottom: 16px;">
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
                html += `
          <div style="margin-bottom: 16px;">
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
        }

        if (report.skipped.length > 0) {
            html += `
        <div style="margin-bottom: 20px; text-align: center;">
           <div style="display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; background: #f1f5f9; border-radius: 20px; font-size: 10px; font-weight: 700; color: #64748b; border: 1px solid #e2e8f0;">
             <span style="font-size: 12px;">📑</span> ${report.skipped.length} Duplicates Skipped
           </div>
        </div>
      `;
        }

        html += `<button id="close-report" style="width:100%; padding: 14px; background:#003da5; color:white; border:none; border-radius:12px; font-weight:800; font-size: 14px; cursor:pointer; transition:all 0.2s; box-shadow: 0 4px 12px rgba(0,61,165,0.25);">Start Building</button>`;

        content.innerHTML = html;
        modal.appendChild(content);
        document.body.appendChild(modal);

        const btn = content.querySelector("#close-report");
        btn.onclick = () => {
            content.style.transform = "scale(0.95)";
            content.style.opacity = "0";
            modal.style.opacity = "0";
            setTimeout(() => modal.remove(), 300);
        };
        btn.onmouseover = () => {
            btn.style.background = "#002a70";
            btn.style.transform = "translateY(-1px)";
            btn.style.boxShadow = "0 6px 20px rgba(0,61,165,0.3)";
        };
        btn.onmouseout = () => {
            btn.style.background = "#003da5";
            btn.style.transform = "translateY(0)";
            btn.style.boxShadow = "0 4px 12px rgba(0,61,165,0.25)";
        };
    }
};
