# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC (Lines of Code):** Source lines excluding comments and whitespace.
*   **Drag:** A calculated resistance metric based on nesting depth, logic density, and complexity penalties. Higher drag reduces the allowed LOC.
*   **Limit:** The dynamic LOC limit for a specific file, calculated as `(Base_Limit * Role_Multiplier) / Drag`.
*   **Role:** The architectural classification (e.g., `orchestrator`, `ui-component`) which determines the base allowed size.
*   **Pattern:** A specific code construct (e.g., `unwrap`, `!important`) that is restricted or forbidden.

---

## 🏗️ STRUCTURAL REFACTOR TASKS (10)
**Action:** Implement Vertical Slicing to reduce directory traversal overhead.

- [ ] **Viewer** (Action: Vertical Slice)
  - *Reason:* Feature 'Viewer' spread across 5 folders (Fragmentation Tax)
- [ ] **mod** (Action: Vertical Slice)
  - *Reason:* Feature 'mod' spread across 16 folders (Fragmentation Tax)
- [ ] **Simulation** (Action: Vertical Slice)
  - *Reason:* Feature 'Simulation' spread across 2 folders (Fragmentation Tax)
- [ ] **Navigation** (Action: Vertical Slice)
  - *Reason:* Feature 'Navigation' spread across 2 folders (Fragmentation Tax)
- [ ] **Upload** (Action: Vertical Slice)
  - *Reason:* Feature 'Upload' spread across 2 folders (Fragmentation Tax)
- [ ] **Scene** (Action: Vertical Slice)
  - *Reason:* Feature 'Scene' spread across 5 folders (Fragmentation Tax)
- [ ] **Project** (Action: Vertical Slice)
  - *Reason:* Feature 'Project' spread across 2 folders (Fragmentation Tax)
- [ ] **Hotspot** (Action: Vertical Slice)
  - *Reason:* Feature 'Hotspot' spread across 3 folders (Fragmentation Tax)
- [ ] **Tour** (Action: Vertical Slice)
  - *Reason:* Feature 'Tour' spread across 2 folders (Fragmentation Tax)
- [ ] **App** (Action: Vertical Slice)
  - *Reason:* Feature 'App' spread across 3 folders (Fragmentation Tax)

---

## 🧩 MERGE TASKS (26)
### Merge Folder: `../../backend/src/pathfinder`
- **Reason:** Score 7.00 > 1.0
- **Files:**
  - `graph_utils.rs`
  - `graph.rs`
  - `algorithms.rs`
  - `view_utils.rs`
  - `mod.rs`
  - `tests.rs`
  - `utils.rs`
### Merge Folder: `../../backend/src/api/media/image`
- **Reason:** Score 4.00 > 1.0
- **Files:**
  - `resize_batch.rs`
  - `extract_metadata.rs`
  - `optimize.rs`
  - `image_utils.rs`
  - `mod.rs`
  - `image_logic.rs`
  - `process_full.rs`
  - `tests.rs`
### Merge Folder: `../../src/components`
- **Reason:** Score 3.20 > 1.0
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
### Merge Folder: `../../src/systems`
- **Reason:** Score 7.80 > 1.0
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
  - `Api.res`
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
### Merge Folder: `../../backend/src/api/project/storage`
- **Reason:** Score 2.00 > 1.0
- **Files:**
  - `storage_logic.rs`
  - `mod.rs`
### Merge Folder: `../../backend/src/services/media/analysis`
- **Reason:** Score 3.00 > 1.0
- **Files:**
  - `mod.rs`
  - `quality.rs`
  - `exif.rs`
### Merge Folder: `../../backend/src/api`
- **Reason:** Score 6.00 > 1.0
- **Files:**
  - `telemetry.rs`
  - `auth.rs`
  - `mod.rs`
  - `telemetry_logic.rs`
  - `geocoding.rs`
  - `utils.rs`
### Merge Folder: `../../src/components/ui`
- **Reason:** Score 2.00 > 1.0
- **Files:**
  - `Shadcn.res`
  - `LucideIcons.res`
