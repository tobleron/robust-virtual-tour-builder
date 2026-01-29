# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines.
*   **Drag:** Complexity multiplier (1.0 = base).
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead for switching context between files.
*   **AI Context Fog:** High-complexity peak regions within a file.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (1)
- [ ] `../../backend/src/pathfinder.rs`

---

## 🏗️ STRUCTURAL REFACTOR TASKS (1)
- [ ] **../../backend/src/services/media/analysis** (Action: Flatten Hierarchy)
  - *Reason:* Folder depth is 5. Flatten to reduce traversal tax.

---

## 🧩 MERGE TASKS (8)
### Merge Folder: `../../backend/src/services/auth`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `mod.rs`
  - `jwt.rs`
### Merge Folder: `../../backend/src/services/media`
- **Reason:** Read Tax high (Score 6.00).
- **Files:**
  - `naming.rs`
  - `mod.rs`
  - `storage.rs`
  - `naming_old.rs`
  - `webp.rs`
  - `resizing.rs`
### Merge Folder: `../../backend/src/services/project`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `mod.rs`
  - `load.rs`
  - `validate.rs`
  - `package.rs`
### Merge Folder: `../../src/components/ui`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `Shadcn.res`
  - `LucideIcons.res`
### Merge Folder: `../../backend/src/services/geocoding`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `mod.rs`
  - `logic.rs`
### Merge Folder: `../../backend/src/services/media/analysis`
- **Reason:** Read Tax high (Score 3.00).
- **Files:**
  - `exif.rs`
  - `mod.rs`
  - `quality.rs`
### Merge Folder: `../../backend/src/middleware`
- **Reason:** Read Tax high (Score 4.00).
- **Files:**
  - `quota_check.rs`
  - `mod.rs`
  - `auth.rs`
  - `request_tracker.rs`
### Merge Folder: `../../backend/src/services`
- **Reason:** Read Tax high (Score 5.00).
- **Files:**
  - `upload_quota.rs`
  - `shutdown.rs`
  - `upload_quota_tests.rs`
  - `database.rs`
  - `mod.rs`
