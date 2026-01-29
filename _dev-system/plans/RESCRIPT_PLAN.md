# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (24)
- [ ] **../../src/systems/Teaser.res**
  - *Reason:* [Nesting: 1.20, Density: 0.01, Coupling: 0.45] | Drag: 2.24 | LOC: 581/250  Hotspot: Lines 594-598 (AI Context Fog (score 65.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/HotspotLine.res**
  - *Reason:* [Nesting: 1.35, Density: 0.12, Coupling: 0.37] | Drag: 2.78 | LOC: 697/250  Hotspot: Lines 245-249 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/SceneList.res**
  - *Reason:* [Nesting: 1.05, Density: 0.07, Coupling: 0.43] | Drag: 2.24 | LOC: 416/319  Hotspot: Lines 436-440 (AI Context Fog (score 51.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Navigation.res**
  - *Reason:* [Nesting: 2.10, Density: 0.21, Coupling: 0.36] | Drag: 4.10 | LOC: 415/250  Hotspot: Lines 376-380 (AI Context Fog (score 196.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Scene.res**
  - *Reason:* [Nesting: 1.05, Density: 0.14, Coupling: 0.54] | Drag: 2.32 | LOC: 338/250  Hotspot: Lines 319-323 (AI Context Fog (score 39.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 1.20, Density: 0.21, Coupling: 0.26] | Drag: 2.85 | LOC: 433/250  Hotspot: Lines 191-195 (AI Context Fog (score 63.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* [Nesting: 1.20, Density: 0.00, Coupling: 0.30] | Drag: 2.20 | LOC: 569/361  Hotspot: Lines 103-107 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationRenderer.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 248)
- [ ] **../../src/core/AuthContext.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 76)
- [ ] **../../src/core/Schemas.res**
  - *Reason:* [Nesting: 0.90, Density: 0.25, Coupling: 1.06] | Drag: 3.72 | LOC: 373/250  Hotspot: Lines 390-394 (AI Context Fog (score 27.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/ReBindings.res**
  - *Reason:* [Nesting: 0.60, Density: 0.00, Coupling: 0.34] | Drag: 1.89 | LOC: 350/309  Hotspot: Lines 233-237 (AI Context Fog (score 12.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 0.90, Density: 0.13, Coupling: 0.30] | Drag: 2.29 | LOC: 492/250  Hotspot: Lines 175-179 (AI Context Fog (score 31.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationController.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 194)
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* [Nesting: 1.35, Density: 0.14, Coupling: 0.48] | Drag: 2.78 | LOC: 365/259  Hotspot: Lines 242-246 (AI Context Fog (score 83.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Api.res**
  - *Reason:* [Nesting: 1.35, Density: 0.01, Coupling: 0.54] | Drag: 2.38 | LOC: 592/250  Hotspot: Lines 601-605 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/UploadProcessor.res**
  - *Reason:* [Nesting: 1.50, Density: 0.02, Coupling: 0.58] | Drag: 2.55 | LOC: 333/250  Hotspot: Lines 338-342 (AI Context Fog (score 84.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Simulation.res**
  - *Reason:* [Nesting: 1.65, Density: 0.00, Coupling: 0.27] | Drag: 2.65 | LOC: 557/250  Hotspot: Lines 370-374 (AI Context Fog (score 124.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ExifParser.res**
  - *Reason:* [Nesting: 1.05, Density: 0.00, Coupling: 0.53] | Drag: 2.05 | LOC: 266/250  Hotspot: Lines 49-53 (AI Context Fog (score 48.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Resizer.res**
  - *Reason:* [Nesting: 1.50, Density: 0.26, Coupling: 0.51] | Drag: 3.21 | LOC: 303/250  Hotspot: Lines 218-222 (AI Context Fog (score 70.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationUI.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 54)
- [ ] **../../src/systems/ViewerSystem.res**
  - *Reason:* [Nesting: 1.20, Density: 0.21, Coupling: 0.51] | Drag: 3.96 | LOC: 299/250  Hotspot: Lines 207-211 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ExifReportGenerator.res**
  - *Reason:* [Nesting: 1.65, Density: 0.00, Coupling: 0.49] | Drag: 2.65 | LOC: 542/250  Hotspot: Lines 204-208 (AI Context Fog (score 121.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/SceneHelpers.res**
  - *Reason:* [Nesting: 1.05, Density: 0.15, Coupling: 0.36] | Drag: 2.60 | LOC: 271/250  Hotspot: Lines 204-208 (AI Context Fog (score 41.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ViewerManagerLogic.res**
  - *Reason:* [Nesting: 1.20, Density: 0.24, Coupling: 0.57] | Drag: 3.00 | LOC: 314/250  Hotspot: Lines 185-189 (AI Context Fog (score 61.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)

---

