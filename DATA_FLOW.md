# 🌊 Data Flow Documentation

This document maps critical data flows through the system to help AI understand architectural boundaries and module interactions.

---

## 🔗 User Interaction Flows

### Scene Navigation
**Trigger:** User clicks scene thumbnail or navigation hotspot

**Flow:**
```
User Click Event
  → [src/components/SceneList/SceneItem.res], [src/components/HotspotLayer.res], or [src/components/FloorNavigation.res] handles click
  → [src/core/Capability.res] evaluates interaction permissions (`CanNavigate`, lock policy)
  → [src/core/Actions.res] defines navigation action contracts dispatched by UI and systems
  → [src/core/InteractionGuard.res] checks cooldowns using [src/core/InteractionPolicies.res]
  → [src/systems/Navigation.res] and [src/systems/NavigationLogic.res] normalize/route navigation intents
  → [src/core/HotspotTarget.res] resolves target scene IDs and canonical refs
  → [src/systems/Navigation/NavigationSupervisor.res] receives intent (auto-cancels previous task)
      → Creates AbortSignal for structured concurrency
      → dispatch(UserClickedScene) FSM event for UI reactivity
      → [src/components/LockFeedback.res] renders progress via NavigationSupervisor.addStatusListener()
      → [src/systems/OperationLifecycle.res] tracks navigation operation lifecycle and visibility thresholds
      → [src/systems/OperationLifecycleContext.res] and [src/systems/OperationLifecycleTypes.res] provide lifecycle context/payload modeling
  → [src/App.res] and [src/components/AppErrorBoundary.res] provide the top-level container
      → [src/components/ErrorFallbackUI.res] and [src/components/CriticalErrorMonitor.res] provide the crash UI and error monitoring
      → [src/Hooks.res] and [src/core/UiHelpers.res] manage top-level component lifecycle
  → [src/core/AppFSM.res] handles top-level state transition (e.g. Editing → Navigation)
  → [src/core/Reducer.res] processes FSM action using [src/core/Types.res], [src/core/ViewerState.res], [src/core/ViewerTypes.res], and [src/core/NavigationState.res]
      → [src/core/NavigationHelpers.res] computes target-aware transition metadata
  → [src/systems/Navigation/NavigationFSM.res] state transition (IdleFsm → Preloading)
  → [src/systems/Navigation/NavigationUI.res] manages prompt-level navigation UX during transitions
  → [src/systems/Navigation/NavigationController.res] subscribes to FSM changes
      → Calls SceneLoader with taskId and AbortSignal from Supervisor
  → [src/systems/Scene.res] and [src/systems/Scene/SceneLoader.res] coordinates viewer loading (with AbortSignal support)
      → [src/systems/SceneLoaderLogic.res] constructs scene configuration and Pannellum setup parameters
      → [src/systems/Scene/Loader/SceneLoaderConfig.res], [src/systems/Scene/Loader/SceneLoaderEvents.res], and [src/systems/Scene/Loader/SceneLoaderReuse.res] handle configuration, events, and instance reuse
      → [src/core/SceneCache.res] manages preloaded scene state
      → [src/components/ViewerManager.res], [src/components/ViewerManagerLogic.res], [src/components/ViewerManager/ViewerManagerLifecycle.res], [src/components/ViewerManager/ViewerManagerCleanup.res], [src/components/ViewerManager/ViewerManagerPreloading.res], [src/components/ViewerManager/ViewerManagerSceneLoad.res], [src/components/ViewerManager/ViewerManagerHotspots.res], [src/components/ViewerManager/ViewerManagerRatchet.res], [src/components/ViewerManager/ViewerManagerSimulation.res], and [src/components/ViewerManager/ViewerManagerIntro.res] manage active viewers and hook-level synchronization
      → [src/components/ViewerSceneElements.res], [src/components/ViewerUI.res], [src/components/ViewerHUD.res], and [src/components/ViewerLoader.res] render scene and interactive overlays
      → [src/systems/ViewerSystem.res], [src/systems/ViewerPool.res], [src/systems/ViewerLogic.res] manage viewer instance lifecycle
          → [src/systems/Viewer/ViewerAdapter.res], [src/systems/Viewer/ViewerPool.res], and [src/systems/Viewer/ViewerFollow.res] provide the underlying implementation
      → [src/systems/PannellumAdapter.res] and [src/systems/PannellumLifecycle.res] interface with engine
  → [src/systems/Scene/SceneSwitcher.res] handles journey initialization and auto-forwarding
  → [src/systems/Scene/SceneTransition.res] performs CSS crossfade and viewport swapping (with Supervisor coordination)
  → [src/systems/Navigation/NavigationGraph.res] projects link geometry and scene graph candidates
  → [src/systems/Navigation/NavigationRenderer.res] updates interactive navigation markers (using [src/components/Tooltip.res], [src/components/PreviewArrow.res], and [src/components/PersistentLabel.res])
  → [src/systems/AudioManager.res] triggers spatial audio transitions
  → [src/systems/Navigation/NavigationSupervisor.res] completes task and marks status Idle
```

