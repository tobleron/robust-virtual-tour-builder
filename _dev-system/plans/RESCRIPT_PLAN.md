# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (4)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 4.20, Density: 0.30, Coupling: 0.10] | Drag: 5.50 | LOC: 385/300  🎯 Target: Function: `finalState` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/core/SceneMutations.res**
  - *Reason:* [Nesting: 6.60, Density: 0.48, Coupling: 0.04] | Drag: 8.11 | LOC: 361/300  🎯 Target: Function: `syncSceneNames` (High Local Complexity (5.6). Logic heavy.)
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* [Nesting: 7.80, Density: 0.23, Coupling: 0.09] | Drag: 9.14 | LOC: 370/300  🎯 Target: Function: `make` (High Local Complexity (23.2). Logic heavy.)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* [Nesting: 4.80, Density: 0.20, Coupling: 0.10] | Drag: 6.00 | LOC: 393/300  🎯 Target: Function: `finalToken` (High Local Complexity (2.0). Logic heavy.)

---

