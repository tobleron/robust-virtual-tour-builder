# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (5)
- [ ] `../../backend/src/services/geocoding/cache.rs`
- [ ] `../../backend/src/pathfinder/timeline.rs`
- [ ] `../../backend/src/services/geocoding/osm.rs`
- [ ] `../../backend/src/auth/handlers.rs`
- [ ] `../../backend/src/pathfinder/walk.rs`

---

## 🧩 MERGE TASKS (3)
### Merge Folder: `backend/src/middleware`
- **Reason:** Recursive Feature Pod: 3 files in subtree sum to 213 LOC (fits in context). Max Drag: 3.03
- **Files:**
  - `backend/src/middleware/../../backend/src/middleware/mod.rs`
  - `backend/src/middleware/../../backend/src/middleware/request_tracker.rs`
  - `backend/src/middleware/../../backend/src/middleware/quota_check.rs`
### Merge Folder: `backend/src/auth`
- **Reason:** Recursive Feature Pod: 4 files in subtree sum to 288 LOC (fits in context). Max Drag: 3.05
- **Files:**
  - `backend/src/auth/../../backend/src/auth/middleware.rs`
  - `backend/src/auth/../../backend/src/auth/handlers.rs`
  - `backend/src/auth/../../backend/src/auth/service.rs`
  - `backend/src/auth/../../backend/src/auth/mod.rs`
### Merge Folder: `../../backend/src/pathfinder`
- **Reason:** Read Tax high (Score 3.00). Projected Limit: 300 (Drag 3.47)
- **Files:**
  - `../../backend/src/pathfinder/utils.rs`
  - `../../backend/src/pathfinder/graph.rs`
  - `../../backend/src/pathfinder/algorithms.rs`
