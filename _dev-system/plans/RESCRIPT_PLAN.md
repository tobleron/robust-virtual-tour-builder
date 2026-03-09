# RESCRIPT MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines. (Lower is easier to read).
*   **Drag:** Complexity multiplier. (Target: < 1.8). High Drag means AI agents struggle to track state.
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead incurred when switching between many small files.
*   **AI Context Fog:** Regions of code with overlapping logic paths that cause model hallucination.

---

## 🛠️ SURGICAL REFACTOR TASKS (53)
- [ ] **../../src/components/VisualPipeline.res**
  - *Reason:* [Nesting: 4.20, Density: 0.08, Coupling: 0.04] | Drag: 5.28 | LOC: 1011/300  🎯 Target: Function: `make` (High Local Complexity (12.7). Logic heavy.)
- [ ] **../../src/components/Sidebar/SidebarExportLogic.res**
  - *Reason:* [Nesting: 4.80, Density: 0.20, Coupling: 0.08] | Drag: 6.37 | LOC: 349/300  ⚠️ Trigger: Drag above target (1.80) with file already at 349 LOC.  🎯 Target: Function: `publishProjectData` (High Local Complexity (6.0). Logic heavy.)
- [ ] **../../src/components/HotspotManager.res**
  - *Reason:* [Nesting: 3.00, Density: 0.36, Coupling: 0.11] | Drag: 4.39 | LOC: 270/300  ⚠️ Trigger: Drag above target (1.80) with file already at 270 LOC.  🎯 Target: Function: `isReturnLink` (High Local Complexity (5.0). Logic heavy.)
- [ ] **../../src/systems/Simulation/SimulationNavigation.res**
  - *Reason:* [Nesting: 3.60, Density: 0.10, Coupling: 0.08] | Drag: 4.70 | LOC: 261/300  ⚠️ Trigger: Drag above target (1.80) with file already at 261 LOC.  🎯 Target: Function: `start` (High Local Complexity (5.9). Logic heavy.)
- [ ] **../../src/systems/Navigation/NavigationController.res**
  - *Reason:* [Nesting: 4.20, Density: 0.10, Coupling: 0.09] | Drag: 5.30 | LOC: 293/300  ⚠️ Trigger: Drag above target (1.80) with file already at 293 LOC.  🎯 Target: Function: `taskInfo` (High Local Complexity (18.2). Logic heavy.)
- [ ] **../../src/utils/LoggerTelemetry.res**
  - *Reason:* [Nesting: 3.00, Density: 0.20, Coupling: 0.06] | Drag: 4.34 | LOC: 453/300  🎯 Target: Function: `parseRetryAfterHeaderMs` (High Local Complexity (4.8). Logic heavy.)
- [ ] **../../src/systems/Api/AuthenticatedClientRequest.res**
  - *Reason:* [Nesting: 2.40, Density: 0.15, Coupling: 0.10] | Drag: 3.55 | LOC: 253/300  ⚠️ Trigger: Drag above target (1.80) with file already at 253 LOC.  🎯 Target: Function: `classifyRateLimitScope` (High Local Complexity (8.0). Logic heavy.)
- [ ] **../../src/components/Sidebar/SidebarActions.res**
  - *Reason:* [Nesting: 7.80, Density: 0.19, Coupling: 0.06] | Drag: 9.01 | LOC: 377/300  🎯 Target: Function: `onCancel` (High Local Complexity (3.0). Logic heavy.)
- [ ] **../../src/systems/TeaserHeadlessLogic.res**
  - *Reason:* [Nesting: 7.80, Density: 0.21, Coupling: 0.09] | Drag: 9.26 | LOC: 348/300  ⚠️ Trigger: Drag above target (1.80) with file already at 348 LOC.  🎯 Target: Function: `etaSeconds` (High Local Complexity (5.0). Logic heavy.)
- [ ] **../../src/systems/Api/MediaApi.res**
  - *Reason:* [Nesting: 3.60, Density: 0.31, Coupling: 0.10] | Drag: 5.03 | LOC: 270/300  ⚠️ Trigger: Drag above target (1.80) with file already at 270 LOC.  🎯 Target: Function: `reserveProcessFullSlot` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/components/PreviewArrow.res**
  - *Reason:* [Nesting: 3.60, Density: 0.14, Coupling: 0.08] | Drag: 4.83 | LOC: 419/300  🎯 Target: Function: `handleMainClick` (High Local Complexity (7.1). Logic heavy.)