### Merge Folder: `../../backend/src/services/auth`
- **Reason:** Score 2.00 > 1.0
- **Files:**
  - `mod.rs`
  - `jwt.rs`
### Merge Folder: `../../backend/src/services/project`
- **Reason:** Score 2.00 > 1.0
- **Files:**
  - `package.rs`
  - `mod.rs`
  - `load.rs`
  - `validate.rs`
### Merge Folder: `../../backend/src/services/geocoding`
- **Reason:** Score 2.00 > 1.0
- **Files:**
  - `logic.rs`
  - `mod.rs`
### Merge Folder: `../../backend/src/pathfinder/algorithms`
- **Reason:** Score 2.00 > 1.0
- **Files:**
  - `timeline.rs`
  - `walk.rs`
### Merge Folder: `../../backend/src/api/media/video`
- **Reason:** Score 4.00 > 1.0
- **Files:**
  - `transcode.rs`
  - `teaser.rs`
  - `mod.rs`
  - `video_logic.rs`
### Merge Folder: `../../backend/src/services/media`
- **Reason:** Score 6.00 > 1.0
- **Files:**
  - `resizing.rs`
  - `naming.rs`
  - `webp.rs`
  - `mod.rs`
  - `naming_old.rs`
  - `storage.rs`
### Merge Folder: `../../backend/src/api/media`
- **Reason:** Score 3.00 > 1.0
- **Files:**
  - `serve.rs`
  - `similarity.rs`
  - `mod.rs`
### Merge Folder: `../../src/core/reducers`
- **Reason:** Score 9.00 > 1.0
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
### Merge Folder: `../../backend/src`
- **Reason:** Score 3.00 > 1.0
- **Files:**
  - `lib.rs`
  - `metrics.rs`
  - `main.rs`
### Merge Folder: `../../src/core`
- **Reason:** Score 1.90 > 1.0
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
  - `AuthContext.res`
  - `SceneCache.res`
### Merge Folder: `../../backend/src/models`
- **Reason:** Score 10.00 > 1.0
- **Files:**
  - `telemetry.rs`
  - `session.rs`
  - `metadata.rs`
  - `similarity.rs`
  - `user.rs`
  - `mod.rs`
  - `validation.rs`
  - `project.rs`
  - `errors.rs`
  - `geocoding.rs`
### Merge Folder: `../../src`
- **Reason:** Score 5.00 > 1.0
- **Files:**
  - `ReBindings.res`
  - `App.res`
  - `Main.res`
  - `ServiceWorkerMain.res`
  - `ServiceWorker.res`
### Merge Folder: `../../src/utils`
- **Reason:** Score 2.00 > 1.0
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
### Merge Folder: `../../backend/src/middleware`
- **Reason:** Score 4.00 > 1.0
- **Files:**
  - `request_tracker.rs`
  - `quota_check.rs`
  - `auth.rs`
  - `mod.rs`
### Merge Folder: `../../src/components/SceneList`
- **Reason:** Score 2.00 > 1.0
- **Files:**
  - `SceneItem.res`
  - `SceneListMain.res`
### Merge Folder: `../../backend/src/api/project`
- **Reason:** Score 5.00 > 1.0
- **Files:**
  - `export.rs`
  - `export_utils.rs`
  - `mod.rs`
  - `validation.rs`
  - `navigation.rs`
### Merge Folder: `../../backend/src/services`
- **Reason:** Score 5.00 > 1.0
- **Files:**
  - `shutdown.rs`
  - `database.rs`
  - `upload_quota.rs`
  - `mod.rs`
  - `upload_quota_tests.rs`
### Merge Folder: `../../src/bindings`
- **Reason:** Score 6.00 > 1.0
- **Files:**
  - `WebApiBindings.res`
  - `GraphicsBindings.res`
  - `BrowserBindings.res`
  - `ViewerBindings.res`
  - `IdbBindings.res`
  - `DomBindings.res`
