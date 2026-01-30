# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (3)
- [ ] `../../backend/src/pathfinder/algorithms.rs`
- [ ] `../../backend/src/pathfinder/graph.rs`
- [ ] `../../backend/src/services/geocoding.rs`

---

## 🧩 MERGE TASKS (1)
### Merge Folder: `backend/src/pathfinder`
- **Reason:** Recursive Feature Pod: 2 files in subtree sum to 482 LOC (fits in context). Max Drag: 2.45
- **Files:**
  - `../../backend/src/pathfinder/algorithms.rs`
  - `../../backend/src/pathfinder/graph.rs`
