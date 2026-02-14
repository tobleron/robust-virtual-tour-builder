# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (2)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 5.40, Density: 0.28, Coupling: 0.10] | Drag: 6.68 | LOC: 409/300  🎯 Target: Function: `finalState` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* [Nesting: 4.80, Density: 0.05, Coupling: 0.06] | Drag: 5.86 | LOC: 469/300

---