### Upload Pipeline
**Trigger:** User selects images for upload

**Flow:**
```
User file selection
  → [src/components/Sidebar.res] (using [src/components/Sidebar/SidebarActions.res], [src/components/Sidebar/SidebarBranding.res], [src/components/Sidebar/SidebarProcessing.res], [src/components/Sidebar/SidebarProjectInfo.res], and [src/components/Sidebar/SidebarAbout.res])
    → [src/components/Sidebar/SidebarSearch.res], [src/components/Sidebar/SidebarFilters.res], [src/components/Sidebar/SidebarBatchManagement.res], [src/components/Sidebar/SidebarSorting.res], and [src/components/Sidebar/UseSidebarProcessing.res] for view orchestration
  → [src/components/Sidebar/SidebarLogic.res] and [src/components/SceneList.res] handle file input and display
  → [src/components/Sidebar/SidebarLogicHandler.res] dispatches upload/load/save/export actions
      → [src/components/Sidebar/SidebarUploadLogic.res], [src/components/Sidebar/SidebarSceneActions.res], and [src/components/Sidebar/SidebarExportLogic.res] provide specialized handlers
  → [src/components/Sidebar/SidebarBase.res] provides shared sidebar types and progress monitoring
  → [src/components/VisualPipeline/VisualPipelineComponent.res] (assisted by [src/components/VisualPipeline.res], [src/components/VisualPipelineLogic.res], [src/components/VisualPipeline/VisualPipelineStyles.res], [src/components/VisualPipelineStyles.res], and [src/components/VisualPipelineNode.res]) shows progress (using [src/utils/ProgressBar.res])
  → [src/systems/UploadProcessor.res] orchestrates the pipeline
  → [src/systems/UploadProcessorLogic.res] manages batch state (using [src/systems/UploadTypes.res] and [src/systems/Upload/UploadScanner.res])
  → [src/utils/NetworkStatus.res] pre-checks connectivity before allowing upload
  → [src/systems/FingerprintService.res] calculates unique image hashes
  → [src/systems/ImageValidator.res] validates formats and dimensions
  → [src/systems/Resizer.res] performs client-side pre-processing
      → [src/systems/Resizer/ResizerLogic.res] and [src/systems/Resizer/ResizerUtils.res] manage resizing tasks with [src/systems/Resizer/ResizerTypes.res]
      → [src/systems/Upload/UploadItemProcessor.res] and [src/systems/Upload/UploadUtils.res] handle per-item transformations
  → [src/utils/ImageOptimizer.res] applies final compression
  → [src/utils/ThumbnailGenerator.res] generates rectilinear thumbnail for local preview
  → [src/utils/OperationJournal.res] starts transaction (startOperation) using [src/utils/OperationJournal/JournalLogic.res] and [src/utils/OperationJournal/JournalPersistence.res]
  → [src/systems/Api/MediaApi.res] sends to backend
  → [backend/src/api/media/image_multipart.rs] and [backend/src/api/media/image.rs] receive files
    → [backend/src/api/project_multipart.rs] for project-level uploads
  → [backend/src/api/media/image_logic.rs] and [backend/src/api/media/image_tasks.rs] handle processing
  → [backend/src/api/media/serve.rs] manages file serving logic
  → [backend/src/services/upload_quota.rs] and [backend/src/services/upload_quota_tests.rs] enforce limits
  → [backend/src/services/media/analysis.rs] processes (EXIF, quality)
    → [backend/src/services/media/mod.rs], [backend/src/services/media/naming.rs] handle file naming
    → [backend/src/api/media/similarity.rs] identifies duplicate uploads
  → Returns analysis results to frontend
  → [src/core/Reducer.res] updates state using [src/core/SceneHelpers.res], [src/core/SceneInventory.res], [src/core/SceneNaming.res], and [src/core/SceneOperations.res]
    → [src/components/QualityIndicator.res] updates based on results
    → [src/systems/Upload/UploadFinalizer.res] handles post-upload state sync
    → [src/systems/Upload/UploadReporting.res] generates final batch summaries
  → [src/utils/OperationJournal.res] completes transaction
  → [src/systems/Upload/UploadRecovery.res] checks for interrupted tasks on retry
  → [src/systems/EtaSupport.res] provides ETA blending, formatting, and progress toast dispatching
```

