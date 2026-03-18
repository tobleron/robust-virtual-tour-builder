# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Estimated modification-risk multiplier. Higher Drag means edits are more likely to miss state, flow, or boundary details.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🧩 MERGE TASKS (2)
### Merge Folder: `../../src/systems/Viewer`
- **Reason:** Read Tax high (Score 3.00). Projected Limit: 400 (Drag 5.06)
- **Files:**
  - `src/systems/Viewer/ViewerPool.res`
  - `src/systems/Viewer/ViewerFollow.res`
  - `src/systems/Viewer/ViewerAdapter.res`
### Merge Folder: `../../src/systems/ExifReport`
- **Reason:** Read Tax high (Score 4.00). Projected Limit: 400 (Drag 3.92)
- **Files:**
  - `src/systems/ExifReport/ExifReportGeneratorLogicGroups.res`
  - `src/systems/ExifReport/ExifReportGeneratorLogicTypes.res`
  - `src/systems/ExifReport/ExifReportGeneratorLogicLocation.res`
  - `src/systems/ExifReport/ExifReportGeneratorLogicExtraction.res`
