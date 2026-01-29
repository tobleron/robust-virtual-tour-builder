# SYSTEM MASTER PLAN
## 📚 LEGEND & DEFINITIONS
*   **LOC:** Total non-comment lines.
*   **Drag:** Complexity multiplier (1.0 = base).
*   **Cognitive Capacity:** Inference energy required (Goal: < 100%).
*   **Read Tax:** Tokens and time overhead for switching context between files.
*   **AI Context Fog:** High-complexity peak regions within a file.

---

## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION (1)
- [ ] `../../backend/src/pathfinder.rs`

---

## 🧩 MERGE TASKS (16)
### Merge Folder: `../../src/components`
- **Reason:** Read Tax high (Score 3.20).
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
### Merge Folder: `../../backend/src/middleware`
- **Reason:** Read Tax high (Score 4.00).
- **Files:**
  - `request_tracker.rs`
  - `quota_check.rs`
  - `auth.rs`
  - `mod.rs`
### Merge Folder: `../../backend/src/services/auth`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `mod.rs`
  - `jwt.rs`
### Merge Folder: `../../backend/src/api/media`
- **Reason:** Read Tax high (Score 2.50).
- **Files:**
  - `serve.rs`
  - `similarity.rs`
  - `image.rs`
  - `video.rs`
  - `mod.rs`
### Merge Folder: `../../backend/src/services/project`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `package.rs`
  - `mod.rs`
  - `load.rs`
  - `validate.rs`
### Merge Folder: `../../backend/src/services/media`
- **Reason:** Read Tax high (Score 6.00).
- **Files:**
  - `resizing.rs`
  - `naming.rs`
  - `webp.rs`
  - `mod.rs`
  - `naming_old.rs`
  - `storage.rs`
### Merge Folder: `../../src/core`
- **Reason:** Read Tax high (Score 1.50).
- **Files:**
  - `SimHelpers.res`
  - `Reducer.res`
  - `ViewerState.res`
  - `Actions.res`
  - `SceneHelpers.res`
  - `UiHelpers.res`
  - `ViewerTypes.res`
  - `SharedTypes.res`
  - `AppContext.res`
  - `Types.res`
  - `Schemas.res`
  - `GlobalStateBridge.res`
  - `State.res`
  - `AuthContext.res`
  - `SceneCache.res`
### Merge Folder: `../../backend/src`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `lib.rs`
  - `models.rs`
  - `metrics.rs`
  - `main.rs`
### Merge Folder: `../../src/systems`
- **Reason:** Read Tax high (Score 3.30).
- **Files:**
  - `Resizer.res`
  - `VideoEncoder.res`
  - `SvgManager.res`
  - `NavigationFSM.res`
  - `LinkEditorLogic.res`
  - `TourTemplates.res`
  - `ViewerSystem.res`
  - `BackendApi.res`
  - `ImageValidator.res`
  - `Simulation.res`
  - `AudioManager.res`
  - `PanoramaClusterer.res`
  - `EventBus.res`
  - `FingerprintService.res`
  - `ProjectData.res`
  - `ExifReportGenerator.res`
  - `UploadTypes.res`
  - `Teaser.res`
  - `Scene.res`
  - `Navigation.res`
  - `Api.res`
  - `CursorPhysics.res`
  - `UploadProcessor.res`
  - `ExifParser.res`
  - `NavigationController.res`
  - `NavigationGraph.res`
  - `HotspotLine.res`
  - `NavigationUI.res`
  - `InputSystem.res`
  - `ProjectManager.res`
  - `DownloadSystem.res`
  - `NavigationRenderer.res`
  - `Exporter.res`
### Merge Folder: `../../src/components/ui`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `Shadcn.res`
  - `LucideIcons.res`
### Merge Folder: `../../src/utils`
- **Reason:** Read Tax high (Score 1.60).
- **Files:**
  - `GeoUtils.res`
  - `PersistenceLayer.res`
  - `ProgressBar.res`
  - `ColorPalette.res`
  - `StateInspector.res`
  - `TourLogic.res`
  - `Logger.res`
  - `ImageOptimizer.res`
  - `UrlUtils.res`
  - `LazyLoad.res`
  - `PathInterpolation.res`
  - `ProjectionMath.res`
  - `RequestQueue.res`
  - `Constants.res`
  - `SessionStore.res`
  - `Version.res`
### Merge Folder: `../../backend/src/api`
- **Reason:** Read Tax high (Score 3.00).
- **Files:**
  - `telemetry.rs`
  - `auth.rs`
  - `mod.rs`
  - `project.rs`
  - `geocoding.rs`
  - `utils.rs`
### Merge Folder: `../../backend/src/services/geocoding`
- **Reason:** Read Tax high (Score 2.00).
- **Files:**
  - `logic.rs`
  - `mod.rs`
### Merge Folder: `../../src`
- **Reason:** Read Tax high (Score 2.50).
- **Files:**
  - `ReBindings.res`
  - `App.res`
  - `Main.res`
  - `ServiceWorkerMain.res`
  - `ServiceWorker.res`
### Merge Folder: `../../backend/src/services/media/analysis`
- **Reason:** Read Tax high (Score 3.00).
- **Files:**
  - `mod.rs`
  - `quality.rs`
  - `exif.rs`
### Merge Folder: `../../backend/src/services`
- **Reason:** Read Tax high (Score 5.00).
- **Files:**
  - `shutdown.rs`
  - `database.rs`
  - `upload_quota.rs`
  - `mod.rs`
  - `upload_quota_tests.rs`
