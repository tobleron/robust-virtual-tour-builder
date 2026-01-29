# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (2)
- [ ] `../../src/index.js`
- [ ] `../../backend/src/pathfinder.rs`

---

## 🏗️ STRUCTURAL REFACTOR TASKS (1)
- [ ] **../../backend/src/services/media/analysis** (Action: Flatten Hierarchy)
  - *Reason:* Folder depth is 5. Flatten to reduce traversal tax.

---

## 🧩 MERGE TASKS (11)
### Merge Folder: `../../scripts`
- **Reason:** Read Tax high (Score 7.00).
- **Files:**
  - `test-logging.js`
  - `increment-build.js`
  - `debug-connectivity.js`
  - `update-changelog.js`
  - `update-version.js`
  - `update-readme.js`
  - `bump-version.js`
### Merge Folder: `../../backend/src/services/auth`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `mod.rs`
  - `jwt.rs`
### Merge Folder: `../../css`
- **Reason:** Read Tax high (Score 3.50).
- **Files:**
  - `tailwind.css`
  - `style.css`
  - `legacy.css`
  - `base.css`
  - `animations.css`
  - `layout.css`
  - `variables.css`
### Merge Folder: `../../backend/src/services/geocoding`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `mod.rs`
  - `logic.rs`
### Merge Folder: `../..`
- **Reason:** Read Tax high (Score 6.00).
- **Files:**
  - `rescript.json`
  - `package.json`
  - `jsconfig.json`
  - `index.html`
  - `tailwind.config.js`
  - `postcss.config.js`
### Merge Folder: `../../backend/src/services/project`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `validate.rs`
  - `load.rs`
  - `mod.rs`
  - `package.rs`
### Merge Folder: `../../backend/src/middleware`
- **Reason:** Read Tax high (Score 4.00).
- **Files:**
  - `auth.rs`
  - `quota_check.rs`
  - `request_tracker.rs`
  - `mod.rs`
### Merge Folder: `../../src/i18n/locales`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `en.json`
  - `es.json`
### Merge Folder: `../../backend/src/services/media`
- **Reason:** Read Tax high (Score 6.00).
- **Files:**
  - `webp.rs`
  - `storage.rs`
  - `naming_old.rs`
  - `naming.rs`
  - `resizing.rs`
  - `mod.rs`
### Merge Folder: `../../backend/src/services`
- **Reason:** Read Tax high (Score 5.00).
- **Files:**
  - `database.rs`
  - `shutdown.rs`
  - `mod.rs`
  - `upload_quota.rs`
  - `upload_quota_tests.rs`
### Merge Folder: `../../backend/src/services/media/analysis`
- **Reason:** Read Tax high (Score 3.00).
- **Files:**
  - `mod.rs`
  - `exif.rs`
  - `quality.rs`
