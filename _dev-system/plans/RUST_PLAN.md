# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (5)
- [ ] **../../backend/src/api/project.rs**
  - *Reason:* [Nesting: 2.00, Density: 0.02, Coupling: 0.04] | Drag: 3.47 | LOC: 340/300
- [ ] **../../backend/src/middleware.rs**
  - *Reason:* [Nesting: 2.00, Density: 0.03, Coupling: 0.06] | Drag: 3.03 | LOC: 354/300
- [ ] **../../backend/src/pathfinder/algorithms.rs**
  - *Reason:* [Nesting: 3.00, Density: 0.10, Coupling: 0.00] | Drag: 4.78 | LOC: 436/300
- [ ] **../../backend/src/services/geocoding.rs**
  - *Reason:* [Nesting: 2.50, Density: 0.07, Coupling: 0.02] | Drag: 3.68 | LOC: 365/300
- [ ] **../../backend/src/api/media/image_logic.rs**
  - *Reason:* [Nesting: 2.00, Density: 0.04, Coupling: 0.02] | Drag: 4.02 | LOC: 405/300

---