### Custom Branding / Logo Upload
**Trigger:** User clicks on the project logo in the viewer HUD

**Flow:**
```
User Click on Viewer Logo
  → [src/components/ViewerHUD.res] handles click and triggers hidden file input
  → [src/core/Actions.res] (SetLogo) dispatched with Selected File
  → [src/core/Reducer.res] updates global Types.state.logo
  → [src/core/AppContext.res] broadcasts updated logo to all subscribers
  → [src/core/JsonParsersEncoders.res] / [src/core/JsonParsersDecoders.res] handle persistence in session
  → [src/systems/Exporter.res] prioritizes custom logo during ZIP assembly
  → [backend/src/services/project/package.rs] detects any "logo.*" format and bundles it
```

### State Persistence & Recovery
**Trigger:** App initialization or state change

**Flow:**
```
State changes
  → [src/core/AppStateBridge.res] notifies subscribers
  → [src/utils/PersistenceLayer.res] debounced save (2s)
  → [src/core/State.res] and [src/core/StateSnapshot.res] serialized by [src/core/JsonParsers.res], [src/core/JsonParsersEncoders.res], [src/core/JsonEncoders.res], and [src/core/JsonParsersShared.res]
  → [src/utils/NetworkStatus.res] monitors connectivity to adjust persistence behavior
  → IndexedDB storage [src/bindings/IdbBindings.res]

On startup ([src/Main.res]):
  → [src/components/RecoveryCheck.res], [src/components/RecoveryPrompt.res], and [src/components/ReturnPrompt.res] mount
  → [src/utils/RecoveryManager.res] checks for interrupted operations using [src/systems/ProjectManager/ProjectRecovery.res]
  → [src/utils/OperationJournal.res] checks journal for active transactions using [src/utils/OperationJournal/JournalLogic.res] and [src/utils/OperationJournal/JournalTypes.res]
  → [src/utils/PersistenceLayer.res] loads last session
  → [src/core/JsonParsersDecoders.res] deserializes
  → [src/core/Reducer.res] dispatches LoadProject
```

### Hotspot Management
**Trigger:** User adds/edits navigation hotspots

**Flow:**
```
User clicks to add hotspot
  → [src/components/HotspotManager.res] handles click event
  → [src/components/ReactHotspotLayer.res] projects hotspot markers from live viewer camera state for React-layer interaction previews
  → [src/components/HotspotActionMenu.res] and [src/components/HotspotMenuLayer.res] provide UI via [src/components/Portal.res] and [src/components/PopOver.res]
  → [src/components/ViewerLabelMenu.res] and [src/components/LabelMenu.res] for advanced labeling
  → [src/components/LinkModal.res], [src/components/ModalContext.res], and [src/systems/LinkEditorLogic.res] handle scene linking via modals
  → [src/core/HotspotHelpers.res] calculates pitch/yaw coordinates
  → dispatch(AddHotspot) via [src/core/AppContext.res]
  → [src/core/Reducer.res] updates state using [src/core/SceneMutations.res]
  → [src/systems/HotspotLine.res] and [src/systems/HotspotLineLogic.res] (assisted by [src/systems/HotspotLine/HotspotLineLogicArrow.res]) orchestrate visual connections
      → [src/systems/HotspotLine/HotspotLineState.res] caches line geometries
      → [src/systems/HotspotLine/HotspotLineUtils.res] calculates SVG paths
  → [src/systems/HotspotLine/HotspotLineDrawing.res] renders SVG overlays using [src/systems/SvgManager.res]
  → [src/utils/TimelineCleanup.res] removes orphaned timeline entries when hotspots are deleted/edited
  → [src/core/HubScene.res] detects hub scenes (2+ exit links) for animation behavior
```

### Simulation & Teaser Generation
**Trigger:** User initiates autopilot simulation or records a teaser

