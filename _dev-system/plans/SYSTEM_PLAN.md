# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (3)
- [ ] `../../backend/src/auth/middleware.rs`
- [ ] `../../backend/src/auth/jwt.rs`
- [ ] `../../backend/src/startup/logging.rs`

---

## 🧩 MERGE TASKS (1)
### Merge Folder: `backend/src/startup`
- **Reason:** Recursive Feature Pod: 3 files in subtree sum to 119 LOC (fits in context). Max Drag: 2.69
- **Files:**
  - `backend/src/startup/../../backend/src/startup/logging.rs`
  - `backend/src/startup/../../backend/src/startup/mod.rs`
  - `backend/src/startup/../../backend/src/startup/config.rs`
