# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (5)
- [ ] `../../backend/src/pathfinder/graph.rs`
- [ ] `../../backend/src/pathfinder/algorithms.rs`
- [ ] `../../backend/src/pathfinder/tests.rs`
- [ ] `../../backend/src/pathfinder/timeline.rs`
- [ ] `../../backend/src/pathfinder/walk.rs`

---

## 🧩 MERGE TASKS (1)
### Merge Folder: `src/systems/Upload`
- **Reason:** Recursive Feature Pod: 3 files in subtree sum to 261 LOC (fits in context). Max Drag: 8.67
- **Files:**
  - `src/systems/Upload/../../src/systems/Upload/UploadProcessorQueue.res`
  - `src/systems/Upload/../../src/systems/Upload/UploadProcessorFinalizer.res`
  - `src/systems/Upload/../../src/systems/Upload/UploadProcessorUtils.res`
