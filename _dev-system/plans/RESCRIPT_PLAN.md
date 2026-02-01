# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (3)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* [Nesting: 4.00, Density: 0.38, Coupling: 0.11] | Drag: 9.05 | LOC: 309/300  🎯 Target: Function: `rebuildUrl` (High Local Complexity (7.4). Logic heavy.)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 2.00, Density: 0.14, Coupling: 0.07] | Drag: 5.47 | LOC: 327/300  🎯 Target: Function: `pd` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/core/JsonParsers.res**
  - *Reason:* [Nesting: 2.00, Density: 0.75, Coupling: 0.03] | Drag: 6.62 | LOC: 470/300  🎯 Target: Function: `qualityAnalysis` (High Local Complexity (14.0). Logic heavy.)

---

