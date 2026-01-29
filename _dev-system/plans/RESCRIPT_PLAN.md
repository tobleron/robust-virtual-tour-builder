# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (17)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 1.20, Density: 0.21, Deps: 0.04] | Drag: 2.85 | LOC: 433/250  Hotspot: Lines 191-195 (AI Context Fog (score 63.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* [Nesting: 1.35, Density: 0.14, Deps: 0.24] | Drag: 2.78 | LOC: 365/319  Hotspot: Lines 242-246 (AI Context Fog (score 83.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Resizer.res**
  - *Reason:* [Nesting: 1.50, Density: 0.26, Deps: 0.11] | Drag: 3.21 | LOC: 303/250  Hotspot: Lines 218-222 (AI Context Fog (score 70.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/HotspotLine.res**
  - *Reason:* [Nesting: 1.35, Density: 0.12, Deps: 0.06] | Drag: 2.78 | LOC: 697/250  Hotspot: Lines 245-249 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 0.90, Density: 0.13, Deps: 0.02] | Drag: 2.29 | LOC: 492/250  Hotspot: Lines 175-179 (AI Context Fog (score 31.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* [Nesting: 1.20, Density: 0.00, Deps: 0.01] | Drag: 2.20 | LOC: 569/450  Hotspot: Lines 103-107 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ViewerManagerLogic.res**
  - *Reason:* [Nesting: 1.20, Density: 0.24, Deps: 0.21] | Drag: 3.00 | LOC: 314/250  Hotspot: Lines 185-189 (AI Context Fog (score 61.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Api.res**
  - *Reason:* [Nesting: 1.35, Density: 0.01, Deps: 0.03] | Drag: 2.38 | LOC: 592/250  Hotspot: Lines 601-605 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Simulation.res**
  - *Reason:* [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 557/250  Hotspot: Lines 370-374 (AI Context Fog (score 124.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/UploadProcessor.res**
  - *Reason:* [Nesting: 1.50, Density: 0.02, Deps: 0.01] | Drag: 2.55 | LOC: 333/250  Hotspot: Lines 338-342 (AI Context Fog (score 84.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/SceneHelpers.res**
  - *Reason:* [Nesting: 1.05, Density: 0.15, Deps: 0.04] | Drag: 2.60 | LOC: 271/250  Hotspot: Lines 204-208 (AI Context Fog (score 41.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ExifReportGenerator.res**
  - *Reason:* [Nesting: 1.65, Density: 0.00, Deps: 0.00] | Drag: 2.65 | LOC: 542/250  Hotspot: Lines 204-208 (AI Context Fog (score 121.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Scene.res**
  - *Reason:* [Nesting: 1.05, Density: 0.14, Deps: 0.10] | Drag: 2.32 | LOC: 338/250  Hotspot: Lines 319-323 (AI Context Fog (score 39.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Navigation.res**
  - *Reason:* [Nesting: 2.10, Density: 0.21, Deps: 0.13] | Drag: 4.10 | LOC: 415/250  Hotspot: Lines 376-380 (AI Context Fog (score 196.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Teaser.res**
  - *Reason:* [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 2.24 | LOC: 581/250  Hotspot: Lines 594-598 (AI Context Fog (score 65.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Schemas.res**
  - *Reason:* [Nesting: 0.90, Density: 0.25, Deps: 0.02] | Drag: 3.72 | LOC: 373/321  Hotspot: Lines 390-394 (AI Context Fog (score 27.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ViewerSystem.res**
  - *Reason:* [Nesting: 1.20, Density: 0.21, Deps: 0.05] | Drag: 3.96 | LOC: 299/250  Hotspot: Lines 207-211 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)

---

