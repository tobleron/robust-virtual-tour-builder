# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (2)
- [ ] `../../backend/src/pathfinder.rs`
- [ ] `../../backend/src/services/media/analysis.rs`

---

## 🧩 MERGE TASKS (6)
### Merge Folder: `../../backend/src/middleware`
- **Reason:** Read Tax high (Score 4.00).
- **Files:**
  - `quota_check.rs`
  - `request_tracker.rs`
  - `mod.rs`
  - `auth.rs`
### Merge Folder: `../../backend/src/services`
- **Reason:** Read Tax high (Score 5.00).
- **Files:**
  - `shutdown.rs`
  - `upload_quota_tests.rs`
  - `mod.rs`
  - `upload_quota.rs`
  - `database.rs`
### Merge Folder: `../../backend/src/services/media`
- **Reason:** Read Tax high (Score 4.00).
- **Files:**
  - `analysis_quality.rs`
  - `naming_old.rs`
  - `webp.rs`
  - `mod.rs`
  - `analysis_exif.rs`
  - `storage.rs`
  - `resizing.rs`
  - `naming.rs`
### Merge Folder: `../../backend/src/services/geocoding`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `logic.rs`
  - `mod.rs`
### Merge Folder: `../../backend/src/services/project`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `package.rs`
  - `validate.rs`
  - `mod.rs`
  - `load.rs`
### Merge Folder: `../../backend/src/services/auth`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `jwt.rs`
  - `mod.rs`