- [ ] **../../src/systems/HotspotLine/HotspotLineDrawing.res**
  - *Reason:* [Nesting: 3.00, Density: 0.21, Coupling: 0.06] | Drag: 4.21 | LOC: 280/300  ⚠️ Trigger: Drag above target (1.80) with file already at 280 LOC.  🎯 Target: Function: `waypointsRaw` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/systems/Scene/SceneLoader.res**
  - *Reason:* [Nesting: 2.40, Density: 0.11, Coupling: 0.09] | Drag: 3.57 | LOC: 266/300  ⚠️ Trigger: Drag above target (1.80) with file already at 266 LOC.  🎯 Target: Function: `cleanupLoadTimeout` (High Local Complexity (3.0). Logic heavy.)
- [ ] **../../src/systems/Exporter/ExporterPackaging.res**
  - *Reason:* [Nesting: 3.60, Density: 0.06, Coupling: 0.06] | Drag: 4.67 | LOC: 500/300  🎯 Target: Function: `isAborted` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/components/Sidebar/UseSidebarProcessing.res**
  - *Reason:* [Nesting: 2.40, Density: 0.01, Coupling: 0.07] | Drag: 3.43 | LOC: 431/300  🎯 Target: Function: `expectedTourName` (High Local Complexity (1.0). Logic heavy.)
- [ ] **../../src/utils/PersistenceLayer.res**
  - *Reason:* [Nesting: 4.80, Density: 0.31, Coupling: 0.05] | Drag: 6.25 | LOC: 571/300  🎯 Target: Function: `getAutosaveCostStats` (High Local Complexity (12.0). Logic heavy.)
- [ ] **../../src/systems/OperationLifecycle.res**
  - *Reason:* [Nesting: 3.60, Density: 0.21, Coupling: 0.03] | Drag: 4.93 | LOC: 404/300  🎯 Target: Function: `ttlMsForType` (High Local Complexity (7.0). Logic heavy.)
- [ ] **../../src/systems/Scene/SceneTransition.res**
  - *Reason:* [Nesting: 2.40, Density: 0.07, Coupling: 0.08] | Drag: 3.47 | LOC: 305/300  ⚠️ Trigger: Drag above target (1.80) with file already at 305 LOC.
- [ ] **../../src/systems/TeaserRecorderHud.res**
  - *Reason:* [Nesting: 5.40, Density: 0.27, Coupling: 0.03] | Drag: 6.71 | LOC: 457/300  🎯 Target: Function: `clampCorner` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/utils/WorkerPool.res**
  - *Reason:* [Nesting: 1.80, Density: 0.10, Coupling: 0.02] | Drag: 3.10 | LOC: 507/300  🎯 Target: Function: `createPoolSize` (High Local Complexity (7.0). Logic heavy.)
- [ ] **../../src/systems/Exporter.res**
  - *Reason:* [Nesting: 2.40, Density: 0.06, Coupling: 0.10] | Drag: 3.49 | LOC: 311/300  ⚠️ Trigger: Drag above target (1.80) with file already at 311 LOC.  🎯 Target: Function: `opId` (High Local Complexity (2.0). Logic heavy.)
- [ ] **../../src/core/HotspotHelpers.res**
  - *Reason:* [Nesting: 6.60, Density: 0.53, Coupling: 0.05] | Drag: 8.13 | LOC: 261/300  ⚠️ Trigger: Drag above target (1.80) with file already at 261 LOC.  🎯 Target: Function: `hotspotLinkId` (High Local Complexity (6.0). Logic heavy.)
- [ ] **../../src/components/Sidebar/SidebarUploadLogic.res**
  - *Reason:* [Nesting: 4.80, Density: 0.23, Coupling: 0.08] | Drag: 6.41 | LOC: 318/300  ⚠️ Trigger: Drag above target (1.80) with file already at 318 LOC.  🎯 Target: Function: `utilizationFactor` (High Local Complexity (4.0). Logic heavy.)
- [ ] **../../src/components/VisualPipelineLayout.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 85)
- [ ] **../../src/systems/Navigation/NavigationRenderer.res**
  - *Reason:* [Nesting: 4.20, Density: 0.03, Coupling: 0.08] | Drag: 5.32 | LOC: 266/300  ⚠️ Trigger: Drag above target (1.80) with file already at 266 LOC.  🎯 Target: Function: `blinkStartTime` (High Local Complexity (7.0). Logic heavy.)
