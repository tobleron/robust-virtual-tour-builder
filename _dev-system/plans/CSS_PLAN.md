# CSS MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (1)
- [ ] **../../css/components/portal-pages.css**
  - *Reason:* [Nesting: 1.20, Density: 0.17, Coupling: 0.00] | Drag: 2.37 | LOC: 980/393  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.

---

