# 🌊 Data Flow Documentation

This document maps critical data flows through the system to help AI understand architectural boundaries and module interactions.

---

## 🔗 User Interaction Flows

### Scene Navigation
**Trigger:** User clicks scene thumbnail or navigation hotspot

**Flow:**
```
User Click Event
  → [src/components/SceneList/SceneItem.res] or [src/components/HotspotLayer.res] handles click
  → [src/core/InteractionGuard.res] checks cooldowns using [src/core/InteractionPolicies.res]
  → [src/systems/Navigation/NavigationSupervisor.res] receives intent (auto-cancels previous task)
      → Creates AbortSignal for structured concurrency
      → dispatch(UserClickedScene) FSM event for UI reactivity
      → [src/components/LockFeedback.res] renders progress via NavigationSupervisor.addStatusListener()
  → [src/App.res] and [src/components/AppErrorBoundary.res] provide the top-level container
      → [src/components/ErrorFallbackUI.res] and [src/components/CriticalErrorMonitor.res] provide the crash UI and error monitoring
      → [src/Hooks.res] and [src/core/UiHelpers.res] manage top-level component lifecycle
  → [src/core/AppFSM.res] handles top-level state transition (e.g. Editing → Navigation)
  → [src/core/Reducer.res] processes FSM action using [src/core/Types.res], [src/core/ViewerState.res] and [src/core/ViewerTypes.res]
  → [src/systems/Navigation/NavigationFSM.res] state transition (IdleFsm → Preloading)
  → [src/systems/Navigation/NavigationController.res] subscribes to FSM changes
      → Calls SceneLoader with taskId and AbortSignal from Supervisor
  → [src/systems/Scene.res] and [src/systems/Scene/SceneLoader.res] coordinates viewer loading (with AbortSignal support)
      → [src/core/SceneCache.res] manages preloaded scene state
      → [src/components/ViewerManager.res], [src/components/ViewerManagerLogic.res], and [src/components/ViewerManager/ViewerManagerLifecycle.res] manage active viewers
      → [src/components/ViewerUI.res], [src/components/ViewerHUD.res], and [src/components/ViewerLoader.res] render interactive overlays
      → [src/systems/ViewerSystem.res], [src/systems/ViewerPool.res], and [src/systems/ViewerLogic.res] manage viewer instance lifecycle
      → [src/systems/PannellumAdapter.res] and [src/systems/PannellumLifecycle.res] interface with engine
  → [src/systems/Scene/SceneSwitcher.res] handles journey initialization and auto-forwarding
  → [src/systems/Scene/SceneTransition.res] performs CSS crossfade and viewport swapping (with Supervisor coordination)
  → [src/systems/Navigation/NavigationRenderer.res] updates interactive navigation markers (using [src/components/Tooltip.res], [src/components/PreviewArrow.res], and [src/components/PersistentLabel.res])
  → [src/systems/AudioManager.res] triggers spatial audio transitions
  → [src/systems/Navigation/NavigationSupervisor.res] completes task and marks status Idle
```

### Upload Pipeline
**Trigger:** User selects images for upload

**Flow:**
```
User file selection
  → [src/components/Sidebar.res] (using [src/components/Sidebar/SidebarActions.res], [src/components/Sidebar/SidebarBranding.res], [src/components/Sidebar/SidebarProcessing.res], [src/components/Sidebar/SidebarProjectInfo.res])
    → [src/components/Sidebar/SidebarSearch.res], [src/components/Sidebar/SidebarFilters.res], [src/components/Sidebar/SidebarBatchManagement.res], [src/components/Sidebar/SidebarSorting.res] for view orchestration
  → [src/components/Sidebar/SidebarLogic.res] and [src/components/SceneList.res] handle file input and display
  → [src/components/VisualPipeline/VisualPipelineComponent.res] (assisted by [src/components/VisualPipeline.res] and [src/components/VisualPipeline/VisualPipelineStyles.res]) shows progress (using [src/utils/ProgressBar.res])
  → [src/systems/UploadProcessor.res] orchestrates the pipeline
  → [src/systems/UploadProcessorLogic.res] manages batch state (using [src/systems/UploadTypes.res])
  → [src/systems/FingerprintService.res] calculates unique image hashes
  → [src/systems/ImageValidator.res] validates formats and dimensions
  → [src/systems/Resizer.res] performs client-side pre-processing
      → [src/systems/Resizer/ResizerLogic.res] and [src/systems/Resizer/ResizerUtils.res] manage resizing tasks with [src/systems/Resizer/ResizerTypes.res]
  → [src/utils/ImageOptimizer.res] applies final compression
  → [src/utils/OperationJournal.res] starts transaction (startOperation)
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
  → [src/core/Reducer.res] updates state using [src/core/SceneHelpers.res]
    → [src/components/QualityIndicator.res] updates based on results
  → [src/utils/OperationJournal.res] completes transaction
```

### State Persistence & Recovery
**Trigger:** App initialization or state change

