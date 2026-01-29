# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (1)
- [ ] `../../src/index.js`

---

## 🧩 MERGE TASKS (1)
### Merge Folder: `../../backend/src/services/auth`
- **Reason:** Read Tax high (Score 2.00). Projected Limit: 203 (Drag 2.38)
- **Files:**
  - `mod.rs`
  - `jwt.rs`
