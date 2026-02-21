# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (2)
- [ ] **../../backend/src/services/project/package.rs**
  - *Reason:* [Nesting: 3.60, Density: 0.03, Coupling: 0.01] | Drag: 5.05 | LOC: 609/300
- [ ] **../../backend/src/services/project/import_upload.rs**
  - *Reason:* [Nesting: 2.40, Density: 0.05, Coupling: 0.02] | Drag: 3.75 | LOC: 459/300

---

