# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (4)
- [ ] `../../backend/src/pathfinder/walk.rs`
- [ ] `../../backend/src/pathfinder/timeline.rs`
- [ ] `../../backend/src/services/geocoding/cache.rs`
- [ ] `../../backend/src/services/geocoding/osm.rs`

---

## 🏗️ STRUCTURAL REFACTOR TASKS (1)
- [ ] **auth** (Action: Vertical Slice)
  - *Reason:* Feature fragmented across 3 files: [`../../backend/src/api/auth.rs`, `../../backend/src/middleware/auth.rs`, `../../backend/src/services/auth.rs`]

---

## 🧩 MERGE TASKS (1)
### Merge Folder: `../../backend/src/pathfinder`
- **Reason:** Read Tax high (Score 3.00). Projected Limit: 300 (Drag 3.47)
- **Files:**
  - `../../backend/src/pathfinder/algorithms.rs`
  - `../../backend/src/pathfinder/utils.rs`
  - `../../backend/src/pathfinder/graph.rs`
