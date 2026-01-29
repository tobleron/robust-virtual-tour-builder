# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (35)
- [ ] **../../src/utils/LazyLoad.res**
  - *Reason:* [Nesting: 1.20, Density: 0.10, Deps: 0.16] | Drag: 4.46 | LOC: 87/80  Hotspot: Lines 30-34 (AI Context Fog (score 58.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* [Nesting: 1.20, Density: 0.00, Deps: 0.01] | Drag: 2.20 | LOC: 569/451  Hotspot: Lines 103-107 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Resizer.res**
  - *Reason:* [Nesting: 1.50, Density: 0.26, Deps: 0.11] | Drag: 8.10 | LOC: 303/90  Hotspot: Lines 218-222 (AI Context Fog (score 70.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/SceneList.res**
  - *Reason:* [Nesting: 1.05, Density: 0.07, Deps: 0.06] | Drag: 3.55 | LOC: 416/303  Hotspot: Lines 436-440 (AI Context Fog (score 51.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Constants.res**
  - *Reason:* [Nesting: 0.45, Density: 0.03, Deps: 0.00] | Drag: 2.05 | LOC: 185/136  Hotspot: Lines 216-220 (AI Context Fog (score 6.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/PathInterpolation.res**
  - *Reason:* [Nesting: 1.20, Density: 0.13, Deps: 0.06] | Drag: 5.11 | LOC: 236/80  Hotspot: Lines 109-113 (AI Context Fog (score 64.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ImageOptimizer.res**
  - *Reason:* [Nesting: 1.05, Density: 0.03, Deps: 0.16] | Drag: 3.06 | LOC: 92/90  Hotspot: Lines 59-63 (AI Context Fog (score 49.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ModalContext.res**
  - *Reason:* [Nesting: 1.05, Density: 0.34, Deps: 0.09] | Drag: 11.83 | LOC: 170/120  Hotspot: Lines 113-117 (AI Context Fog (score 48.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ViewerManagerLogic.res**
  - *Reason:* [Nesting: 1.20, Density: 0.24, Deps: 0.21] | Drag: 8.81 | LOC: 314/80  Hotspot: Lines 185-189 (AI Context Fog (score 61.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationGraph.res**
  - *Reason:* [Nesting: 1.20, Density: 0.21, Deps: 0.06] | Drag: 7.06 | LOC: 121/103  Hotspot: Lines 92-96 (AI Context Fog (score 55.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/PanoramaClusterer.res**
  - *Reason:* [Nesting: 1.20, Density: 0.29, Deps: 0.10] | Drag: 10.15 | LOC: 143/80  Hotspot: Lines 132-136 (AI Context Fog (score 59.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Api.res**
  - *Reason:* [Nesting: 1.35, Density: 0.01, Deps: 0.03] | Drag: 2.53 | LOC: 592/228  Hotspot: Lines 601-605 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Simulation.res**
  - *Reason:* [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 557/224  Hotspot: Lines 370-374 (AI Context Fog (score 124.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationController.res**
  - *Reason:* [Nesting: 2.25, Density: 0.20, Deps: 0.11] | Drag: 9.08 | LOC: 194/82  Hotspot: Lines 163-167 (AI Context Fog (score 201.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ViewerSystem.res**
  - *Reason:* [Nesting: 1.20, Density: 0.21, Deps: 0.05] | Drag: 6.87 | LOC: 299/106  Hotspot: Lines 207-211 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/LinkEditorLogic.res**
  - *Reason:* [Nesting: 0.90, Density: 0.19, Deps: 0.09] | Drag: 7.29 | LOC: 122/99  Hotspot: Lines 123-127 (AI Context Fog (score 38.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/HotspotManager.res**
  - *Reason:* [Nesting: 0.60, Density: 0.18, Deps: 0.14] | Drag: 5.83 | LOC: 115/113  Hotspot: Lines 109-113 (AI Context Fog (score 16.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ProgressBar.res**
  - *Reason:* [Nesting: 0.90, Density: 0.25, Deps: 0.14] | Drag: 5.79 | LOC: 109/80  Hotspot: Lines 100-104 (AI Context Fog (score 27.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Teaser.res**
  - *Reason:* [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 2.53 | LOC: 581/227  Hotspot: Lines 594-598 (AI Context Fog (score 65.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Navigation.res**
  - *Reason:* [Nesting: 2.10, Density: 0.21, Deps: 0.13] | Drag: 7.83 | LOC: 415/91  Hotspot: Lines 376-380 (AI Context Fog (score 196.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/SvgManager.res**
  - *Reason:* [Nesting: 0.90, Density: 0.24, Deps: 0.19] | Drag: 8.08 | LOC: 190/85  Hotspot: Lines 163-167 (AI Context Fog (score 40.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/HotspotLine.res**
  - *Reason:* [Nesting: 1.35, Density: 0.12, Deps: 0.06] | Drag: 5.95 | LOC: 697/118  Hotspot: Lines 245-249 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 1.20, Density: 0.21, Deps: 0.04] | Drag: 7.64 | LOC: 433/98  Hotspot: Lines 191-195 (AI Context Fog (score 63.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/SceneHelpers.res**
  - *Reason:* [Nesting: 1.05, Density: 0.15, Deps: 0.04] | Drag: 6.72 | LOC: 271/108  Hotspot: Lines 204-208 (AI Context Fog (score 41.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ExifReportGenerator.res**
  - *Reason:* [Nesting: 1.65, Density: 0.00, Deps: 0.00] | Drag: 2.65 | LOC: 542/224  Hotspot: Lines 204-208 (AI Context Fog (score 121.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/PreviewArrow.res**
  - *Reason:* [Nesting: 0.90, Density: 0.22, Deps: 0.03] | Drag: 8.19 | LOC: 194/166  Hotspot: Lines 137-141 (AI Context Fog (score 27.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationRenderer.res**
  - *Reason:* [Nesting: 1.80, Density: 0.14, Deps: 0.08] | Drag: 6.79 | LOC: 248/105  Hotspot: Lines 206-210 (AI Context Fog (score 125.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Schemas.res**
  - *Reason:* [Nesting: 0.90, Density: 0.25, Deps: 0.02] | Drag: 6.78 | LOC: 373/205  Hotspot: Lines 390-394 (AI Context Fog (score 27.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Actions.res**
  - *Reason:* [Nesting: 1.05, Density: 0.81, Deps: 0.01] | Drag: 24.35 | LOC: 155/80  Hotspot: Lines 155-159 (AI Context Fog (score 48.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/UploadProcessor.res**
  - *Reason:* [Nesting: 1.50, Density: 0.02, Deps: 0.01] | Drag: 2.94 | LOC: 333/207  Hotspot: Lines 338-342 (AI Context Fog (score 84.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Scene.res**
  - *Reason:* [Nesting: 1.05, Density: 0.14, Deps: 0.10] | Drag: 3.90 | LOC: 338/157  Hotspot: Lines 319-323 (AI Context Fog (score 39.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* [Nesting: 1.20, Density: 0.28, Deps: 0.18] | Drag: 8.10 | LOC: 247/85  Hotspot: Lines 235-239 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 0.90, Density: 0.13, Deps: 0.02] | Drag: 5.24 | LOC: 492/80  Hotspot: Lines 175-179 (AI Context Fog (score 31.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* [Nesting: 1.35, Density: 0.14, Deps: 0.24] | Drag: 5.85 | LOC: 365/183  Hotspot: Lines 242-246 (AI Context Fog (score 83.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Exporter.res**
  - *Reason:* [Nesting: 1.35, Density: 0.08, Deps: 0.13] | Drag: 4.38 | LOC: 205/141  Hotspot: Lines 55-59 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)

---

