# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC (Lines of Code):** Source lines excluding comments and whitespace.
*   **Drag:** A calculated resistance metric based on nesting depth, logic density, and complexity penalties. Higher drag reduces the allowed LOC.
*   **Limit:** The dynamic LOC limit for a specific file, calculated as `(Base_Limit * Role_Multiplier) / Drag`.
*   **Role:** The architectural classification (e.g., `orchestrator`, `ui-component`) which determines the base allowed size.
*   **Pattern:** A specific code construct (e.g., `unwrap`, `!important`) that is restricted or forbidden.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (28)
**Action:** The AI Agent must analyze these files and update `_dev-system/config/efficiency.json` or add `@efficiency` headers.

- [ ] `../../tests/rescript-schema-shim.js`
- [ ] `../../tests/TestRunner.res`
- [ ] `../../tests/node-setup.js`
- [ ] `../../backend/tests/shutdown_test.rs`
- [ ] `../../backend/src/middleware/request_tracker.rs`
- [ ] `../../backend/src/middleware/quota_check.rs`
- [ ] `../../backend/src/middleware/auth.rs`
- [ ] `../../backend/src/pathfinder/graph.rs`
- [ ] `../../backend/src/pathfinder/algorithms.rs`
- [ ] `../../backend/src/metrics.rs`
- [ ] `../../backend/src/services/shutdown.rs`
- [ ] `../../backend/src/services/database.rs`
- [ ] `../../backend/src/services/auth/jwt.rs`
- [ ] `../../backend/src/services/upload_quota.rs`
- [ ] `../../backend/src/services/project/package.rs`
- [ ] `../../backend/src/services/project/load.rs`
- [ ] `../../backend/src/services/project/validate.rs`
- [ ] `../../backend/src/services/upload_quota_tests.rs`
- [ ] `../../backend/src/services/media/resizing.rs`
- [ ] `../../backend/src/services/media/analysis/quality.rs`
- [ ] `../../backend/src/services/media/analysis/exif.rs`
- [ ] `../../backend/src/services/media/naming.rs`
- [ ] `../../backend/src/services/media/webp.rs`
- [ ] `../../backend/src/services/media/naming_old.rs`
- [ ] `../../backend/src/services/media/storage.rs`
- [ ] `../../package-lock.json`
- [ ] `../../rescript.json`
- [ ] `../../.vscode/settings.json`

---

## 🧩 MERGE TASKS (5)
### Merge Folder: `../../src/systems`
- **Reason:** Score 7.13 > 1.5
- **Files:**
  - `TeaserRecorderLogic.res`
  - `Resizer.res`
  - `VideoEncoder.res`
  - `ExifReportGeneratorLogicExtraction.res`
  - `ViewerFollow.res`
  - `HotspotLineLogic.res`
  - `SvgManager.res`
  - `NavigationFSM.res`
  - `LinkEditorLogic.res`
  - `SimulationLogic.res`
  - `UploadProcessorTypes.res`
  - `TourTemplates.res`
  - `TourTemplateScripts.res`
  - `ServerTeaser.res`
  - `TeaserRecorderTypes.res`
  - `HotspotLineTypes.res`
  - `HotspotLineUtils.res`
  - `TourTemplateAssets.res`
  - `TeaserRecorderOverlay.res`
  - `SceneTransitionManager.res`
  - `UploadProcessorLogic.res`
  - `ViewerPool.res`
  - `HotspotLineLogicArrow.res`
  - `BackendApi.res`
  - `TeaserRecorder.res`
  - `ImageValidator.res`
  - `SceneLoaderLogic.res`
  - `ExifReportGeneratorLogicLocation.res`
  - `AudioManager.res`
  - `PanoramaClusterer.res`
  - `EventBus.res`
  - `FingerprintService.res`
  - `SceneLoaderTypes.res`
  - `SceneLoaderLogicReuse.res`
  - `PannellumAdapter.res`
  - `SvgRenderer.res`
  - `SimulationPathGenerator.res`
  - `UploadProcessorLogicLogic.res`
  - `ProjectData.res`
  - `ExifReportGeneratorTypes.res`
  - `ExifReportGenerator.res`
  - `ExifReportGeneratorUtils.res`
  - `SimulationNavigation.res`
  - `SceneLoader.res`
  - `SimulationChainSkipper.res`
  - `ExifReportGeneratorLogic.res`
  - `PannellumLifecycle.res`
  - `TeaserState.res`
  - `CursorPhysics.res`
  - `UploadProcessor.res`
  - `ExifParser.res`
  - `TeaserManager.res`
  - `ExifReportGeneratorLogicTypes.res`
  - `TourTemplateStyles.res`
  - `NavigationController.res`
  - `NavigationGraph.res`
  - `ProjectManagerLogic.res`
  - `HotspotLineLogicLogic.res`
  - `ResizerLogic.res`
  - `HotspotLine.res`
  - `SimulationDriver.res`
  - `TeaserPlayback.res`
  - `NavigationUI.res`
  - `InputSystem.res`
  - `TeaserPathfinder.res`
  - `ProjectManager.res`
  - `HotspotLineLogicTypes.res`
  - `ExifReportGeneratorLogicGroups.res`
  - `SceneLoaderLogicConfig.res`
  - `ProjectManagerTypes.res`
  - `ResizerTypes.res`
  - `ResizerUtils.res`
  - `SceneSwitcher.res`
  - `DownloadSystem.res`
  - `SceneLoaderLogicEvents.res`
  - `NavigationRenderer.res`
  - `Exporter.res`

