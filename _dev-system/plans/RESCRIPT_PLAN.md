# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (6)
- [ ] **../../src/systems/OperationLifecycle.res**
  - *Reason:* [Nesting: 3.00, Density: 0.22, Coupling: 0.03] | Drag: 4.28 | LOC: 381/300  🎯 Target: Function: `updateLoggerContext` (High Local Complexity (14.0). Logic heavy.)
- [ ] **../../src/systems/TeaserLogic.res**
  - *Reason:* [Nesting: 2.40, Density: 0.02, Coupling: 0.12] | Drag: 3.42 | LOC: 378/300  🎯 Target: Function: `readMotionManifest` (High Local Complexity (1.0). Logic heavy.)
- [ ] **../../src/systems/TeaserPlayback.res**
  - *Reason:* [Nesting: 2.40, Density: 0.02, Coupling: 0.07] | Drag: 3.42 | LOC: 396/300  🎯 Target: Function: `start` (High Local Complexity (1.0). Logic heavy.)
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* [Nesting: 3.00, Density: 0.09, Coupling: 0.08] | Drag: 4.09 | LOC: 414/300  🎯 Target: Function: `isAutoForward` (High Local Complexity (8.0). Logic heavy.)
- [ ] **../../src/components/Sidebar/SidebarLogicHandler.res**
  - *Reason:* [Nesting: 4.20, Density: 0.06, Coupling: 0.07] | Drag: 5.27 | LOC: 561/300  🎯 Target: Function: `fileArray` (High Local Complexity (3.0). Logic heavy.)
- [ ] **../../src/systems/TeaserRecorder.res**
  - *Reason:* [Nesting: 6.00, Density: 0.22, Coupling: 0.05] | Drag: 7.24 | LOC: 481/300  🎯 Target: Function: `_` (High Local Complexity (6.0). Logic heavy.)

---

