# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (3)
- [ ] **../../src/systems/TourTemplates.res**
  - *Reason:* [Nesting: 4.20, Density: 0.13, Coupling: 0.02] | Drag: 5.33 | LOC: 1111/300  🎯 Target: Function: `autoForwardHotspotIndex` (High Local Complexity (7.9). Logic heavy.)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* [Nesting: 2.40, Density: 0.09, Coupling: 0.08] | Drag: 3.48 | LOC: 400/300  🎯 Target: Function: `classifySaveError` (High Local Complexity (10.5). Logic heavy.)
- [ ] **../../src/systems/Exporter.res**
  - *Reason:* [Nesting: 1.80, Density: 0.11, Coupling: 0.06] | Drag: 2.92 | LOC: 546/300  🎯 Target: Function: `normalizeLogoExtension` (High Local Complexity (5.0). Logic heavy.)

---

