# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🧩 MERGE TASKS (1)
### Merge Folder: `src/systems/Api`
- **Reason:** Recursive Feature Pod: 3 files in subtree sum to 294 LOC (fits in context). Max Drag: 6.93
- **Files:**
  - `../../src/systems/Api/AuthenticatedClient.res`
  - `../../src/systems/Api/MediaApi.res`
  - `../../src/systems/Api/ApiTypes.res`
