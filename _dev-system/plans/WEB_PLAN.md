# WEB MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (1)
- [ ] **../../src/site/PageFrameworkBuilder.js**
  - *Reason:* [Nesting: 9.00, Density: 0.21, Coupling: 0.01] | Drag: 10.21 | LOC: 341/300  ⚠️ Trigger: Drag above target (1.80) with file already at 341 LOC.

---

