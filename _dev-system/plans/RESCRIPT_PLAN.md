# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 2.0). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (19)
- [ ] **../../src/systems/HotspotLineLogic.res**
  - *Reason:* [Nesting: 1.20, Density: 0.25, Coupling: 0.01] | Drag: 4.22 | LOC: 514/500  🎯 Target: Function: `getPointAtProgress` (High Local Complexity (25.5). Logic heavy.)
- [ ] **../../src/core/Schemas.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 373)
- [ ] **../../src/utils/StateInspector.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 88)
- [ ] **../../src/utils/ProgressBar.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 109)
- [ ] **../../src/utils/RequestQueue.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 57)
- [ ] **../../src/utils/PersistenceLayer.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 66)
- [ ] **../../src/components/PopOver.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 147)
- [ ] **../../src/systems/ApiLogic.res**
  - *Reason:* [Nesting: 1.05, Density: 0.09, Coupling: 0.02] | Drag: 4.35 | LOC: 586/500  🎯 Target: Function: `handleResponse` (High Local Complexity (4.2). Logic heavy.)
- [ ] **../../src/utils/ImageOptimizer.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 92)
- [ ] **../../src/utils/LazyLoad.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 87)
- [ ] **../../src/utils/ProjectionMath.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 88)
- [ ] **../../src/core/SceneHelpers.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 271)
- [ ] **../../src/components/Sidebar.res**
  - *Reason:* [Nesting: 1.20, Density: 0.04, Coupling: 0.03] | Drag: 3.95 | LOC: 569/500  🎯 Target: Function: `handleUpload` (High Local Complexity (5.0). Logic heavy.)
- [ ] **../../src/components/LinkModal.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 175)
- [ ] **../../src/core/Reducer.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 433)
- [ ] **../../src/utils/Constants.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 185)
- [ ] **../../src/utils/SessionStore.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 80)
- [ ] **../../src/components/ViewerSnapshot.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 57)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 492)

---

