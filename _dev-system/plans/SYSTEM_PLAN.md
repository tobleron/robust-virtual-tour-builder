# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🧩 MERGE TASKS (2)
### Merge Folder: `src/systems/Scene/Loader`
- **Reason:** Recursive Feature Pod: 3 files in subtree sum to 156 LOC (fits in context). Max Drag: 6.80
- **Files:**
  - `src/systems/Scene/Loader/../../src/systems/Scene/Loader/SceneLoaderConfig.res`
  - `src/systems/Scene/Loader/../../src/systems/Scene/Loader/SceneLoaderEvents.res`
  - `src/systems/Scene/Loader/../../src/systems/Scene/Loader/SceneLoaderReuse.res`
### Merge Folder: `../../src/systems/Project`
- **Reason:** Read Tax high (Score 3.00). Projected Limit: 300 (Drag 4.92)
- **Files:**
  - `../../src/systems/Project/ProjectSaver.res`
  - `../../src/systems/Project/ProjectLoader.res`
  - `../../src/systems/Project/ProjectValidator.res`
