# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (3)
- [ ] **../../backend/src/middleware.rs**
  - *Reason:* [Nesting: 3.00, Density: 0.05, Coupling: 0.06] | Drag: 4.16 | LOC: 380/300
- [ ] **../../backend/src/api/project.rs**
  - *Reason:* [Nesting: 2.50, Density: 0.04, Coupling: 0.04] | Drag: 3.82 | LOC: 375/300
- [ ] **../../backend/src/api/media/image_logic.rs**
  - *Reason:* [Nesting: 2.50, Density: 0.04, Coupling: 0.03] | Drag: 4.27 | LOC: 330/300

---

