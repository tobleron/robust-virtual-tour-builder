# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Estimated modification-risk multiplier. Higher Drag means edits are more likely to miss state, flow, or boundary details.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (9)
- [ ] **../../src/systems/TourTemplates/TourScriptUINav.res**
  - *Reason:* [Nesting: 0.00, Density: 0.00, Coupling: 0.00] | Drag: 1.00 | LOC: 979/577  ⚠️ Trigger: Oversized beyond the preferred 350-450 LOC working band.
- [ ] **../../src/systems/TourTemplateHtml.res**
  - *Reason:* [Nesting: 3.00, Density: 0.01, Coupling: 0.01] | Drag: 4.01 | LOC: 620/400  ⚠️ Trigger: Drag above target (2.40); keep the module within the 350-450 LOC working band if you extract helpers.
- [ ] **../../src/site/PortalApi.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 366)
- [ ] **../../src/site/PortalApp.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 2977)
- [ ] **../../src/site/PortalApp.res**
  - *Reason:* [Nesting: 8.40, Density: 0.19, Coupling: 0.01] | Drag: 9.67 | LOC: 2977/400  ⚠️ Trigger: Drag above target (2.40); keep the module within the 350-450 LOC working band if you extract helpers.  🎯 Target: Function: `make` (High Local Complexity (225.8). Logic heavy.)
- [ ] **../../src/site/PortalTypes.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 225)
- [ ] **../../src/utils/NetworkStatus.res**
  - *Reason:* [Nesting: 2.40, Density: 0.37, Coupling: 0.03] | Drag: 4.05 | LOC: 377/400  ⚠️ Trigger: Drag above target (2.40) with file already at 377 LOC.  🎯 Target: Function: `initialize` (High Local Complexity (9.0). Logic heavy.)
- [ ] **../../src/systems/TourTemplates/TourScriptNavigation.res**
  - *Reason:* [Nesting: 0.00, Density: 0.00, Coupling: 0.00] | Drag: 1.00 | LOC: 1051/577  ⚠️ Trigger: Oversized beyond the preferred 350-450 LOC working band.
- [ ] **../../src/components/ReactHotspotLayer.res**
  - *Reason:* [Nesting: 6.00, Density: 0.37, Coupling: 0.08] | Drag: 7.49 | LOC: 417/400  ⚠️ Trigger: Drag above target (2.40) with file already at 417 LOC.  🎯 Target: Function: `make` (High Local Complexity (41.0). Logic heavy.)

---

