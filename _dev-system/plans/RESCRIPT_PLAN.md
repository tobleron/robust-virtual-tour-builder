# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (1)
- [ ] **../../src/systems/TeaserLogic.res**
  - *Reason:* [Nesting: 3.00, Density: 0.05, Coupling: 0.10] | Drag: 4.05 | LOC: 384/300  🎯 Target: Function: `getConfigForStyle` (High Local Complexity (3.5). Logic heavy.)

---

