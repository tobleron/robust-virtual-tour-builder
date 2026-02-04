# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🧩 MERGE TASKS (3)
### Merge Folder: `../../tests`
- **Reason:** Read Tax high (Score 2.00). Projected Limit: 300 (Drag 9.40)
- **Files:**
  - `../../tests/vitest-setup.js`
  - `../../tests/node-setup.js`
### Merge Folder: `../../tests/unit`
- **Reason:** Read Tax high (Score 2.00). Projected Limit: 300 (Drag 4.60)
- **Files:**
  - `../../tests/unit/LabelMenu_v.test.setup.jsx`
  - `../../tests/unit/Components_v.test.setup.jsx`
### Merge Folder: `../../tests/unit`
- **Reason:** Read Tax high (Score 2.00). Projected Limit: 300 (Drag 2.20)
- **Files:**
  - `../../tests/unit/UploadProcessor_v.test.setup.js`
  - `../../tests/unit/HotspotLine_v.test.setup.js`
