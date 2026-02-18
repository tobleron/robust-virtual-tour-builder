# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (4)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* [Nesting: 2.40, Density: 0.09, Coupling: 0.08] | Drag: 3.48 | LOC: 400/300  🎯 Target: Function: `classifySaveError` (High Local Complexity (10.5). Logic heavy.)
- [ ] **../../src/systems/TourTemplates.res**
  - *Reason:* [Nesting: 3.60, Density: 0.12, Coupling: 0.02] | Drag: 4.72 | LOC: 1226/300  🎯 Target: Function: `autoForwardHotspotIndex` (High Local Complexity (6.8). Logic heavy.)
- [ ] **../../src/systems/Exporter.res**
  - *Reason:* [Nesting: 2.40, Density: 0.11, Coupling: 0.06] | Drag: 3.52 | LOC: 592/300  🎯 Target: Function: `normalizeLogoExtension` (High Local Complexity (5.0). Logic heavy.)
- [ ] **../../src/components/ViewerManagerLogic.res**
  - *Reason:* [Nesting: 3.00, Density: 0.12, Coupling: 0.08] | Drag: 4.12 | LOC: 377/300  🎯 Target: Function: `isLastIdValid` (High Local Complexity (3.0). Logic heavy.)

---