**Flow:**
```
User clicks "Start Simulation"
  → [src/systems/Simulation.res] initializes simulation
  → [src/systems/SimulationLogic.res] and [src/systems/Simulation/SimulationMainLogic.res] orchestrate waypoint logic
      → [src/systems/Simulation/SimulationPathGenerator.res] generates optimal paths using [src/systems/Simulation/SimulationTypes.res]
      → [src/systems/Simulation/SimulationNavigation.res] and [src/systems/Simulation/SimulationChainSkipper.res] manage movement
      → [src/systems/PanoramaClusterer.res] assists in logical grouping
      → [src/core/SimHelpers.res] and [src/core/SimulationHelpers.res] provide core simulation algorithms
  → [src/systems/Navigation/NavigationFSM.res] drives scene transitions
  → [src/systems/TeaserManager.res] manages recording sessions
      → [src/systems/TeaserManagerLogic.res], [src/systems/Teaser.res], [src/systems/TeaserLogic.res], [src/systems/TeaserLogicHelpers.res], [src/systems/TeaserPlayback.res], [src/systems/TeaserPlaybackManifest.res], [src/systems/TeaserStyleConfig.res], and [src/systems/TeaserState.res] handle playback and movement logic
      → [src/systems/TeaserHeadlessLogic.res] and [src/systems/TeaserRecorderHud.res] support headless rendering setup and recorder HUD behavior
      → [src/systems/TeaserPathfinder.res] specialized cinematic pathfinding
  → [src/systems/TeaserRecorder.res] captures viewports (using [src/components/SnapshotOverlay.res], [src/components/ViewerSnapshot.res])
  → [src/systems/TeaserStyleCatalog.res] provides style type definitions and availability flags
  → [src/systems/TeaserManifest.res] defines deterministic shot/segment manifests consumed by teaser renderers
  → [src/systems/TeaserRendererRegistry.res] dispatches style-specific manifest generation
  → [src/systems/TeaserStyleCinematic.res] builds Cinematic motion manifests
  → [src/systems/TeaserStyleFastShots.res] (stub: not implemented yet)
  → [src/systems/TeaserStyleSimpleCrossfade.res] (stub: not implemented yet)
  → [src/systems/TeaserOfflineCfrRenderer.res] renders deterministic CFR WebM from manifests
  → [src/systems/EtaSupport.res] provides ETA formatting for recording progress
  → [src/systems/ServerTeaser.res] (Optional) requests backend high-quality render
      → [backend/src/api/media/video.rs], [backend/src/api/media/video_logic.rs], [backend/src/api/media/video_logic_runtime.rs], [backend/src/api/media/video_runtime_impl.rs], [backend/src/api/media/video_capture.rs], and [backend/src/api/media/video_request_utils.rs] for transcoding and frame capture
      → [src/systems/VideoEncoder.res] and [src/systems/Exporter.res] for final assembly
```

### EXIF Analysis & Reporting
**Trigger:** User requests an EXIF report for uploaded scenes

**Flow:**
```
User clicks "Generate Report"
  → [src/systems/ExifReportGenerator.res] and [src/systems/ExifReportGeneratorLogic.res] orchestrate report assembly
      → [src/systems/ExifReport/ExifReportGeneratorLogicExtraction.res] and [src/systems/ExifReport/ExifReportGeneratorLogicTypes.res]
      → [src/systems/ExifReport/ExifReportGeneratorLogicLocation.res] centroid and geo analysis
      → [src/systems/ExifReport/ExifReportGeneratorLogicGroups.res] camera device categorization
  → [src/systems/ExifParser.res] and [src/systems/ExifUtils.res] handle binary extraction
  → [src/components/UploadReport.res] renders visual results
```

### Background Thumbnail Enhancement
**Trigger:** App mounted with existing equirectangular scene thumbnails
**Flow:**
```
[src/systems/ThumbnailProjectSystem.res] scans scenes on mount
  → Identifies scenes with None or Url(equirectangular) tinyFile
  → Loads scene.file (source equirectangular)
  → [src/utils/ThumbnailGenerator.res] projects rectilinear 120x80 thumbnail
  → dispatch(PatchSceneThumbnail) update session state
  → [src/utils/PersistenceLayer.res] saves updated thumbnail to local cache
```

### System Notification & Feedback
**Trigger:** Success/Error events across systems or user UI actions

