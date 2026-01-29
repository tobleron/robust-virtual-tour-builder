# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (3)
- [ ] **../../backend/src/api/project.rs**
  - *Reason:* [Nesting: 0.75, Density: 0.04, Deps: 0.00] | Drag: 2.19 | LOC: 375/357
- [ ] **../../backend/src/api/media/image_logic.rs**
  - *Reason:* [Nesting: 0.75, Density: 0.04, Deps: 0.00] | Drag: 2.46 | LOC: 290/238
- [ ] **../../backend/src/pathfinder.rs**
  - *Reason:* [Nesting: 1.05, Density: 0.07, Deps: 0.00] | Drag: 2.83 | LOC: 583/214

---

