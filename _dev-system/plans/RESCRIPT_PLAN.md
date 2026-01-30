# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (12)
- [ ] **../../src/systems/Resizer.res**
  - *Reason:* [Nesting: 3.50, Density: 0.19, Coupling: 0.10] | Drag: 8.17 | LOC: 303/300  🎯 Target: Function: `getMemoryUsage` (High Local Complexity (10.4). Logic heavy.)
- [ ] **../../src/systems/UploadProcessor.res**
  - *Reason:* [Nesting: 2.50, Density: 0.05, Coupling: 0.10] | Drag: 5.68 | LOC: 333/300  🎯 Target: Function: `type_` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 3.00, Density: 0.31, Coupling: 0.05] | Drag: 7.56 | LOC: 492/300  🎯 Target: Function: `stringToLevel` (High Local Complexity (7.0). Logic heavy.)
- [ ] **../../src/systems/Navigation.res**
  - *Reason:* [Nesting: 5.50, Density: 0.41, Coupling: 0.08] | Drag: 10.84 | LOC: 372/300  🎯 Target: Function: `make` (High Local Complexity (11.3). Logic heavy.)
- [ ] **../../src/systems/SimulationLogic.res**
  - *Reason:* [Nesting: 4.50, Density: 0.10, Coupling: 0.06] | Drag: 9.23 | LOC: 460/300  🎯 Target: Function: `globalViewer` (High Local Complexity (11.2). Logic heavy.)
- [ ] **../../src/systems/ApiLogic.res**
  - *Reason:* [Nesting: 3.50, Density: 0.11, Coupling: 0.05] | Drag: 7.09 | LOC: 586/300  🎯 Target: Function: `handleResponse` (High Local Complexity (4.2). Logic heavy.)
- [ ] **../../src/core/Schemas.res**
  - *Reason:* [Nesting: 2.50, Density: 0.50, Coupling: 0.05] | Drag: 9.24 | LOC: 373/300  🎯 Target: Function: `castToProject` (High Local Complexity (3.4). Logic heavy.)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* [Nesting: 4.00, Density: 0.45, Coupling: 0.06] | Drag: 8.89 | LOC: 433/300  🎯 Target: Function: `newTransition` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/ReBindings.res**
  - *Reason:* [Nesting: 1.50, Density: 0.67, Coupling: 0.15] | Drag: 9.94 | LOC: 350/300
- [ ] **../../src/systems/ExifReportGeneratorLogic.res**
  - *Reason:* [Nesting: 4.00, Density: 0.12, Coupling: 0.07] | Drag: 7.94 | LOC: 433/300  🎯 Target: Function: `locationPart` (High Local Complexity (6.6). Logic heavy.)
- [ ] **../../src/systems/HotspotLineLogic.res**
  - *Reason:* [Nesting: 4.00, Density: 0.30, Coupling: 0.04] | Drag: 7.65 | LOC: 514/300  🎯 Target: Function: `getPointAtProgress` (High Local Complexity (25.5). Logic heavy.)
- [ ] **../../src/systems/Scene.res**
  - *Reason:* [Nesting: 3.00, Density: 0.15, Coupling: 0.10] | Drag: 8.69 | LOC: 338/300  🎯 Target: Function: `clv` (High Local Complexity (3.5). Logic heavy.)

---

