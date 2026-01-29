# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🧩 MERGE TASKS (6)
### Merge Folder: `backend/src/services/project`
- **Reason:** Recursive Feature Pod: 4 files in subtree sum to 605 LOC (fits in context).
- **Files:**
  - `../../backend/src/services/project/mod.rs`
  - `../../backend/src/services/project/validate.rs`
  - `../../backend/src/services/project/load.rs`
  - `../../backend/src/services/project/package.rs`
### Merge Folder: `backend/src/services/auth`
- **Reason:** Recursive Feature Pod: 2 files in subtree sum to 111 LOC (fits in context).
- **Files:**
  - `../../backend/src/services/auth/mod.rs`
  - `../../backend/src/services/auth/jwt.rs`
### Merge Folder: `backend/src/services/media`
- **Reason:** Recursive Feature Pod: 9 files in subtree sum to 791 LOC (fits in context).
- **Files:**
  - `../../backend/src/services/media/naming.rs`
  - `../../backend/src/services/media/resizing.rs`
  - `../../backend/src/services/media/webp.rs`
  - `../../backend/src/services/media/analysis_exif.rs`
  - `../../backend/src/services/media/naming_old.rs`
  - `../../backend/src/services/media/mod.rs`
  - `../../backend/src/services/media/storage.rs`
  - `../../backend/src/services/media/analysis_quality.rs`
  - `../../backend/src/services/media/analysis.rs`
### Merge Folder: `backend/src/services/geocoding`
- **Reason:** Recursive Feature Pod: 2 files in subtree sum to 375 LOC (fits in context).
- **Files:**
  - `../../backend/src/services/geocoding/logic.rs`
  - `../../backend/src/services/geocoding/mod.rs`
### Merge Folder: `backend/src/middleware`
- **Reason:** Recursive Feature Pod: 4 files in subtree sum to 375 LOC (fits in context).
- **Files:**
  - `../../backend/src/middleware/mod.rs`
  - `../../backend/src/middleware/quota_check.rs`
  - `../../backend/src/middleware/auth.rs`
  - `../../backend/src/middleware/request_tracker.rs`
### Merge Folder: `../../backend/src/services/auth`
- **Reason:** Read Tax high (Score 2.00). Projected Limit: 204 (Drag 2.38)
- **Files:**
  - `mod.rs`
  - `jwt.rs`
