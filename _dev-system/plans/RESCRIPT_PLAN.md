# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (15)
- [ ] **../../src/systems/TourTemplates/TourScriptUINav.res**
  - *Reason:* [Nesting: 0.00, Density: 0.00, Coupling: 0.00] | Drag: 1.00 | LOC: 979/419  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.
- [ ] **../../src/utils/NetworkStatus.res**
  - *Reason:* [Nesting: 2.40, Density: 0.36, Coupling: 0.03] | Drag: 4.03 | LOC: 385/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.  🎯 Target: Function: `initialize` (High Local Complexity (9.0). Logic heavy.)
- [ ] **../../src/systems/TourTemplates/TourScriptNavigation.res**
  - *Reason:* [Nesting: 0.00, Density: 0.00, Coupling: 0.00] | Drag: 1.00 | LOC: 1051/419  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.
- [ ] **../../src/components/ReactHotspotLayer.res**
  - *Reason:* [Nesting: 6.00, Density: 0.39, Coupling: 0.08] | Drag: 7.50 | LOC: 404/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.  🎯 Target: Function: `make` (High Local Complexity (41.0). Logic heavy.)
- [ ] **../../src/site/PortalTypes.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 194)
- [ ] **../../src/systems/TeaserRecorderHudSupport.res**
  - *Reason:* [Nesting: 4.20, Density: 0.35, Coupling: 0.03] | Drag: 5.58 | LOC: 256/300  ⚠️ Trigger: Drag above target (1.80) with file already at 256 LOC.  🎯 Target: Function: `clampCorner` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/systems/TourTemplates/TourScriptUIMap.res**
  - *Reason:* [Nesting: 0.00, Density: 0.00, Coupling: 0.00] | Drag: 1.00 | LOC: 588/419  ⚠️ Trigger: Oversized beyond the preferred 250-350 LOC working band.
- [ ] **../../src/utils/RequestQueue.res**
  - *Reason:* [Nesting: 3.00, Density: 0.15, Coupling: 0.06] | Drag: 4.25 | LOC: 253/300  ⚠️ Trigger: Drag above target (1.80) with file already at 253 LOC.  🎯 Target: Function: `pushByPriority` (High Local Complexity (3.5). Logic heavy.)
- [ ] **../../src/components/VisualPipelineEdgePaths.res**
  - *Reason:* [Nesting: 4.80, Density: 0.43, Coupling: 0.05] | Drag: 6.23 | LOC: 253/300  ⚠️ Trigger: Drag above target (1.80) with file already at 253 LOC.  🎯 Target: Function: `clipId` (High Local Complexity (2.5). Logic heavy.)
- [ ] **../../src/components/Sidebar/SidebarActionsSupport.res**
  - *Reason:* [Nesting: 3.60, Density: 0.14, Coupling: 0.06] | Drag: 4.83 | LOC: 254/300  ⚠️ Trigger: Drag above target (1.80) with file already at 254 LOC.  🎯 Target: Function: `saveTargetLabel` (High Local Complexity (3.0). Logic heavy.)
- [ ] **../../src/site/PortalApi.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 362)
- [ ] **../../src/site/PortalApi.res**
  - *Reason:* [Nesting: 1.80, Density: 0.19, Coupling: 0.06] | Drag: 2.99 | LOC: 362/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.  🎯 Target: Function: `authHeaderValue` (High Local Complexity (5.8). Logic heavy.)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 1.80, Density: 0.29, Coupling: 0.07] | Drag: 3.17 | LOC: 279/300  ⚠️ Trigger: Drag above target (1.80) with file already at 279 LOC.  🎯 Target: Function: `init` (High Local Complexity (18.8). Logic heavy.)
- [ ] **../../src/site/PortalApp.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 2354)
- [ ] **../../src/systems/TourTemplateHtml.res**
  - *Reason:* [Nesting: 3.00, Density: 0.01, Coupling: 0.01] | Drag: 4.01 | LOC: 621/300  ⚠️ Trigger: Drag above target (1.80); keep the module within the 250-350 LOC working band if you extract helpers.

---

