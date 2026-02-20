# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (2)
- [ ] **../../src/systems/Api/AuthenticatedClient.res**
  - *Reason:* [Nesting: 2.40, Density: 0.18, Coupling: 0.09] | Drag: 3.64 | LOC: 388/300  🎯 Target: Function: `getTimeoutMs` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/systems/Api/ProjectApi.res**
  - *Reason:* [Nesting: 1.20, Density: 0.00, Coupling: 0.05] | Drag: 2.20 | LOC: 437/300

---