**Flow:**
```
Trigger Event
  → [src/systems/EventBus.res] dispatches notification
  → [src/core/NotificationManager.res] processes queue (using [src/core/NotificationQueue.res] and [src/core/NotificationTypes.res])
  → [src/components/NotificationCenter.res] subscribes to manager and renders via custom ReScript toasts (confined to viewer)
  → [src/components/ModalContext.res] handles modal UI/Event routing
```

---

## 🔄 Backend Internal Flows

### Image Processing Pipeline
**Trigger:** Backend receives image upload

**Flow:**
```
[backend/src/api/media/image_multipart.rs] receives multipart upload
  → [backend/src/api/media/image_logic.rs] coordinates processing tasks
  → [backend/src/api/media/mod.rs], [backend/src/api/media/video_logic_support.rs], [backend/src/services/media/mod.rs] route requests
  → [backend/src/api/media/image_tasks.rs] background worker tasks
  → [backend/src/services/media/analysis_exif.rs] extracts metadata
  → [backend/src/services/media/resizing.rs] generates multi-resolution (512px, 4K)
  → [backend/src/services/media/analysis_quality.rs] histogram and blur analysis
  → [backend/src/services/media/webp.rs] encodes to WebP
  → [backend/src/services/media/storage.rs] persists to disk
  → Returns analysis results
```

### Pathfinder & Navigation (Backend)
**Trigger:** Client requests optimal path Between scenes

**Flow:**
```
[backend/src/api/project.rs] receives path request
  → [backend/src/pathfinder.rs] orchestrates search
      → [backend/src/pathfinder/graph.rs] loads scene relationship graph
      → [backend/src/pathfinder/algorithms.rs] executes A* or similar search
      → [backend/src/pathfinder/timeline.rs] (Optional) applies timeline constraints
      → [backend/src/pathfinder/utils.rs] and [backend/src/pathfinder/walk.rs] for traversal logic
  → Returns path sequence
```

### Project Lifecycle (Save/Load/Export)
**Trigger:** User performs project operations

**Flow:**
```
Save/Export Trigger:
  → [src/systems/ProjectManager.res] and [src/systems/ProjectManagerUrl.res] package project data
      → [src/systems/ProjectConnectivity.res] performs dead-end/connectivity checks before packaging/export completion
      → [src/systems/ProjectManager/ProjectSave.res] and [src/systems/ProjectManager/ProjectUtils.res] orchestrate the save sequence
      → [src/systems/Project/ProjectSaver.res] handles ZIP assembly and export packaging
  → [src/systems/Exporter.res] prepares local archive
      → [src/systems/Exporter/ExporterPackaging.res], [src/systems/Exporter/ExporterUpload.res], and [src/systems/Exporter/ExporterUtils.res] handle packaging assembly, upload transport, and export-specific helpers
      → Handles asset streaming, XHR upload, and branding application using [src/systems/TourTemplates.res] (assisted by [src/systems/TourTemplates/TourStyles.res], [src/systems/TourTemplates/TourData.res], [src/systems/TourTemplates/TourScripts.res], [src/systems/TourTemplates/TourScriptCore.res], [src/systems/TourTemplates/TourScriptNavigation.res], [src/systems/TourTemplates/TourScriptInput.res], [src/systems/TourTemplates/TourScriptHotspots.res], [src/systems/TourTemplates/TourScriptViewport.res], [src/systems/TourTemplates/TourScriptUI.res], [src/systems/TourTemplates/TourScriptUINav.res], [src/systems/TourTemplates/TourScriptUIMap.res], and [src/systems/TourTemplates/TourAssets.res])
  → [src/systems/DownloadSystem.res] triggers client-side saving
  → [src/systems/OperationLifecycle.res] tracks blocking/ambient operation progress for load/save/export UX
  → [backend/src/api/mod.rs] and [backend/src/api/project.rs] receive request
      → [backend/src/middleware/rate_limiter.rs] enforces route-class rate limits and structured 429 response payloads
  → [backend/src/api/project_logic.rs] and [backend/src/api/project_logic/mod.rs] coordinate project packaging/import helpers
      → [backend/src/api/project_logic/files.rs] discovers available image files
      → [backend/src/api/project_logic/reference.rs] resolves scene/inventory file references
      → [backend/src/api/project_logic/summary.rs] builds export summary artifacts
      → [backend/src/api/project_logic/validation.rs] performs synchronous validation + report generation
      → [backend/src/api/project_logic/zip.rs] handles zip extraction/creation and secure path handling
  → [backend/src/services/project/mod.rs] handles persistence
  → [backend/src/api/utils.rs] for request validation
  → [backend/src/services/mod.rs], [backend/src/services/project/package.rs], and [backend/src/services/project/package_utils.rs] create ZIP (Export only)

Load Trigger:
  → [src/utils/FileSlicer.res] slices project archive for chunked/resumable import uploads
  → [backend/src/services/project/import_upload.rs] manages init/chunk/status/complete/abort upload session lifecycle
      → [backend/src/services/project/import_upload_runtime.rs] executes session/chunk runtime operations
      → [backend/src/services/project/import_upload_logic.rs] provides validation and chunk accounting helpers
  → [backend/src/middleware/rate_limiter.rs] applies write-scope backpressure controls during import sequence
  → [backend/src/services/project/load.rs] fetches project data
  → [backend/src/services/project/validate.rs] performs deep structural validation
  → Returns metadata to client
  → [src/systems/ProjectSystem.res] validates project structure and processes loaded data
  → [src/systems/Project/ProjectLoader.res] patches and initializes project state
  → [src/systems/Project/ProjectValidator.res] validates integrity on the client side
  → [src/systems/Api/ProjectImportApi.res] sends atomic chunked import requests
  → [src/systems/Api/ProjectImportOrchestrator.res] orchestrates the multi-chunk import flow
  → [src/systems/Api/ProjectImportTypes.res] provides shared import payload types and decoders
  → [src/systems/Api/AuthenticatedClientBase.res] and [src/systems/Api/AuthenticatedClientRequest.res] build authenticated requests
  → [backend/src/api/project_import.rs] handles chunked resumable import endpoints
  → [backend/src/services/project/import_session.rs] manages session state and chunk assembly
  → [backend/src/services/project/validate_utils.rs] provides validation helpers for import
```

