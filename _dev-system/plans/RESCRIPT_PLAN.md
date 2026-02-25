# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (6)
- [ ] **../../src/systems/TeaserRecorder.res**
  - *Reason:* [Nesting: 6.00, Density: 0.23, Coupling: 0.05] | Drag: 7.25 | LOC: 485/300  🎯 Target: Function: `_` (High Local Complexity (6.0). Logic heavy.)
- [ ] **../../src/systems/TeaserLogic.res**
  - *Reason:* [Nesting: 2.40, Density: 0.01, Coupling: 0.09] | Drag: 3.41 | LOC: 572/300  🎯 Target: Function: `readMotionManifest` (High Local Complexity (1.0). Logic heavy.)
- [ ] **../../src/components/Sidebar/SidebarLogicHandler.res**
  - *Reason:* [Nesting: 4.80, Density: 0.15, Coupling: 0.04] | Drag: 6.06 | LOC: 1027/300  🎯 Target: Function: `parseExportMetrics` (High Local Complexity (16.5). Logic heavy.)
- [ ] **../../src/systems/TeaserPlayback.res**
  - *Reason:* [Nesting: 2.40, Density: 0.02, Coupling: 0.07] | Drag: 3.42 | LOC: 399/300  🎯 Target: Function: `start` (High Local Complexity (1.0). Logic heavy.)
- [ ] **../../src/systems/OperationLifecycle.res**
  - *Reason:* [Nesting: 3.00, Density: 0.22, Coupling: 0.03] | Drag: 4.28 | LOC: 381/300  🎯 Target: Function: `updateLoggerContext` (High Local Complexity (14.0). Logic heavy.)
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* [Nesting: 3.00, Density: 0.12, Coupling: 0.08] | Drag: 4.13 | LOC: 453/300  🎯 Target: Function: `isAutoForward` (High Local Complexity (8.0). Logic heavy.)

---

