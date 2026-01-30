# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (5)
- [ ] **../../src/systems/HotspotLineLogic.res**
  - *Reason:* [Nesting: 1.35, Density: 0.28, Coupling: 0.43] | Drag: 4.40 | LOC: 514/500  Hotspot: Lines 245-249 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* [Nesting: 1.20, Density: 0.00, Coupling: 0.00] | Drag: 2.22 | LOC: 569/500  Hotspot: Lines 103-107 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 365)
- [ ] **../../src/components/SceneList.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 416)
- [ ] **../../src/systems/ApiLogic.res**
  - *Reason:* [Nesting: 1.35, Density: 0.04, Coupling: 0.11] | Drag: 2.69 | LOC: 586/500  Hotspot: Lines 598-602 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)

---

