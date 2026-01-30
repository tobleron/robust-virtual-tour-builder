# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (3)
- [ ] `../../backend/src/services/geocoding.rs`
- [ ] `../../backend/src/pathfinder/graph.rs`
- [ ] `../../backend/src/pathfinder/algorithms.rs`

---

## 🧩 MERGE TASKS (2)
### Merge Folder: `backend/src/pathfinder`
- **Reason:** Recursive Feature Pod: 2 files in subtree sum to 485 LOC (fits in context). Max Drag: 2.45
- **Files:**
  - `../../backend/src/pathfinder/graph.rs`
  - `../../backend/src/pathfinder/algorithms.rs`
### Merge Folder: `src/utils`
- **Reason:** Recursive Feature Pod: 3 files in subtree sum to 448 LOC (fits in context). Max Drag: 4.36
- **Files:**
  - `../../src/utils/TourLogic.res`
  - `../../src/utils/GeoUtils.res`
  - `../../src/utils/PathInterpolation.res`
