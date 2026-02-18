# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (3)
- [ ] **../../src/systems/TourTemplates/TourScripts.res**
  - *Reason:* [Nesting: 0.00, Density: 0.01, Coupling: 0.00] | Drag: 1.01 | LOC: 920/409
- [ ] **../../src/components/ViewerManagerLogic.res**
  - *Reason:* [Nesting: 3.00, Density: 0.12, Coupling: 0.08] | Drag: 4.12 | LOC: 377/300  🎯 Target: Function: `isLastIdValid` (High Local Complexity (3.0). Logic heavy.)
- [ ] **../../src/systems/Exporter.res**
  - *Reason:* [Nesting: 2.40, Density: 0.04, Coupling: 0.08] | Drag: 3.46 | LOC: 406/300

---

