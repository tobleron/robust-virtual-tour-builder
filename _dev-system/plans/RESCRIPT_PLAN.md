# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (3)
- [ ] **../../src/systems/TourTemplates/TourScriptUINav.res**
  - *Reason:* [Nesting: 0.00, Density: 0.00, Coupling: 0.00] | Drag: 1.00 | LOC: 556/414  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.
- [ ] **../../src/systems/TourTemplateHtml.res**
  - *Reason:* [Nesting: 3.00, Density: 0.02, Coupling: 0.01] | Drag: 4.02 | LOC: 391/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.
- [ ] **../../src/systems/TourTemplates/TourScriptNavigation.res**
  - *Reason:* [Nesting: 0.00, Density: 0.00, Coupling: 0.00] | Drag: 1.00 | LOC: 719/414  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.

---

