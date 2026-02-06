# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (3)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 4.20, Density: 0.31, Coupling: 0.10] | Drag: 5.51 | LOC: 373/300  🎯 Target: Function: `finalState` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* [Nesting: 4.80, Density: 0.21, Coupling: 0.11] | Drag: 6.01 | LOC: 371/300  🎯 Target: Function: `finalToken` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/core/SceneMutations.res**
  - *Reason:* [Nesting: 6.60, Density: 0.49, Coupling: 0.04] | Drag: 8.11 | LOC: 363/300  🎯 Target: Function: `syncSceneNames` (High Local Complexity (5.6). Logic heavy.)

---

