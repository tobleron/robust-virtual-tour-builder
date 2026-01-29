# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (1)
- [ ] `../../backend/src/pathfinder.rs`

---

## 🏗️ STRUCTURAL REFACTOR TASKS (1)
- [ ] **../../backend/src/services/media/analysis** (Action: Flatten Hierarchy)
  - *Reason:* Folder depth is 5. Flatten to reduce traversal tax.

---

## 🧩 MERGE TASKS (8)
### Merge Folder: `../../backend/src/middleware`
- **Reason:** Read Tax high (Score 4.00).
- **Files:**
  - `request_tracker.rs`
  - `quota_check.rs`
  - `auth.rs`
  - `mod.rs`
### Merge Folder: `../../backend/src/services/project`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `mod.rs`
  - `validate.rs`
  - `package.rs`
  - `load.rs`
### Merge Folder: `../../backend/src/services/auth`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `jwt.rs`
  - `mod.rs`
### Merge Folder: `../../backend/src/services/media/analysis`
- **Reason:** Read Tax high (Score 3.00).
- **Files:**
  - `quality.rs`
  - `exif.rs`
  - `mod.rs`
### Merge Folder: `../../src/components/ui`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `LucideIcons.res`
  - `Shadcn.res`
### Merge Folder: `../../backend/src/services/media`
- **Reason:** Read Tax high (Score 6.00).
- **Files:**
  - `resizing.rs`
  - `webp.rs`
  - `naming_old.rs`
  - `naming.rs`
  - `mod.rs`
  - `storage.rs`
### Merge Folder: `../../backend/src/services/geocoding`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `mod.rs`
  - `logic.rs`
### Merge Folder: `../../backend/src/services`
- **Reason:** Read Tax high (Score 5.00).
- **Files:**
  - `database.rs`
  - `mod.rs`
  - `upload_quota_tests.rs`
  - `upload_quota.rs`
  - `shutdown.rs`
