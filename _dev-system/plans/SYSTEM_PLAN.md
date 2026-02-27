# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (3)
- [ ] `../../backend/src/services/project/export_session.rs`
- [ ] `../../backend/src/services/project/export_upload_runtime.rs`
- [ ] `../../backend/src/services/project/export_upload.rs`

---

## 🧩 MERGE TASKS (1)
### Merge Folder: `backend/src/services/geocoding`
- **Reason:** Recursive Feature Pod: 2 files in subtree sum to 178 LOC (fits in context). Max Drag: 4.14
- **Files:**
  - `backend/src/services/geocoding/../../backend/src/services/geocoding/mod.rs`
  - `backend/src/services/geocoding/../../backend/src/services/geocoding/osm.rs`
