# RUST MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (5)
- [ ] **../../backend/src/api/project_snapshot.rs**
  - *Reason:* [Nesting: 2.40, Density: 0.02, Coupling: 0.02] | Drag: 3.46 | LOC: 433/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.
- [ ] **../../backend/src/api/config_routes.rs**
  - *Reason:* [Nesting: 0.60, Density: 0.00, Coupling: 0.01] | Drag: 1.60 | LOC: 665/392  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.
- [ ] **../../backend/src/main.rs**
  - *Reason:* [Nesting: 3.00, Density: 0.04, Coupling: 0.06] | Drag: 4.04 | LOC: 447/300  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.
- [ ] **../../backend/src/services/project/package_output.rs**
  - *Reason:* [Nesting: 2.40, Density: 0.05, Coupling: 0.02] | Drag: 3.75 | LOC: 466/300  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.
- [ ] **../../backend/src/api/portal.rs**
  - *Reason:* [Nesting: 2.40, Density: 0.02, Coupling: 0.02] | Drag: 3.47 | LOC: 690/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.

---

