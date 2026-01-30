# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (9)
- [ ] **../../src/systems/Resizer.res**
  - *Reason:* [Nesting: 3.50, Density: 0.20, Coupling: 0.10] | Drag: 8.21 | LOC: 303/300  🎯 Target: Function: `getMemoryUsage` (High Local Complexity (10.4). Logic heavy.)
- [ ] **../../src/systems/ApiLogic.res**
  - *Reason:* [Nesting: 3.50, Density: 0.08, Coupling: 0.04] | Drag: 7.14 | LOC: 503/300  🎯 Target: Function: `bodyVal` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/systems/SimulationLogic.res**
  - *Reason:* [Nesting: 4.50, Density: 0.12, Coupling: 0.06] | Drag: 9.29 | LOC: 467/300  🎯 Target: Function: `currentResult` (High Local Complexity (6.6). Logic heavy.)
- [ ] **../../src/systems/UploadProcessor.res**
  - *Reason:* [Nesting: 2.50, Density: 0.05, Coupling: 0.10] | Drag: 5.70 | LOC: 339/300  🎯 Target: Function: `getNotificationType` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/systems/Scene.res**
  - *Reason:* [Nesting: 3.00, Density: 0.17, Coupling: 0.09] | Drag: 6.99 | LOC: 355/300  🎯 Target: Function: `updateGlobalStateAndViewer` (High Local Complexity (5.8). Logic heavy.)
- [ ] **../../src/systems/ExifReportGeneratorLogic.res**
  - *Reason:* [Nesting: 5.50, Density: 0.14, Coupling: 0.06] | Drag: 9.29 | LOC: 331/300  🎯 Target: Function: `extractAllExif` (High Local Complexity (11.1). Logic heavy.)
- [ ] **../../src/systems/HotspotLineLogic.res**
  - *Reason:* [Nesting: 4.00, Density: 0.29, Coupling: 0.04] | Drag: 7.55 | LOC: 540/300  🎯 Target: Function: `isViewerValid` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 4.00, Density: 0.44, Coupling: 0.06] | Drag: 8.79 | LOC: 437/300  🎯 Target: Function: `vf` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/systems/Navigation.res**
  - *Reason:* [Nesting: 6.00, Density: 0.39, Coupling: 0.08] | Drag: 10.15 | LOC: 407/300  🎯 Target: Function: `startJourney` (High Local Complexity (9.8). Logic heavy.)

---

