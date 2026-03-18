# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Estimated modification-risk multiplier. Higher Drag means edits are more likely to miss state, flow, or boundary details.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (3)
- [ ] **../../backend/src/services/portal.rs**
  - *Reason:* [Nesting: 3.60, Density: 0.02, Coupling: 0.00] | Drag: 4.66 | LOC: 3436/400  ⚠️ Trigger: Oversized beyond the preferred 350-450 LOC working band.
- [ ] **../../backend/src/api/config_routes.rs**
  - *Reason:* [Nesting: 0.60, Density: 0.00, Coupling: 0.01] | Drag: 1.60 | LOC: 735/400  ⚠️ Trigger: Oversized beyond the preferred 350-450 LOC working band.
- [ ] **../../backend/src/api/portal.rs**
  - *Reason:* [Nesting: 2.40, Density: 0.02, Coupling: 0.01] | Drag: 3.46 | LOC: 874/400  ⚠️ Trigger: Oversized beyond the preferred 350-450 LOC working band.

---

