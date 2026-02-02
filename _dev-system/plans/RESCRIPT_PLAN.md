# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (4)
- [ ] **../../src/systems/ViewerSystem.res**
  - *Reason:* [Nesting: 3.50, Density: 0.65, Coupling: 0.09] | Drag: 9.05 | LOC: 308/300  🎯 Target: Function: `reset` (High Local Complexity (4.1). Logic heavy.)
- [ ] **../../src/core/JsonParsers.res**
  - *Reason:* [Nesting: 2.00, Density: 0.75, Coupling: 0.03] | Drag: 6.62 | LOC: 470/300  🎯 Target: Function: `qualityAnalysis` (High Local Complexity (14.0). Logic heavy.)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* [Nesting: 4.00, Density: 0.38, Coupling: 0.11] | Drag: 9.06 | LOC: 311/300  🎯 Target: Function: `rebuildUrl` (High Local Complexity (8.4). Logic heavy.)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 2.00, Density: 0.14, Coupling: 0.07] | Drag: 5.47 | LOC: 327/300  🎯 Target: Function: `pd` (High Local Complexity (2.0). Logic heavy.)

---