- [ ] **../../src/utils/Retry.res**
  - *Reason:* [Nesting: 4.20, Density: 0.33, Coupling: 0.04] | Drag: 5.59 | LOC: 380/300  🎯 Target: Function: `classifyError` (High Local Complexity (4.5). Logic heavy.)
- [ ] **../../src/components/VisualPipelineHub.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 46)
- [ ] **../../src/components/UploadReport.res**
  - *Reason:* [Nesting: 4.20, Density: 0.15, Coupling: 0.08] | Drag: 5.37 | LOC: 295/300  ⚠️ Trigger: Drag above target (1.80) with file already at 295 LOC.  🎯 Target: Function: `state` (High Local Complexity (5.0). Logic heavy.)
- [ ] **../../src/systems/ProjectSystem.res**
  - *Reason:* [Nesting: 1.80, Density: 0.05, Coupling: 0.10] | Drag: 2.85 | LOC: 437/300  🎯 Target: Function: `notifyProjectValidationWarnings` (High Local Complexity (3.5). Logic heavy.)
- [ ] **../../src/components/SceneList.res**
  - *Reason:* [Nesting: 3.60, Density: 0.11, Coupling: 0.08] | Drag: 4.78 | LOC: 352/300  ⚠️ Trigger: Drag above target (1.80) with file already at 352 LOC.  🎯 Target: Function: `make` (High Local Complexity (23.8). Logic heavy.)
- [ ] **../../src/systems/TeaserManifest.res**
  - *Reason:* [Nesting: 3.00, Density: 0.15, Coupling: 0.05] | Drag: 4.15 | LOC: 352/300  ⚠️ Trigger: Drag above target (1.80) with file already at 352 LOC.  🎯 Target: Function: `pickWaypointHotspot` (High Local Complexity (6.0). Logic heavy.)
- [ ] **../../src/systems/Resizer/ResizerLogic.res**
  - *Reason:* [Nesting: 2.40, Density: 0.06, Coupling: 0.11] | Drag: 3.46 | LOC: 310/300  ⚠️ Trigger: Drag above target (1.80) with file already at 310 LOC.
- [ ] **../../src/components/LabelMenu.res**
  - *Reason:* [Nesting: 2.40, Density: 0.11, Coupling: 0.06] | Drag: 3.57 | LOC: 521/300  🎯 Target: Function: `bulkDeleteBlockReason` (High Local Complexity (18.5). Logic heavy.)
- [ ] **../../src/systems/TourTemplates.res**
  - *Reason:* [Nesting: 3.00, Density: 0.03, Coupling: 0.02] | Drag: 4.03 | LOC: 337/300  ⚠️ Trigger: Drag above target (1.80) with file already at 337 LOC.
- [ ] **../../src/core/JsonParsersDecoders.res**
  - *Reason:* [Nesting: 3.00, Density: 0.65, Coupling: 0.05] | Drag: 4.65 | LOC: 377/300  🎯 Target: Function: `project` (High Local Complexity (13.4). Logic heavy.)
- [ ] **../../src/components/SceneList/SceneItem.res**
  - *Reason:* [Nesting: 5.40, Density: 0.26, Coupling: 0.10] | Drag: 6.73 | LOC: 363/300  ⚠️ Trigger: Drag above target (1.80) with file already at 363 LOC.  🎯 Target: Function: `qualityScore` (High Local Complexity (5.0). Logic heavy.)
- [ ] **../../src/systems/Exporter/ExporterUpload.res**
  - *Reason:* [Nesting: 4.20, Density: 0.17, Coupling: 0.05] | Drag: 5.39 | LOC: 499/300  🎯 Target: Function: `uploadedCount` (High Local Complexity (8.5). Logic heavy.)
- [ ] **../../src/components/Sidebar/SidebarLogicHandler.res**
  - *Reason:* [Nesting: 4.80, Density: 0.15, Coupling: 0.11] | Drag: 5.99 | LOC: 393/300  🎯 Target: Function: `state` (High Local Complexity (9.5). Logic heavy.)
- [ ] **../../src/App.res**
  - *Reason:* [Nesting: 6.60, Density: 0.34, Coupling: 0.11] | Drag: 7.94 | LOC: 429/300  🎯 Target: Function: `make` (High Local Complexity (35.3). Logic heavy.)