### Merge Folder: `../../src/core`
- **Reason:** Score 2.12 > 1.5
- **Files:**
  - `SimHelpers.res`
  - `Reducer.res`
  - `ViewerState.res`
  - `SceneHelpersParser.res`
  - `Actions.res`
  - `SceneHelpers.res`
  - `UiHelpers.res`
  - `ViewerTypes.res`
  - `SharedTypes.res`
  - `AppContext.res`
  - `Types.res`
  - `Schemas.res`
  - `SchemasShared.res`
  - `SchemasDomain.res`
  - `GlobalStateBridge.res`
  - `SceneHelpersLogic.res`
  - `State.res`
  - `SceneCache.res`

### Merge Folder: `../../src/components`
- **Reason:** Score 4.16 > 1.5
- **Files:**
  - `NotificationLayer.res`
  - `LabelMenu.res`
  - `HotspotManager.res`
  - `UploadReport.res`
  - `Tooltip.res`
  - `HotspotActionMenu.res`
  - `ViewerLoader.res`
  - `QualityIndicator.res`
  - `ViewerSnapshot.res`
  - `HotspotLayer.res`
  - `AppErrorBoundary.res`
  - `ViewerUI.res`
  - `PopOver.res`
  - `PersistentLabel.res`
  - `Sidebar.res`
  - `PreviewArrow.res`
  - `VisualPipeline.res`
  - `HotspotMenuLayer.res`
  - `ViewerHUD.res`
  - `FloorNavigation.res`
  - `ViewerManagerLogic.res`
  - `ReturnPrompt.res`
  - `NotificationContext.res`
  - `UtilityBar.res`
  - `ViewerLabelMenu.res`
  - `SnapshotOverlay.res`
  - `SceneList.res`
  - `ViewerManager.res`
  - `LinkModal.res`
  - `ModalContext.res`
  - `Portal.res`
  - `ErrorFallbackUI.res`

### Merge Folder: `../../src/core/reducers`
- **Reason:** Score 1.84 > 1.5
- **Files:**
  - `TimelineReducer.res`
  - `NavigationReducer.res`
  - `ProjectReducer.res`
  - `SimulationReducer.res`
  - `SceneReducer.res`
  - `UiReducer.res`
  - `mod.res`
  - `RootReducer.res`
  - `HotspotReducer.res`

### Merge Folder: `../../src/utils`
- **Reason:** Score 2.08 > 1.5
- **Files:**
  - `GeoUtils.res`
  - `PersistenceLayer.res`
  - `ProgressBar.res`
  - `ColorPalette.res`
  - `StateInspector.res`
  - `TourLogic.res`
  - `LoggerTelemetry.res`
  - `Logger.res`
  - `ImageOptimizer.res`
  - `UrlUtils.res`
  - `LazyLoad.res`
  - `LoggerLogic.res`
  - `PathInterpolation.res`
  - `ProjectionMath.res`
  - `RequestQueue.res`
  - `LoggerTypes.res`
  - `Constants.res`
  - `SessionStore.res`
  - `Version.res`
  - `VersionData.res`

