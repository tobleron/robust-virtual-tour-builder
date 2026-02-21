# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (3)
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* [Nesting: 3.00, Density: 0.09, Coupling: 0.08] | Drag: 4.09 | LOC: 414/300  🎯 Target: Function: `isAutoForward` (High Local Complexity (8.0). Logic heavy.)
- [ ] **../../src/systems/OperationLifecycle.res**
  - *Reason:* [Nesting: 3.00, Density: 0.22, Coupling: 0.03] | Drag: 4.28 | LOC: 379/300  🎯 Target: Function: `updateLoggerContext` (High Local Complexity (14.0). Logic heavy.)
- [ ] **../../src/components/Sidebar/SidebarLogicHandler.res**
  - *Reason:* [Nesting: 4.20, Density: 0.06, Coupling: 0.07] | Drag: 5.27 | LOC: 543/300  🎯 Target: Function: `msg` (High Local Complexity (2.0). Logic heavy.)

---