- [ ] **../../src/systems/ExifParser.res**
  - *Reason:* [Nesting: 4.20, Density: 0.13, Coupling: 0.04] | Drag: 5.33 | LOC: 371/300  ⚠️ Trigger: Drag above target (1.80) with file already at 371 LOC.  🎯 Target: Function: `getValue` (High Local Complexity (4.9). Logic heavy.)
- [ ] **../../src/core/AppContext.res**
  - *Reason:* [Nesting: 3.60, Density: 0.22, Coupling: 0.10] | Drag: 4.91 | LOC: 360/300  ⚠️ Trigger: Drag above target (1.80) with file already at 360 LOC.  🎯 Target: Function: `dispatch` (High Local Complexity (8.2). Logic heavy.)
- [ ] **../../src/utils/RequestQueue.res**
  - *Reason:* [Nesting: 3.00, Density: 0.16, Coupling: 0.06] | Drag: 4.25 | LOC: 269/300  ⚠️ Trigger: Drag above target (1.80) with file already at 269 LOC.  🎯 Target: Function: `promoteStarved` (High Local Complexity (8.0). Logic heavy.)
- [ ] **../../src/ServiceWorkerMain.res**
  - *Reason:* [Nesting: 2.40, Density: 0.17, Coupling: 0.08] | Drag: 3.57 | LOC: 302/300  ⚠️ Trigger: Drag above target (1.80) with file already at 302 LOC.
- [ ] **../../src/systems/Simulation.res**
  - *Reason:* [Nesting: 7.20, Density: 0.25, Coupling: 0.08] | Drag: 8.47 | LOC: 383/300  🎯 Target: Function: `make` (High Local Complexity (9.1). Logic heavy.)
- [ ] **../../src/systems/Navigation/NavigationSupervisor.res**
  - *Reason:* [Nesting: 2.40, Density: 0.02, Coupling: 0.04] | Drag: 3.55 | LOC: 302/300  ⚠️ Trigger: Drag above target (1.80) with file already at 302 LOC.  🎯 Target: Function: `notifyListeners` (High Local Complexity (1.5). Logic heavy.)
- [ ] **../../src/systems/Traversal/CanonicalTraversal.res**
  - *Reason:* [Nesting: 4.20, Density: 0.15, Coupling: 0.05] | Drag: 5.45 | LOC: 403/300  🎯 Target: Function: `stripSceneTag` (High Local Complexity (5.0). Logic heavy.)
- [ ] **../../src/components/VisualPipelineRouter.res**
  - *Reason:* Unreachable Module. Not referenced by any entry point. (LOC: 90)
- [ ] **../../src/utils/Logger.res**
  - *Reason:* [Nesting: 2.40, Density: 0.09, Coupling: 0.07] | Drag: 3.52 | LOC: 420/300
- [ ] **../../src/systems/TeaserRecorder.res**
  - *Reason:* [Nesting: 6.00, Density: 0.28, Coupling: 0.06] | Drag: 7.31 | LOC: 356/300  ⚠️ Trigger: Drag above target (1.80) with file already at 356 LOC.  🎯 Target: Function: `_` (High Local Complexity (6.0). Logic heavy.)
- [ ] **../../src/core/SceneOperations.res**
  - *Reason:* [Nesting: 7.20, Density: 0.21, Coupling: 0.06] | Drag: 8.43 | LOC: 370/300  ⚠️ Trigger: Drag above target (1.80) with file already at 370 LOC.  🎯 Target: Function: `nextMovingHotspot` (High Local Complexity (8.2). Logic heavy.)
- [ ] **../../src/systems/Api/ProjectApi.res**
  - *Reason:* [Nesting: 3.00, Density: 0.32, Coupling: 0.05] | Drag: 4.32 | LOC: 440/300  🎯 Target: Function: `listDashboardProjects` (High Local Complexity (3.4). Logic heavy.)
- [ ] **../../src/utils/AsyncQueue.res**
  - *Reason:* [Nesting: 3.60, Density: 0.12, Coupling: 0.02] | Drag: 4.88 | LOC: 470/300  🎯 Target: Function: `toSortedCopy` (High Local Complexity (6.0). Logic heavy.)
- [ ] **../../src/systems/TeaserOfflineCfrRenderer.res**
  - *Reason:* [Nesting: 2.40, Density: 0.09, Coupling: 0.12] | Drag: 3.49 | LOC: 298/300  ⚠️ Trigger: Drag above target (1.80) with file already at 298 LOC.  🎯 Target: Function: `floorLevelsInUse` (High Local Complexity (7.5). Logic heavy.)

---

