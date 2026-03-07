# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (3)
- [ ] **../../backend/src/api/project.rs**
  - *Reason:* [Nesting: 3.00, Density: 0.03, Coupling: 0.03] | Drag: 4.06 | LOC: 496/300
- [ ] **../../backend/src/services/project/package.rs**
  - *Reason:* [Nesting: 3.00, Density: 0.05, Coupling: 0.02] | Drag: 4.41 | LOC: 378/300
- [ ] **../../backend/src/services/geocoding/cache.rs**
  - *Reason:* [Nesting: 2.40, Density: 0.04, Coupling: 0.02] | Drag: 3.87 | LOC: 380/300

---

