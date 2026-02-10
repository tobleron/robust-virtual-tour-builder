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
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* [Nesting: 7.80, Density: 0.23, Coupling: 0.09] | Drag: 9.13 | LOC: 391/300  🎯 Target: Function: `make` (High Local Complexity (24.1). Logic heavy.)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 4.20, Density: 0.30, Coupling: 0.10] | Drag: 5.50 | LOC: 385/300  🎯 Target: Function: `finalState` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/systems/UploadProcessorLogic.res**
  - *Reason:* [Nesting: 2.40, Density: 0.04, Coupling: 0.12] | Drag: 3.44 | LOC: 356/300  🎯 Target: Function: `getNotificationType` (High Local Complexity (4.0). Logic heavy.)

---

