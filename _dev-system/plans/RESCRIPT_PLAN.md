# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (2)
- [ ] **../../src/core/JsonParsers.res**
  - *Reason:* [Nesting: 2.00, Density: 0.48, Coupling: 0.04] | Drag: 5.80 | LOC: 380/300  🎯 Target: Function: `hotspot` (High Local Complexity (11.0). Logic heavy.)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* [Nesting: 4.00, Density: 0.30, Coupling: 0.09] | Drag: 8.92 | LOC: 392/300  🎯 Target: Function: `rebuildUrl` (High Local Complexity (8.4). Logic heavy.)

---

