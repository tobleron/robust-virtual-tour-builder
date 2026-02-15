# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (2)
- [ ] **../../src/core/ReducerModules.res**
  - *Reason:* [Nesting: 5.40, Density: 0.31, Coupling: 0.08] | Drag: 6.71 | LOC: 378/300  🎯 Target: Function: `finalState` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/components/VisualPipelineLogic.res**
  - *Reason:* [Nesting: 4.80, Density: 0.06, Coupling: 0.05] | Drag: 5.88 | LOC: 384/300

---

