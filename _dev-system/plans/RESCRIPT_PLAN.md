# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (11)
- [ ] **../../src/systems/HotspotLineLogic.res**
  - *Reason:* [Nesting: 4.00, Density: 0.29, Coupling: 0.04] | Drag: 7.55 | LOC: 540/300  🎯 Target: Function: `isViewerValid` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/systems/SimulationLogic.res**
  - *Reason:* [Nesting: 4.50, Density: 0.12, Coupling: 0.06] | Drag: 9.29 | LOC: 467/300  🎯 Target: Function: `currentResult` (High Local Complexity (6.6). Logic heavy.)
- [ ] **../../src/systems/Navigation.res**
  - *Reason:* [Nesting: 6.00, Density: 0.38, Coupling: 0.08] | Drag: 10.09 | LOC: 415/300  🎯 Target: Function: `startJourney` (High Local Complexity (9.8). Logic heavy.)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 4.00, Density: 0.45, Coupling: 0.06] | Drag: 8.85 | LOC: 443/300  🎯 Target: Function: `calculateTransition` (High Local Complexity (3.0). Logic heavy.)
- [ ] **../../src/systems/ExifReportGeneratorLogic.res**
  - *Reason:* [Nesting: 4.00, Density: 0.13, Coupling: 0.07] | Drag: 7.96 | LOC: 434/300  🎯 Target: Function: `extractLocationName` (High Local Complexity (7.0). Logic heavy.)
- [ ] **../../src/core/Schemas.res**
  - *Reason:* [Nesting: 2.00, Density: 0.51, Coupling: 0.05] | Drag: 6.14 | LOC: 377/300  🎯 Target: Function: `castToValidationReport` (High Local Complexity (3.0). Logic heavy.)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 2.00, Density: 0.29, Coupling: 0.05] | Drag: 6.28 | LOC: 514/300  🎯 Target: Function: `levelPriority` (High Local Complexity (6.0). Logic heavy.)
- [ ] **../../src/systems/UploadProcessor.res**
  - *Reason:* [Nesting: 2.50, Density: 0.05, Coupling: 0.10] | Drag: 5.70 | LOC: 339/300  🎯 Target: Function: `getNotificationType` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/systems/ApiLogic.res**
  - *Reason:* [Nesting: 3.50, Density: 0.11, Coupling: 0.05] | Drag: 7.10 | LOC: 592/300  🎯 Target: Function: `extractErrorMessage` (High Local Complexity (3.0). Logic heavy.)
- [ ] **../../src/systems/Scene.res**
  - *Reason:* [Nesting: 3.00, Density: 0.17, Coupling: 0.09] | Drag: 6.99 | LOC: 355/300  🎯 Target: Function: `updateGlobalStateAndViewer` (High Local Complexity (5.8). Logic heavy.)
- [ ] **../../src/systems/Resizer.res**
  - *Reason:* [Nesting: 3.50, Density: 0.20, Coupling: 0.10] | Drag: 8.21 | LOC: 303/300  🎯 Target: Function: `getMemoryUsage` (High Local Complexity (10.4). Logic heavy.)

---

