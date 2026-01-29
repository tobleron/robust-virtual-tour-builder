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
### Merge Folder: `../../backend/src/services/media/analysis`
- **Reason:** Read Tax high (Score 3.00).
- **Files:**
  - `quality.rs`
  - `exif.rs`
  - `mod.rs`
### Merge Folder: `../../backend/src/services/media`
- **Reason:** Read Tax high (Score 6.00).
- **Files:**
  - `naming_old.rs`
  - `resizing.rs`
  - `storage.rs`
  - `mod.rs`
  - `naming.rs`
  - `webp.rs`
### Merge Folder: `../../backend/src/middleware`
- **Reason:** Read Tax high (Score 4.00).
- **Files:**
  - `auth.rs`
  - `quota_check.rs`
  - `mod.rs`
  - `request_tracker.rs`
### Merge Folder: `../../backend/src/services/geocoding`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `mod.rs`
  - `logic.rs`
### Merge Folder: `../../src/components/ui`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `Shadcn.res`
  - `LucideIcons.res`
### Merge Folder: `../../backend/src/services/project`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `load.rs`
  - `mod.rs`
  - `validate.rs`
  - `package.rs`
### Merge Folder: `../../backend/src/services/auth`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `jwt.rs`
  - `mod.rs`
### Merge Folder: `../../backend/src/services`
- **Reason:** Read Tax high (Score 5.00).
- **Files:**
  - `database.rs`
  - `shutdown.rs`
  - `upload_quota.rs`
  - `mod.rs`
  - `upload_quota_tests.rs`
