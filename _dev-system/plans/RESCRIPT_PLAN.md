# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (3)
- [ ] **../../src/core/JsonParsers.res**
  - *Reason:* [Nesting: 2.00, Density: 0.28, Coupling: 0.04] | Drag: 4.47 | LOC: 379/300  🎯 Target: Function: `file` (High Local Complexity (3.0). Logic heavy.)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* [Nesting: 3.00, Density: 0.27, Coupling: 0.09] | Drag: 7.20 | LOC: 358/300  🎯 Target: Function: `safeEncodeFile` (High Local Complexity (3.0). Logic heavy.)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 2.00, Density: 0.14, Coupling: 0.07] | Drag: 5.47 | LOC: 327/300  🎯 Target: Function: `pd` (High Local Complexity (2.0). Logic heavy.)

---

