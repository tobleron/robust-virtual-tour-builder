# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (20)
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* [Nesting: 4.20, Density: 0.08, Coupling: 0.04] | Drag: 5.28 | LOC: 1011/300  🎯 Target: Function: `make` (High Local Complexity (12.7). Logic heavy.)
- [ ] **../../src/components/VisualPipelineHub.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 46)
- [ ] **../../src/components/LabelMenu.res**
  - *Reason:* [Nesting: 2.40, Density: 0.11, Coupling: 0.06] | Drag: 3.57 | LOC: 521/300  🎯 Target: Function: `bulkDeleteBlockReason` (High Local Complexity (18.5). Logic heavy.)
- [ ] **../../src/core/JsonParsersDecoders.res**
  - *Reason:* [Nesting: 3.00, Density: 0.65, Coupling: 0.05] | Drag: 4.65 | LOC: 377/300  🎯 Target: Function: `project` (High Local Complexity (13.4). Logic heavy.)
- [ ] **../../src/utils/AsyncQueue.res**
  - *Reason:* [Nesting: 3.60, Density: 0.12, Coupling: 0.02] | Drag: 4.88 | LOC: 470/300  🎯 Target: Function: `toSortedCopy` (High Local Complexity (6.0). Logic heavy.)
- [ ] **../../src/systems/Exporter/ExporterUpload.res**
  - *Reason:* [Nesting: 4.20, Density: 0.17, Coupling: 0.05] | Drag: 5.39 | LOC: 496/300  🎯 Target: Function: `uploadedCount` (High Local Complexity (8.5). Logic heavy.)
- [ ] **../../src/systems/Exporter/ExporterPackaging.res**
  - *Reason:* [Nesting: 3.00, Density: 0.06, Coupling: 0.07] | Drag: 4.08 | LOC: 422/300  🎯 Target: Function: `isAborted` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/systems/TeaserRecorderHud.res**
  - *Reason:* [Nesting: 5.40, Density: 0.27, Coupling: 0.03] | Drag: 6.71 | LOC: 457/300  🎯 Target: Function: `clampCorner` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/utils/WorkerPool.res**
  - *Reason:* [Nesting: 1.80, Density: 0.10, Coupling: 0.02] | Drag: 3.10 | LOC: 507/300  🎯 Target: Function: `createPoolSize` (High Local Complexity (7.0). Logic heavy.)
- [ ] **../../src/components/Sidebar/SidebarLogicHandler.res**
  - *Reason:* [Nesting: 4.80, Density: 0.15, Coupling: 0.10] | Drag: 5.99 | LOC: 391/300  🎯 Target: Function: `state` (High Local Complexity (9.5). Logic heavy.)
- [ ] **../../src/components/PreviewArrow.res**
  - *Reason:* [Nesting: 3.60, Density: 0.14, Coupling: 0.08] | Drag: 4.83 | LOC: 419/300  🎯 Target: Function: `handleMainClick` (High Local Complexity (7.1). Logic heavy.)
- [ ] **../../src/utils/LoggerTelemetry.res**
  - *Reason:* [Nesting: 3.00, Density: 0.20, Coupling: 0.06] | Drag: 4.34 | LOC: 453/300  🎯 Target: Function: `parseRetryAfterHeaderMs` (High Local Complexity (4.8). Logic heavy.)
- [ ] **../../src/systems/OperationLifecycle.res**
  - *Reason:* [Nesting: 3.60, Density: 0.21, Coupling: 0.03] | Drag: 4.93 | LOC: 404/300  🎯 Target: Function: `ttlMsForType` (High Local Complexity (7.0). Logic heavy.)
- [ ] **../../src/components/VisualPipelineRouter.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 90)
- [ ] **../../src/systems/Simulation.res**
  - *Reason:* [Nesting: 7.20, Density: 0.25, Coupling: 0.08] | Drag: 8.47 | LOC: 383/300  🎯 Target: Function: `make` (High Local Complexity (9.1). Logic heavy.)
- [ ] **../../src/systems/ProjectSystem.res**
  - *Reason:* [Nesting: 1.80, Density: 0.05, Coupling: 0.10] | Drag: 2.85 | LOC: 404/300  🎯 Target: Function: `notifyProjectValidationWarnings` (High Local Complexity (3.5). Logic heavy.)
- [ ] **../../src/systems/Traversal/CanonicalTraversal.res**
  - *Reason:* [Nesting: 4.20, Density: 0.15, Coupling: 0.05] | Drag: 5.45 | LOC: 403/300  🎯 Target: Function: `stripSceneTag` (High Local Complexity (5.0). Logic heavy.)
- [ ] **../../src/utils/PersistenceLayer.res**
  - *Reason:* [Nesting: 3.00, Density: 0.12, Coupling: 0.05] | Drag: 4.26 | LOC: 545/300  🎯 Target: Function: `getAutosaveCostStats` (High Local Complexity (12.0). Logic heavy.)
- [ ] **../../src/components/VisualPipelineLayout.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 85)
- [ ] **../../src/utils/Retry.res**
  - *Reason:* [Nesting: 4.20, Density: 0.33, Coupling: 0.04] | Drag: 5.59 | LOC: 380/300  🎯 Target: Function: `classifyError` (High Local Complexity (4.5). Logic heavy.)

---

