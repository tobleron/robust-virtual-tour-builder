# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (5)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* [Nesting: 4.20, Density: 0.21, Coupling: 0.10] | Drag: 5.41 | LOC: 395/300  🎯 Target: Function: `finalToken` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/core/SceneMutations.res**
  - *Reason:* [Nesting: 5.40, Density: 0.26, Coupling: 0.04] | Drag: 6.68 | LOC: 394/300  🎯 Target: Function: `getDeletedIds` (High Local Complexity (3.5). Logic heavy.)
- [ ] **../../src/systems/ViewerSystem.res**
  - *Reason:* [Nesting: 3.60, Density: 0.06, Coupling: 0.08] | Drag: 4.68 | LOC: 390/300  🎯 Target: Function: `elOpt` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 5.40, Density: 0.29, Coupling: 0.10] | Drag: 6.69 | LOC: 407/300  🎯 Target: Function: `finalState` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* [Nesting: 3.00, Density: 0.04, Coupling: 0.09] | Drag: 4.10 | LOC: 398/300  🎯 Target: Function: `make` (High Local Complexity (13.5). Logic heavy.)

---

