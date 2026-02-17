# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (2)
- [ ] **../../src/systems/TourTemplates.res**
  - *Reason:* [Nesting: 3.60, Density: 0.12, Coupling: 0.03] | Drag: 4.72 | LOC: 963/300  🎯 Target: Function: `extractScenePrefix` (High Local Complexity (3.0). Logic heavy.)
- [ ] **../../src/systems/Exporter.res**
  - *Reason:* [Nesting: 1.80, Density: 0.12, Coupling: 0.06] | Drag: 2.93 | LOC: 514/300  🎯 Target: Function: `normalizeLogoExtension` (High Local Complexity (5.0). Logic heavy.)

---