**Flow:**
```
State changes
  → [src/core/GlobalStateBridge.res] notifies subscribers
  → [src/utils/PersistenceLayer.res] debounced save (2s)
  → [src/core/State.res] and [src/core/StateSnapshot.res] serialized by [src/core/JsonParsers.res], [src/core/JsonParsersEncoders.res], [src/core/JsonEncoders.res], and [src/core/JsonParsersShared.res]
  → IndexedDB storage [src/bindings/IdbBindings.res]

On startup ([src/Main.res]):
  → [src/components/RecoveryCheck.res], [src/components/RecoveryPrompt.res], and [src/components/ReturnPrompt.res] mount
  → [src/utils/RecoveryManager.res] checks for interrupted operations
  → [src/utils/OperationJournal.res] checks journal for active transactions
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
      → [src/systems/Teaser.res], [src/systems/TeaserLogic.res], and [src/systems/TeaserState.res] handle playback and movement logic
      → [src/systems/TeaserPathfinder.res] specialized cinematic pathfinding
  → [src/systems/TeaserRecorder.res] captures viewports (using [src/components/SnapshotOverlay.res], [src/components/ViewerSnapshot.res])
  → [src/systems/ServerTeaser.res] (Optional) requests backend high-quality render
      → [backend/src/api/media/video.rs] and [backend/src/api/media/video_logic.rs] for transcoding
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
  → [backend/src/api/media/mod.rs], [backend/src/services/media/mod.rs] route requests
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
  → [src/systems/Exporter.res] prepares local archive
  → [src/systems/DownloadSystem.res] triggers client-side saving
  → [backend/src/api/mod.rs] and [backend/src/api/project.rs] receive request
  → [backend/src/api/project_logic.rs] and [backend/src/services/project/mod.rs] handle persistence
  → [backend/src/api/utils.rs] for request validation
  → [backend/src/services/mod.rs] and [backend/src/services/project/package.rs] create ZIP (Export only)

Load Trigger:
  → [backend/src/services/project/load.rs] fetches project data
  → [backend/src/services/project/validate.rs] performs deep structural validation
  → Returns metadata to client
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

### Infrastructure, Metadata & Quota (Backend)
**Trigger:** Server startup or request middleware

**Flow:**
```
[backend/src/main.rs] entry point
  → [backend/src/startup.rs] initializes HTTP server
  → [backend/src/lib.rs] provides core application logic
  → [backend/src/middleware.rs] and [backend/src/auth.rs] handle CORS and Auth
  → [backend/src/services/database.rs] connection pool
  → [backend/src/services/upload_quota.rs] and [backend/src/services/upload_quota_tests.rs] enforce limits
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
- Frontend: [src/core/SharedTypes.res], [src/core/State.res], [src/core/StateSnapshot.res], [src/core/OptimisticAction.res], [src/core/interfaces/ViewerDriver.res]
- Backend: [backend/src/models.rs]

### Components & UI Foundation (Common)
**Purpose:** Shared presentation components and style primitives.
- [src/components/PopOver.res], [src/components/Portal.res], [src/components/Tooltip.res], [src/components/SelectionOverlay.res], [src/components/FocusRing.res], [src/components/EmptyState.res], [src/components/LoadingSpinner.res], [src/components/VisualPipeline/VisualPipelineStyles.res]

### External Bindings (Web APIs)
**Purpose:** Bridge ReScript to browser-native functionality.
- [src/bindings/BrowserBindings.res], [src/bindings/DomBindings.res], [src/bindings/GraphicsBindings.res], [src/bindings/ViewerBindings.res], [src/bindings/WebApiBindings.res], [src/ReBindings.res]

### Progressive Web App (PWA)
**Purpose:** Offline capabilities and asset pre-caching.
- [src/ServiceWorker.res] and [src/ServiceWorkerMain.res] (Entry point: [src/index.js])

### Concurrent Utility primitives
**Purpose:** Flow control and performance management.
- [src/utils/AsyncQueue.res], [src/utils/RequestQueue.res], [src/utils/CircuitBreaker.res], [src/utils/RateLimiter.res], [src/utils/Retry.res], [src/utils/Debounce.res], [src/core/InteractionGuard.res], [src/systems/Navigation/NavigationSupervisor.res] (navigation-specific concurrency)

### Interaction & Perception
- [src/systems/InputSystem.res], [src/systems/CursorPhysics.res], [src/systems/ViewerFollow.res], [src/utils/ProgressBar.res], [src/utils/ColorPalette.res], [src/utils/SessionStore.res], [src/utils/StateInspector.res], [src/systems/TourTemplates.res]

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

## 🆕 Unmapped Modules
(This section auto-populated by _dev-system analyzer)

### 📂 src/components
- `[src/components/FloorNavigation.res]`

### 📂 src/core
- `[src/core/Actions.res]`
- `[src/core/NavigationHelpers.res]`
- `[src/core/NavigationState.res]`
- `[src/core/TransitionLock.res]`

### 📂 src/systems
- `[src/systems/Navigation.res]`
- `[src/systems/NavigationLogic.res]`

### 📂 src/systems/Navigation
- `[src/systems/Navigation/NavigationGraph.res]`
- `[src/systems/Navigation/NavigationUI.res]`

---
(Utilities and Infrastructure modules are excluded from flow documentation by design)
