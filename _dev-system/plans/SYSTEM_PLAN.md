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

## 🧩 MERGE TASKS (7)
### Merge Folder: `../../backend/src/services/media`
- **Reason:** Read Tax high (Score 4.00).
- **Files:**
  - `mod.rs`
  - `analysis_quality.rs`
  - `storage.rs`
  - `webp.rs`
  - `analysis_exif.rs`
  - `naming_old.rs`
  - `resizing.rs`
  - `naming.rs`
### Merge Folder: `../../backend/src/services/auth`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `jwt.rs`
  - `mod.rs`
### Merge Folder: `../../backend/src/services`
- **Reason:** Read Tax high (Score 5.00).
- **Files:**
  - `mod.rs`
  - `upload_quota.rs`
  - `database.rs`
  - `shutdown.rs`
  - `upload_quota_tests.rs`
### Merge Folder: `../../backend/src/services/project`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `mod.rs`
  - `load.rs`
  - `package.rs`
  - `validate.rs`
### Merge Folder: `../../src/components/ui`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `Shadcn.res`
  - `LucideIcons.res`
### Merge Folder: `../../backend/src/services/geocoding`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `logic.rs`
  - `mod.rs`
### Merge Folder: `../../backend/src/middleware`
- **Reason:** Read Tax high (Score 4.00).
- **Files:**
  - `mod.rs`
  - `quota_check.rs`
  - `auth.rs`
  - `request_tracker.rs`
