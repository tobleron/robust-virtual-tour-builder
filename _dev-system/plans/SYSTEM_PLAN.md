# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (2)
- [ ] `../../src/hooks/UseIsInteractionPermitted.res`
- [ ] `../../src/hooks/UseThrottledAction.res`

---

## 🧩 MERGE TASKS (1)
### Merge Folder: `src/hooks`
- **Reason:** Recursive Feature Pod: 2 files in subtree sum to 71 LOC (fits in context). Max Drag: 9.58
- **Files:**
  - `src/hooks/../../src/hooks/UseIsInteractionPermitted.res`
  - `src/hooks/../../src/hooks/UseThrottledAction.res`
