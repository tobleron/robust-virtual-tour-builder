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
- **Reason:** Recursive Feature Pod: 3 files in subtree sum to 157 LOC (fits in context). Max Drag: 7.30
- **Files:**
  - `src/systems/Scene/Loader/../../src/systems/Scene/Loader/SceneLoaderReuse.res`
  - `src/systems/Scene/Loader/../../src/systems/Scene/Loader/SceneLoaderEvents.res`
  - `src/systems/Scene/Loader/../../src/systems/Scene/Loader/SceneLoaderConfig.res`
### Merge Folder: `src/systems/Project`
- **Reason:** Recursive Feature Pod: 3 files in subtree sum to 223 LOC (fits in context). Max Drag: 7.87
- **Files:**
  - `src/systems/Project/../../src/systems/Project/ProjectValidator.res`
  - `src/systems/Project/../../src/systems/Project/ProjectSaver.res`
  - `src/systems/Project/../../src/systems/Project/ProjectLoader.res`
