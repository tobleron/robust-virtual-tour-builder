# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (12)
- [ ] **../../src/systems/ApiLogic.res**
  - *Reason:* [Nesting: 3.50, Density: 0.11, Coupling: 0.05] | Drag: 7.10 | LOC: 589/300  🎯 Target: Function: `processErrorResponse` (High Local Complexity (4.5). Logic heavy.)
- [ ] **../../src/systems/ExifReportGeneratorLogic.res**
  - *Reason:* [Nesting: 4.00, Density: 0.13, Coupling: 0.07] | Drag: 7.96 | LOC: 434/300  🎯 Target: Function: `extractLocationName` (High Local Complexity (9.2). Logic heavy.)
- [ ] **../../src/systems/Navigation.res**
  - *Reason:* [Nesting: 5.50, Density: 0.41, Coupling: 0.09] | Drag: 10.81 | LOC: 380/300  🎯 Target: Function: `startJourney` (High Local Complexity (10.1). Logic heavy.)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 4.00, Density: 0.45, Coupling: 0.06] | Drag: 8.89 | LOC: 433/300  🎯 Target: Function: `newTransition` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/core/Schemas.res**
  - *Reason:* [Nesting: 2.50, Density: 0.50, Coupling: 0.05] | Drag: 9.24 | LOC: 373/300  🎯 Target: Function: `castToProject` (High Local Complexity (3.4). Logic heavy.)
- [ ] **../../src/ReBindings.res**
  - *Reason:* [Nesting: 1.50, Density: 0.66, Coupling: 0.15] | Drag: 9.90 | LOC: 358/300
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 3.00, Density: 0.31, Coupling: 0.05] | Drag: 7.56 | LOC: 492/300  🎯 Target: Function: `stringToLevel` (High Local Complexity (7.0). Logic heavy.)
- [ ] **../../src/systems/Resizer.res**
  - *Reason:* [Nesting: 3.50, Density: 0.20, Coupling: 0.10] | Drag: 8.23 | LOC: 301/300  🎯 Target: Function: `getMemoryUsage` (High Local Complexity (10.9). Logic heavy.)
- [ ] **../../src/systems/Scene.res**
  - *Reason:* [Nesting: 3.00, Density: 0.16, Coupling: 0.10] | Drag: 8.65 | LOC: 348/300  🎯 Target: Function: `scheduleCleanup` (High Local Complexity (6.6). Logic heavy.)
- [ ] **../../src/systems/SimulationLogic.res**
  - *Reason:* [Nesting: 4.50, Density: 0.11, Coupling: 0.06] | Drag: 9.22 | LOC: 459/300  🎯 Target: Function: `globalViewer` (High Local Complexity (7.5). Logic heavy.)
- [ ] **../../src/systems/UploadProcessor.res**
  - *Reason:* [Nesting: 2.50, Density: 0.05, Coupling: 0.10] | Drag: 5.65 | LOC: 341/300  🎯 Target: Function: `type_` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/systems/HotspotLineLogic.res**
  - *Reason:* [Nesting: 4.00, Density: 0.29, Coupling: 0.04] | Drag: 7.54 | LOC: 538/300  🎯 Target: Function: `mousePtOpt` (High Local Complexity (5.0). Logic heavy.)

---

