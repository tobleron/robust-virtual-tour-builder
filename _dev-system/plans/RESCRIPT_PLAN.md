# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (6)
- [ ] **../../src/utils/AsyncQueue.res**
  - *Reason:* [Nesting: 3.60, Density: 0.13, Coupling: 0.02] | Drag: 4.87 | LOC: 465/300  🎯 Target: Function: `toSortedCopy` (High Local Complexity (6.0). Logic heavy.)
- [ ] **../../src/utils/Retry.res**
  - *Reason:* [Nesting: 4.20, Density: 0.30, Coupling: 0.03] | Drag: 5.56 | LOC: 376/300  🎯 Target: Function: `classifyError` (High Local Complexity (4.5). Logic heavy.)
- [ ] **../../src/systems/Exporter/ExporterUpload.res**
  - *Reason:* [Nesting: 4.20, Density: 0.17, Coupling: 0.04] | Drag: 5.39 | LOC: 493/300  🎯 Target: Function: `uploadedCount` (High Local Complexity (8.5). Logic heavy.)
- [ ] **../../src/utils/LoggerTelemetry.res**
  - *Reason:* [Nesting: 3.00, Density: 0.21, Coupling: 0.06] | Drag: 4.35 | LOC: 441/300  🎯 Target: Function: `parseRetryAfterHeaderMs` (High Local Complexity (4.8). Logic heavy.)
- [ ] **../../src/utils/PersistenceLayer.res**
  - *Reason:* [Nesting: 3.00, Density: 0.13, Coupling: 0.06] | Drag: 4.29 | LOC: 499/300  🎯 Target: Function: `getAutosaveCostStats` (High Local Complexity (12.0). Logic heavy.)
- [ ] **../../src/systems/OperationLifecycle.res**
  - *Reason:* [Nesting: 3.60, Density: 0.21, Coupling: 0.03] | Drag: 4.93 | LOC: 401/300  🎯 Target: Function: `ttlMsForType` (High Local Complexity (7.0). Logic heavy.)

---