### Geocoding & Search
**Trigger:** User searches for location or system resolves GPS

**Flow:**
```
Address/GPS Query
  → [backend/src/api/geocoding.rs] handles request
  → [backend/src/services/geocoding/mod.rs] facade
      → [backend/src/services/geocoding/cache.rs] checks LRU cache
      → [backend/src/services/geocoding/osm.rs] queries OpenStreetMap Nominatim
  → Returns result with bounding box/coords
```

### Backend Media Test Coverage
**Trigger:** Backend test execution (`cargo test`)

**Flow:**
```
Test runner
  → [backend/src/api/media/video_tests.rs] validates video endpoint contract and request handling
  → [backend/src/api/media/video_logic_tests.rs] validates teaser runtime/transcode logic behavior
```

### Infrastructure, Metadata & Quota (Backend)
**Trigger:** Server startup or request middleware

**Flow:**
```
[backend/src/main.rs] entry point
  → [backend/src/startup.rs] initializes HTTP server
  → [backend/src/lib.rs] provides core application logic
  → [backend/src/middleware.rs], [backend/src/middleware/rate_limiter.rs], and [backend/src/auth.rs] handle CORS/Auth/rate limiting
  → [backend/src/services/database.rs] connection pool
  → [backend/src/services/upload_quota.rs] and [backend/src/services/upload_quota_tests.rs] enforce limits
  → [backend/src/api/health.rs] provides service diagnostics

### CI Budget Governance
**Trigger:** Pull request / CI execution

**Flow:**
```
CI job
  → [npm run build] produces dist artifacts
  → [scripts/check-bundle-budgets.mjs] validates bundle ceilings (raw/gzip/largest chunk)
  → [playwright.config.ts] routes @budget tests to chromium-budget project
  → [tests/e2e/perf-budgets.spec.ts] captures runtime metrics:
      - rapid navigation p95 latency
      - long task counts
      - memory growth ratios
      - bulk upload completion latency
      - long simulation stability
  → writes [artifacts/perf-budget-metrics.json]
  → [scripts/check-runtime-budgets.mjs] enforces runtime thresholds
  → [docs/_pending_integration/enterprise_reliability_performance_runbook.md] records threshold contract and before/after SLO evidence
  → CI fails on budget regression
```
  → [backend/src/services/shutdown.rs] graceful exit orchestration
  → [backend/src/metrics.rs] processes performance metrics
```

---

## 🛠️ Infrastructure & Hardware Bridges

