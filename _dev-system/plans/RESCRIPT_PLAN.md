# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (42)
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* [Nesting: 1.20, Density: 0.00, Coupling: 0.00] | Drag: 2.20 | LOC: 569/453  Hotspot: Lines 103-107 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/HotspotLine.res**
  - *Reason:* [Nesting: 1.35, Density: 0.12, Coupling: 0.06] | Drag: 2.78 | LOC: 697/250  Hotspot: Lines 245-249 (AI Context Fog (score 67.4): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 433)
- [ ] **../../src/core/AuthContext.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 76)
- [ ] **../../src/systems/ProjectData.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 94)
- [ ] **../../src/utils/RequestQueue.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 57)
- [ ] **../../src/components/SceneList.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 416)
- [ ] **../../src/systems/CursorPhysics.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 55)
- [ ] **../../src/utils/TourLogic.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 129)
- [ ] **../../src/utils/GeoUtils.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 83)
- [ ] **../../src/utils/LazyLoad.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 87)
- [ ] **../../src/systems/Teaser.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 581)
- [ ] **../../src/systems/Scene.res**
  - *Reason:* [Nesting: 1.05, Density: 0.14, Coupling: 0.11] | Drag: 2.32 | LOC: 338/250  Hotspot: Lines 319-323 (AI Context Fog (score 39.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/systems/Navigation.res**
  - *Reason:* [Nesting: 2.10, Density: 0.21, Coupling: 0.14] | Drag: 4.10 | LOC: 415/250  Hotspot: Lines 376-380 (AI Context Fog (score 196.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/Schemas.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 373)
- [ ] **../../src/systems/PanoramaClusterer.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 143)
- [ ] **../../src/systems/Resizer.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 303)
- [ ] **../../src/systems/FingerprintService.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 77)
- [ ] **../../src/systems/Exporter.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 205)
- [ ] **../../src/systems/Simulation.res**
  - *Reason:* [Nesting: 1.65, Density: 0.00, Coupling: 0.01] | Drag: 2.65 | LOC: 557/250  Hotspot: Lines 370-374 (AI Context Fog (score 124.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/ProgressBar.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 109)
- [ ] **../../src/core/SceneHelpers.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 271)
- [ ] **../../src/systems/ExifParser.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 266)
- [ ] **../../src/systems/Api.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 592)
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 365)
- [ ] **../../src/systems/DownloadSystem.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 135)
- [ ] **../../src/systems/VideoEncoder.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 100)
- [ ] **../../src/systems/NavigationController.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 194)
- [ ] **../../src/systems/ProjectManager.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 247)
- [ ] **../../src/components/UploadReport.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 189)
- [ ] **../../src/components/ViewerManagerLogic.res**
  - *Reason:* [Nesting: 1.20, Density: 0.24, Coupling: 0.21] | Drag: 3.00 | LOC: 314/250  Hotspot: Lines 185-189 (AI Context Fog (score 61.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 0.90, Density: 0.13, Coupling: 0.03] | Drag: 2.29 | LOC: 492/250  Hotspot: Lines 175-179 (AI Context Fog (score 31.6): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/core/SharedTypes.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 132)
- [ ] **../../src/components/PopOver.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 147)
- [ ] **../../src/systems/ExifReportGenerator.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 542)
- [ ] **../../src/systems/ViewerSystem.res**
  - *Reason:* [Nesting: 1.20, Density: 0.21, Coupling: 0.08] | Drag: 3.96 | LOC: 299/250  Hotspot: Lines 207-211 (AI Context Fog (score 52.0): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.)
- [ ] **../../src/ServiceWorkerMain.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 164)
- [ ] **../../src/systems/InputSystem.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 78)
- [ ] **../../src/systems/NavigationRenderer.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 248)
- [ ] **../../src/systems/TourTemplates.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 217)
- [ ] **../../src/systems/UploadProcessor.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 333)
- [ ] **../../src/systems/NavigationUI.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 54)

---

