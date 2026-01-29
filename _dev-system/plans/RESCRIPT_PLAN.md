# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines.
*   **Drag:** Complexity multiplier (1.0 = base).
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead for switching context between files.
*   **AI Context Fog:** High-complexity peak regions within a file.

---

## 🛠️ SURGICAL REFACTOR TASKS (36)
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* [Nesting: 1.20, Density: 0.00, Deps: 0.01] | Drag: 2.20 | LOC: 569/446  Hotspot: Lines 103-107 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/SceneList.res**
  - *Reason:* [Nesting: 1.05, Density: 0.08, Deps: 0.06] | Drag: 3.57 | LOC: 413/298  Hotspot: Lines 433-437 (AI Context Fog (score 51.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/SvgManager.res**
  - *Reason:* [Nesting: 0.90, Density: 0.24, Deps: 0.19] | Drag: 8.83 | LOC: 191/80  Hotspot: Lines 164-168 (AI Context Fog (score 40.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Api.res**
  - *Reason:* [Nesting: 1.35, Density: 0.01, Deps: 0.03] | Drag: 2.53 | LOC: 592/225  Hotspot: Lines 601-605 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Exporter.res**
  - *Reason:* [Nesting: 1.35, Density: 0.08, Deps: 0.13] | Drag: 4.38 | LOC: 205/139  Hotspot: Lines 55-59 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* [Nesting: 1.35, Density: 0.14, Deps: 0.24] | Drag: 6.05 | LOC: 365/176  Hotspot: Lines 242-246 (AI Context Fog (score 83.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Teaser.res**
  - *Reason:* [Nesting: 1.20, Density: 0.01, Deps: 0.03] | Drag: 3.72 | LOC: 572/168  Hotspot: Lines 585-589 (AI Context Fog (score 65.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ProgressBar.res**
  - *Reason:* [Nesting: 0.90, Density: 0.25, Deps: 0.14] | Drag: 5.90 | LOC: 106/80  Hotspot: Lines 111-115 (AI Context Fog (score 37.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ViewerSystem.res**
  - *Reason:* [Nesting: 1.20, Density: 0.23, Deps: 0.06] | Drag: 8.87 | LOC: 272/86  Hotspot: Lines 168-172 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/HotspotLine.res**
  - *Reason:* [Nesting: 1.35, Density: 0.12, Deps: 0.06] | Drag: 5.96 | LOC: 695/116  Hotspot: Lines 245-249 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/UploadProcessor.res**
  - *Reason:* [Nesting: 1.50, Density: 0.02, Deps: 0.01] | Drag: 2.94 | LOC: 331/204  Hotspot: Lines 336-340 (AI Context Fog (score 84.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Simulation.res**
  - *Reason:* [Nesting: 1.65, Density: 0.00, Deps: 0.01] | Drag: 2.65 | LOC: 553/221  Hotspot: Lines 366-370 (AI Context Fog (score 124.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Resizer.res**
  - *Reason:* [Nesting: 1.35, Density: 0.26, Deps: 0.11] | Drag: 8.01 | LOC: 300/89  Hotspot: Lines 217-221 (AI Context Fog (score 55.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/PreviewArrow.res**
  - *Reason:* [Nesting: 1.20, Density: 0.22, Deps: 0.03] | Drag: 8.69 | LOC: 188/157  Hotspot: Lines 90-94 (AI Context Fog (score 66.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ExifReportGenerator.res**
  - *Reason:* [Nesting: 1.65, Density: 0.00, Deps: 0.00] | Drag: 2.65 | LOC: 542/222  Hotspot: Lines 204-208 (AI Context Fog (score 121.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* [Nesting: 1.20, Density: 0.28, Deps: 0.18] | Drag: 8.10 | LOC: 247/84  Hotspot: Lines 235-239 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/LinkEditorLogic.res**
  - *Reason:* [Nesting: 0.90, Density: 0.19, Deps: 0.09] | Drag: 7.29 | LOC: 122/97  Hotspot: Lines 123-127 (AI Context Fog (score 38.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/PathInterpolation.res**
  - *Reason:* [Nesting: 1.20, Density: 0.13, Deps: 0.06] | Drag: 5.11 | LOC: 236/80  Hotspot: Lines 109-113 (AI Context Fog (score 64.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/SceneHelpers.res**
  - *Reason:* [Nesting: 1.05, Density: 0.16, Deps: 0.05] | Drag: 6.84 | LOC: 264/106  Hotspot: Lines 196-200 (AI Context Fog (score 41.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 0.90, Density: 0.13, Deps: 0.02] | Drag: 5.24 | LOC: 492/80  Hotspot: Lines 175-179 (AI Context Fog (score 31.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/PanoramaClusterer.res**
  - *Reason:* [Nesting: 1.20, Density: 0.29, Deps: 0.10] | Drag: 9.99 | LOC: 146/80  Hotspot: Lines 44-48 (AI Context Fog (score 64.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Navigation.res**
  - *Reason:* [Nesting: 2.10, Density: 0.20, Deps: 0.13] | Drag: 7.77 | LOC: 420/91  Hotspot: Lines 381-385 (AI Context Fog (score 196.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationController.res**
  - *Reason:* [Nesting: 2.25, Density: 0.20, Deps: 0.11] | Drag: 9.08 | LOC: 194/81  Hotspot: Lines 163-167 (AI Context Fog (score 201.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/HotspotManager.res**
  - *Reason:* [Nesting: 0.60, Density: 0.18, Deps: 0.14] | Drag: 5.83 | LOC: 115/111  Hotspot: Lines 109-113 (AI Context Fog (score 16.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationGraph.res**
  - *Reason:* [Nesting: 1.20, Density: 0.21, Deps: 0.06] | Drag: 7.06 | LOC: 121/102  Hotspot: Lines 92-96 (AI Context Fog (score 55.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ViewerManagerLogic.res**
  - *Reason:* [Nesting: 1.20, Density: 0.23, Deps: 0.22] | Drag: 8.93 | LOC: 307/80  Hotspot: Lines 183-187 (AI Context Fog (score 61.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Constants.res**
  - *Reason:* [Nesting: 0.45, Density: 0.03, Deps: 0.00] | Drag: 2.05 | LOC: 185/134  Hotspot: Lines 216-220 (AI Context Fog (score 6.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Schemas.res**
  - *Reason:* [Nesting: 0.90, Density: 0.24, Deps: 0.02] | Drag: 6.62 | LOC: 386/110  Hotspot: Lines 385-389 (AI Context Fog (score 27.2): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ImageOptimizer.res**
  - *Reason:* [Nesting: 1.05, Density: 0.03, Deps: 0.16] | Drag: 3.06 | LOC: 92/89  Hotspot: Lines 59-63 (AI Context Fog (score 49.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/components/ModalContext.res**
  - *Reason:* [Nesting: 1.35, Density: 0.34, Deps: 0.09] | Drag: 12.36 | LOC: 166/115  Hotspot: Lines 77-81 (AI Context Fog (score 81.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Actions.res**
  - *Reason:* [Nesting: 0.15, Density: 0.92, Deps: 0.01] | Drag: 25.31 | LOC: 105/80  Hotspot: Lines 55-59 (AI Context Fog (score 3.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Scene.res**
  - *Reason:* [Nesting: 1.05, Density: 0.14, Deps: 0.10] | Drag: 3.91 | LOC: 336/155  Hotspot: Lines 317-321 (AI Context Fog (score 39.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/NavigationRenderer.res**
  - *Reason:* [Nesting: 1.80, Density: 0.14, Deps: 0.08] | Drag: 6.79 | LOC: 248/104  Hotspot: Lines 206-210 (AI Context Fog (score 125.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 1.50, Density: 0.21, Deps: 0.04] | Drag: 7.98 | LOC: 430/94  Hotspot: Lines 182-186 (AI Context Fog (score 86.8): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/LazyLoad.res**
  - *Reason:* [Nesting: 1.20, Density: 0.10, Deps: 0.16] | Drag: 4.46 | LOC: 87/80  Hotspot: Lines 30-34 (AI Context Fog (score 58.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/SessionStore.res**
  - *Reason:* [Nesting: 0.75, Density: 0.39, Deps: 0.01] | Drag: 6.88 | LOC: 84/80  Hotspot: Lines 53-57 (AI Context Fog (score 29.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)

---

