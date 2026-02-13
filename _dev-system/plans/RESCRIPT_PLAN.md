# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (8)
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* [Nesting: 3.00, Density: 0.04, Coupling: 0.08] | Drag: 4.10 | LOC: 412/300  🎯 Target: Function: `make` (High Local Complexity (15.5). Logic heavy.)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 5.40, Density: 0.28, Coupling: 0.10] | Drag: 6.68 | LOC: 408/300  🎯 Target: Function: `finalState` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* [Nesting: 4.20, Density: 0.20, Coupling: 0.10] | Drag: 5.40 | LOC: 402/300  🎯 Target: Function: `finalToken` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/systems/Scene/SceneLoader.res**
  - *Reason:* [Nesting: 1.80, Density: 0.03, Coupling: 0.08] | Drag: 2.85 | LOC: 377/300
- [ ] **../../src/systems/UploadProcessorLogic.res**
  - *Reason:* [Nesting: 2.40, Density: 0.04, Coupling: 0.11] | Drag: 3.44 | LOC: 378/300  🎯 Target: Function: `getNotificationType` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/systems/ViewerSystem.res**
  - *Reason:* [Nesting: 3.60, Density: 0.06, Coupling: 0.08] | Drag: 4.68 | LOC: 390/300  🎯 Target: Function: `elOpt` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/utils/OperationJournal.res**
  - *Reason:* [Nesting: 1.80, Density: 0.02, Coupling: 0.04] | Drag: 2.82 | LOC: 405/300  🎯 Target: Function: `isTerminalStatus` (High Local Complexity (3.0). Logic heavy.)
- [ ] **../../src/core/SceneMutations.res**
  - *Reason:* [Nesting: 5.40, Density: 0.26, Coupling: 0.04] | Drag: 6.68 | LOC: 394/300  🎯 Target: Function: `getDeletedIds` (High Local Complexity (3.5). Logic heavy.)

---

