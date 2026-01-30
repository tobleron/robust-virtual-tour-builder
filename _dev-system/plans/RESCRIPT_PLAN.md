# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (6)
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* [Nesting: 1.20, Density: 0.00, Coupling: 0.30] | Drag: 2.20 | LOC: 569/500  Hotspot: Lines 103-107 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ExifReportGenerator.res**
  - *Reason:* [Nesting: 1.65, Density: 0.01, Coupling: 0.49] | Drag: 2.70 | LOC: 542/500  Hotspot: Lines 204-208 (AI Context Fog (score 121.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Api.res**
  - *Reason:* [Nesting: 1.35, Density: 0.04, Coupling: 0.54] | Drag: 2.69 | LOC: 592/500  Hotspot: Lines 601-605 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Teaser.res**
  - *Reason:* [Nesting: 1.20, Density: 0.08, Coupling: 0.45] | Drag: 2.91 | LOC: 581/500  Hotspot: Lines 594-598 (AI Context Fog (score 65.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Simulation.res**
  - *Reason:* [Nesting: 1.65, Density: 0.00, Coupling: 0.27] | Drag: 2.67 | LOC: 557/500  Hotspot: Lines 370-374 (AI Context Fog (score 124.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/HotspotLine.res**
  - *Reason:* [Nesting: 1.35, Density: 0.27, Coupling: 0.37] | Drag: 4.21 | LOC: 697/500  Hotspot: Lines 245-249 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)

---

