# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (2)
- [ ] `../../backend/src/services/media/analysis.rs`
- [ ] `../../backend/src/pathfinder.rs`

---

## 🧩 MERGE TASKS (7)
### Merge Folder: `../../backend/src/services/auth`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `mod.rs`
  - `jwt.rs`
### Merge Folder: `../../backend/src/services/project`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `mod.rs`
  - `package.rs`
  - `validate.rs`
  - `load.rs`
### Merge Folder: `../../backend/src/services/geocoding`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `logic.rs`
  - `mod.rs`
### Merge Folder: `../../src/components/ui`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `Shadcn.res`
  - `LucideIcons.res`
### Merge Folder: `../../backend/src/middleware`
- **Reason:** Read Tax high (Score 4.00).
- **Files:**
  - `request_tracker.rs`
  - `mod.rs`
  - `quota_check.rs`
  - `auth.rs`
### Merge Folder: `../../backend/src/services`
- **Reason:** Read Tax high (Score 5.00).
- **Files:**
  - `upload_quota_tests.rs`
  - `shutdown.rs`
  - `upload_quota.rs`
  - `mod.rs`
  - `database.rs`
### Merge Folder: `../../backend/src/services/media`
- **Reason:** Read Tax high (Score 4.00).
- **Files:**
  - `resizing.rs`
  - `naming.rs`
  - `analysis_exif.rs`
  - `storage.rs`
  - `webp.rs`
  - `analysis_quality.rs`
  - `mod.rs`
  - `naming_old.rs`
