# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (8)
- [ ] **../../src/systems/Navigation.res**
  - *Reason:* [Nesting: 6.00, Density: 0.39, Coupling: 0.08] | Drag: 10.11 | LOC: 430/300  🎯 Target: Function: `req` (High Local Complexity (9.3). Logic heavy.)
- [ ] **../../src/systems/ApiLogic.res**
  - *Reason:* [Nesting: 3.50, Density: 0.07, Coupling: 0.04] | Drag: 7.09 | LOC: 503/300  🎯 Target: Function: `extractMetadata` (High Local Complexity (1.0). Logic heavy.)
- [ ] **../../src/systems/ExifReportGeneratorLogic.res**
  - *Reason:* [Nesting: 4.00, Density: 0.16, Coupling: 0.06] | Drag: 7.88 | LOC: 338/300  🎯 Target: Function: `processSceneDataItem` (High Local Complexity (14.4). Logic heavy.)
- [ ] **../../src/systems/SimulationLogic.res**
  - *Reason:* [Nesting: 3.50, Density: 0.12, Coupling: 0.06] | Drag: 8.29 | LOC: 470/300  🎯 Target: Function: `currentResult` (High Local Complexity (6.6). Logic heavy.)
- [ ] **../../src/systems/Scene.res**
  - *Reason:* [Nesting: 3.00, Density: 0.17, Coupling: 0.09] | Drag: 6.99 | LOC: 356/300  🎯 Target: Function: `updateGlobalStateAndViewer` (High Local Complexity (3.5). Logic heavy.)
- [ ] **../../src/systems/UploadProcessor.res**
  - *Reason:* [Nesting: 2.50, Density: 0.05, Coupling: 0.11] | Drag: 5.69 | LOC: 341/300  🎯 Target: Function: `getNotificationType` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/systems/Resizer.res**
  - *Reason:* [Nesting: 3.50, Density: 0.21, Coupling: 0.10] | Drag: 8.30 | LOC: 309/300  🎯 Target: Function: `getMemoryUsage` (High Local Complexity (12.9). Logic heavy.)
- [ ] **../../src/systems/HotspotLineLogic.res**
  - *Reason:* [Nesting: 4.00, Density: 0.29, Coupling: 0.04] | Drag: 7.55 | LOC: 538/300  🎯 Target: Function: `waypointsRaw` (High Local Complexity (2.0). Logic heavy.)

---