### API Orchestration & Telemetry
**Purpose:** Managing network requests and stateful client communication.
- [src/systems/Api.res], [src/systems/ApiHelpers.res], [src/systems/ApiLogic.res], [src/systems/Api/AuthenticatedClient.res], [src/systems/Api/ProjectApi.res], [src/systems/BackendApi.res], [src/utils/UrlUtils.res], [backend/src/api/telemetry.rs]
- Frontend Logger: [src/utils/Logger.res], [src/utils/LoggerCommon.res], [src/utils/LoggerConsole.res], [src/utils/LoggerLogic.res], [src/utils/LoggerTelemetry.res]

### Logical Data Models & State
**Purpose:** Canonical definitions for core domain objects.
- Frontend: [src/core/SharedTypes.res], [src/core/State.res], [src/core/StateSnapshot.res], [src/core/OptimisticAction.res], [src/core/interfaces/ViewerDriver.res], [src/core/ReducerModules.res], [src/core/NavigationProjectReducer.res]
- Backend: [backend/src/models.rs], [backend/src/models_common.rs], [backend/src/models_identity.rs], [backend/src/models_project_session.rs]

### Components & UI Foundation (Common)
**Purpose:** Shared presentation components and style primitives.
- [src/components/PopOver.res], [src/components/Portal.res], [src/components/Tooltip.res], [src/components/SelectionOverlay.res], [src/components/FocusRing.res], [src/components/EmptyState.res], [src/components/LoadingSpinner.res], [src/components/VisualPipeline/VisualPipelineStyles.res], [src/components/VisualPipelineStyles.res], [src/components/VisualPipelineNode.res]

### External Bindings (Web APIs)
**Purpose:** Bridge ReScript to browser-native functionality.
- [src/bindings/BrowserBindings.res], [src/bindings/DomBindings.res], [src/bindings/GraphicsBindings.res], [src/bindings/ViewerBindings.res], [src/bindings/WebApiBindings.res], [src/ReBindings.res]

### Progressive Web App (PWA)
**Purpose:** Offline capabilities and asset pre-caching.
- [src/ServiceWorker.res] and [src/ServiceWorkerMain.res] (Entry point: [src/index.js])

### Concurrent Utility primitives
**Purpose:** Flow control and performance management.
- [src/utils/AsyncQueue.res], [src/utils/RequestQueue.res], [src/utils/CircuitBreaker.res], [src/utils/RateLimiter.res], [src/utils/Retry.res], [src/utils/Debounce.res], [src/utils/FileSlicer.res], [src/core/InteractionGuard.res], [src/core/Capability.res], [src/systems/OperationLifecycle.res], [src/systems/OperationLifecycleContext.res], [src/systems/OperationLifecycleTypes.res], [src/systems/Navigation/NavigationSupervisor.res] (navigation-specific concurrency)

### Interaction & Perception
- [src/systems/InputSystem.res], [src/systems/CursorPhysics.res], [src/systems/ViewerFollow.res], [src/utils/ProgressBar.res], [src/utils/ColorPalette.res], [src/utils/SessionStore.res], [src/utils/StateInspector.res], [src/systems/TourTemplates.res], [src/utils/Easing.res], [src/utils/PerfUtils.res], [src/utils/StateDensityMonitor.res]

### Geometric & Projection Math
**Purpose:** 3D viewport calculations and coordinate mapping.
- [src/utils/ProjectionMath.res], [src/utils/GeoUtils.res], [src/utils/PathInterpolation.res], [src/utils/Constants.res]

### Global Support & Metadata
- [src/utils/Version.res], [src/utils/TourLogic.res], [src/components/UtilityBar.res], [src/i18n/I18n.res], [src/utils/ImageOptimizer.res], [src/utils/LazyLoad.res]

---

### 📂 src/hooks
- `[src/hooks/UseInteraction.res]`

---
(Utilities and Infrastructure modules are excluded from flow documentation by design)

(Utilities and Infrastructure modules are excluded from flow documentation by design)

*(None currently - all detected modules have been integrated into flows.)*


---
(Utilities and Infrastructure modules are excluded from flow documentation by design)

*(None currently - all detected modules have been integrated into flows.)*

*(None currently - all detected modules have been integrated into flows.)*

## 🆕 Unmapped Modules
(This section auto-populated by _dev-system analyzer)

---
(Utilities and Infrastructure modules are excluded from flow documentation by design)
