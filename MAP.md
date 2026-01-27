# 🗺️ Robust Virtual Tour Builder - Codebase Map

This map provides a semantic overview of the project structure to optimize context acquisition and pinpoint intent through tagging.

---

## 🏗️ Core Architecture

### 🚀 Entry & Foundational Bindings
*   [src/Main.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/Main.res): Entry point, global initialization, and React root mounting. `#entry-point` `#initialization`
*   [src/App.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/App.res): Root React component orchestrating the high-level UI layout. `#root-component` `#layout`
*   [src/ReBindings.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/ReBindings.res): Centralized external bindings for Browser APIs and third-party libraries. `#rescript` `#bindings` `#dom`
*   [src/utils/Logger.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/Logger.res): Mandatory logging utility for standardized debug output. `#logging` `#debug` `#vitals`

### 🛡️ State Management & Logic
*   [src/core/State.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/State.res): Central application state definition. `#state` `#immutability`
*   [src/core/Reducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/Reducer.res): Root reducer orchestrating domain updates. `#reducer` `#action-dispatch`
*   [src/core/Actions.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/Actions.res): All supported user and system actions. `#actions` `#events`
*   [src/core/AppContext.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/AppContext.res): Typed React Context for state and dispatch accessibility. `#react-context` `#hooks`
*   [src/core/SceneHelpers.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/SceneHelpers.res): Domain logic for scene parsing, synchronization, and manipulation. `#helpers` `#scene`
*   [src/core/UiHelpers.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/UiHelpers.res): Generic UI utilities, blob/file handling, and array manipulation. `#helpers` `#ui` `#utils`
*   [src/core/SimHelpers.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/SimHelpers.res): Simulation and timeline specific parsers and helpers. `#helpers` `#simulation`

### 🌐 System Layer (Business Logic)
*   [src/systems/UploadProcessor.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/UploadProcessor.res): Lightweight facade for the image processing pipeline. `#upload` `#facade`
*   [src/systems/UploadProcessorLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/UploadProcessorLogic.res): Core image validation, fingerprinting, and clustering logic. `#image-processing` `#logic`
*   [src/systems/SceneLoader.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SceneLoader.res): Orchestrates scene loading, progressive loading, and recovery. `#scene-loading` `#lifecycle`
*   [src/systems/SceneTransitionManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SceneTransitionManager.res): Manages DOM transitions and viewer swapping logic. `#transition` `#dom`
*   [src/systems/PannellumLifecycle.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/PannellumLifecycle.res): Lifecycle bindings for Pannellum viewer initialization and destruction. `#pannellum` `#bindings`
*   [src/systems/HotspotLine.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/HotspotLine.res): Facade for visual hotspot connections and simulation arrows. `#hotspots` `#rendering` `#facade`
*   [src/core/interfaces/ViewerDriver.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/interfaces/ViewerDriver.res): Interface contract for 360 renderer drivers. `#interface` `#abstraction`
*   [src/systems/PannellumAdapter.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/PannellumAdapter.res): Pannellum-specific implementation of ViewerDriver. `#adapter` `#rendering`
*   [src/systems/ViewerPool.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ViewerPool.res): Manager for multiple viewport instances and their lifecycles. `#orchestration` `#efficiency`
*   [src/systems/HotspotLineLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/HotspotLineLogic.res): Coordinate projection math and SVG drawing primitives. `#math` `#rendering` `#logic`
*   [src/systems/SimulationDriver.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SimulationDriver.res): Logic for Autopilot and route simulations. `#autopilot` `#simulation` `#navigation`
*   [src/systems/NavigationController.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationController.res): Manages movement between scenes. `#navigation` `#scene-switching`
*   [src/systems/NavigationFSM.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationFSM.res): Pure deterministic Finite State Machine for navigation lifecycle. `#orchestration` `#reliability`
*   [src/systems/NavigationGraph.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationGraph.res): Viewport math and link projection logic. `#math` `#navigation`
*   [src/systems/SceneSwitcher.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SceneSwitcher.res): Handles the state transitions and side effects of changing scenes. `#scene-switching` `#transition`
*   [src/systems/TeaserPlayback.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserPlayback.res): Orchestrates teaser and autopilot playback logic. `#teaser` `#playback`
*   [src/systems/TeaserState.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserState.res): State management for the teaser system. `#teaser` `#state`
*   [src/systems/TeaserManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserManager.res): Manager for teaser recording and playback sessions. `#teaser` `#manager`
*   [src/systems/ProjectManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ProjectManager.res): Handles ZIP-based loading and periodic auto-saving. `#persistence` `#save-load` `#zip`
*   [src/systems/Exporter.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/Exporter.res): Generates production-ready tour clusters. `#export` `#deployment`
*   [src/systems/api/ProjectApi.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/api/ProjectApi.res): Frontend API client for project operations. `#api` `#client`
*   [src/systems/api/MediaApi.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/api/MediaApi.res): Frontend API client for media operations. `#api` `#media`
*   [src/systems/FingerprintService.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/FingerprintService.res): Image fingerprinting for deduplication. `#image` `#fingerprint`
*   [src/systems/PanoramaClusterer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/PanoramaClusterer.res): Logic for grouping and clustering panoramas. `#logic` `#clustering`
*   [src/systems/SvgManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SvgManager.res): Management of SVG overlays and elements. `#svg` `#rendering`
*   [src/systems/VideoEncoder.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/VideoEncoder.res): Logic for encoding tour sequences into video. `#video` `#encoding`
*   [src/systems/DownloadSystem.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/DownloadSystem.res): Management of asset downloading and caching. `#download` `#cache`

### 🎨 Visual & UI Components
*   [src/components/ViewerUI.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerUI.res): High-level orchestrator for the viewer interface. `#ui` `#hud` `#orchestration`
*   [src/components/ViewerHUD.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerHUD.res): Primary overlay system (UtilityBar, FloorNav, Labels). `#ui` `#hud` `#overlays`
*   [src/components/SnapshotOverlay.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/SnapshotOverlay.res): Visual transition "flash" layer. `#ui` `#transition`
*   [src/components/NotificationLayer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/NotificationLayer.res): Centralized notification and processing status layer. `#ui` `#notifications`
*   [src/components/Sidebar.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Sidebar.res): Scene list, drag-and-drop organization, and project controls. `#sidebar` `#scene-management`
*   [src/components/HotspotManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/HotspotManager.res): Visual editor for placement and editing of nav links. `#hotspots` `#editor`
*   [src/components/AppErrorBoundary.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/AppErrorBoundary.res): Top-level safety net for render failures. `#error-handling` `#stability`
*   [src/components/FloorNavigation.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/FloorNavigation.res): UI for navigating between floors/levels. `#ui` `#navigation`
*   [src/components/UtilityBar.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/UtilityBar.res): Toolbar for common actions and tools. `#ui` `#toolbar`
*   [src/components/VisualPipeline.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/VisualPipeline.res): Visual processing pipeline components. `#ui` `#visuals`

### ⚙️ Utilities & Infrastructure
*   [src/utils/VersionData.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/VersionData.res): Versioning and build metadata. `#utils` `#version`
*   [src/utils/SessionStore.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/SessionStore.res): Session-based storage and state persistence. `#utils` `#storage`
*   [src/utils/RequestQueue.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/RequestQueue.res): Queue management for network requests. `#utils` `#network`
*   [src/utils/LazyLoad.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/LazyLoad.res): Helpers for lazy loading components and assets. `#utils` `#performance`
*   [src/utils/ProjectionMath.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/ProjectionMath.res): Mathematical utilities for 3D/2D projection. `#utils` `#math`

### ⚙️ Backend API (Rust)
*   [backend/src/main.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/main.rs): Server entry point, middleware setup, and routing. `#rust` `#api` `#server`
*   [backend/src/api/auth.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/auth.rs): Google OAuth2 authentication endpoints. `#rust` `#auth` `#google-oauth`
*   [backend/src/api/project.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project.rs): Endpoints for project packaging, imports, and validation. `#backend-logic` `#project-api`
*   [backend/src/api/media/image.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/image.rs): High-performance image processing logic. `#rust` `#image-processing` `#performance`
*   [backend/src/pathfinder/algorithms.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/pathfinder/algorithms.rs): Graph traversal logic for optimal routes. `#algorithms` `#graph-theory`

---

## 📁 Directory Semantic Index

| Directory | Primary Purpose | Key Tags |
| :--- | :--- | :--- |
| `src/` | Root components and foundational bindings. | `#entry` `#bindings` `#app` |
| `src/core` | Data model, state, and foundational types. | `#state` `#types` `#json` |
| `src/systems` | Complex business logic and background services. | `#logic` `#processing` `#simulation` |
| `src/components` | UI building blocks and contextual modules. | `#ui` `#react` `#hud` |
| `src/utils` | Shared helper functions and utility modules. | `#utils` `#helpers` `#logging` |
| `backend/src` | High-performance Rust services and APIs. | `#rust` `#backend` `#concurrency` |
| `css` | Design system, tokens, and animations. | `#styling` `#tailwind` `#tokens` |
| `scripts` | Automation, setup, commit protocols, and maintenance tools. | `#automation` `#scripts` `#ci` `#commit` |
| `docs/` | Technical specifications and project history. | `#documentation` `#specs` `#history` |
| `tmp/` | Temporary files and non-integrated documents. | `#temp` `#scratchpad` |

## 🆕 Unmapped Modules
* [src/ServiceWorker.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/ServiceWorker.res): New module detected. Please classify. #new
* [src/ServiceWorkerMain.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/ServiceWorkerMain.res): New module detected. Please classify. #new
* [src/components/ErrorFallbackUI.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ErrorFallbackUI.res): New module detected. Please classify. #new
* [src/components/HotspotActionMenu.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/HotspotActionMenu.res): New module detected. Please classify. #new
* [src/components/HotspotLayer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/HotspotLayer.res): New module detected. Please classify. #new
* [src/components/HotspotMenuLayer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/HotspotMenuLayer.res): New module detected. Please classify. #new
* [src/components/LabelMenu.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/LabelMenu.res): New module detected. Please classify. #new
* [src/components/LinkModal.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/LinkModal.res): New module detected. Please classify. #new
* [src/components/ModalContext.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ModalContext.res): New module detected. Please classify. #new
* [src/components/NotificationContext.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/NotificationContext.res): New module detected. Please classify. #new
* [src/components/PersistentLabel.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/PersistentLabel.res): New module detected. Please classify. #new
* [src/components/PopOver.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/PopOver.res): New module detected. Please classify. #new
* [src/components/Portal.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Portal.res): New module detected. Please classify. #new
* [src/components/PreviewArrow.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/PreviewArrow.res): New module detected. Please classify. #new
* [src/components/QualityIndicator.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/QualityIndicator.res): New module detected. Please classify. #new
* [src/components/ReturnPrompt.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ReturnPrompt.res): New module detected. Please classify. #new
* [src/components/SceneList.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/SceneList.res): New module detected. Please classify. #new
* [src/components/Tooltip.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Tooltip.res): New module detected. Please classify. #new
* [src/components/UploadReport.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/UploadReport.res): New module detected. Please classify. #new
* [src/components/ViewerLabelMenu.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerLabelMenu.res): New module detected. Please classify. #new
* [src/components/ViewerLoader.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerLoader.res): New module detected. Please classify. #new
* [src/components/ViewerManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerManager.res): New module detected. Please classify. #new
* [src/components/ViewerSnapshot.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerSnapshot.res): New module detected. Please classify. #new
* [src/components/ui/LucideIcons.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/LucideIcons.res): New module detected. Please classify. #new
* [src/components/ui/Shadcn.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/Shadcn.res): New module detected. Please classify. #new
* [src/core/GlobalStateBridge.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/GlobalStateBridge.res): New module detected. Please classify. #new
* [src/core/JsonTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/JsonTypes.res): New module detected. Please classify. #new
* [src/core/SceneCache.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/SceneCache.res): New module detected. Please classify. #new
* [src/core/SharedTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/SharedTypes.res): New module detected. Please classify. #new
* [src/core/Types.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/Types.res): New module detected. Please classify. #new
* [src/core/ViewerState.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/ViewerState.res): New module detected. Please classify. #new
* [src/core/ViewerTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/ViewerTypes.res): New module detected. Please classify. #new
* [src/core/reducers/HotspotReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/HotspotReducer.res): New module detected. Please classify. #new
* [src/core/reducers/NavigationReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/NavigationReducer.res): New module detected. Please classify. #new
* [src/core/reducers/ProjectReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/ProjectReducer.res): New module detected. Please classify. #new
* [src/core/reducers/RootReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/RootReducer.res): New module detected. Please classify. #new
* [src/core/reducers/SceneReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/SceneReducer.res): New module detected. Please classify. #new
* [src/core/reducers/SimulationReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/SimulationReducer.res): New module detected. Please classify. #new
* [src/core/reducers/TimelineReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/TimelineReducer.res): New module detected. Please classify. #new
* [src/core/reducers/UiReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/UiReducer.res): New module detected. Please classify. #new
* [src/core/reducers/mod.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/mod.res): New module detected. Please classify. #new
* [src/systems/AudioManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/AudioManager.res): New module detected. Please classify. #new
* [src/systems/BackendApi.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/BackendApi.res): New module detected. Please classify. #new
* [src/systems/CursorPhysics.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/CursorPhysics.res): New module detected. Please classify. #new
* [src/systems/EventBus.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/EventBus.res): New module detected. Please classify. #new
* [src/systems/ExifParser.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ExifParser.res): New module detected. Please classify. #new
* [src/systems/ExifReportGenerator.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ExifReportGenerator.res): New module detected. Please classify. #new
* [src/systems/HotspotLineTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/HotspotLineTypes.res): New module detected. Please classify. #new
* [src/systems/ImageValidator.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ImageValidator.res): New module detected. Please classify. #new
* [src/systems/InputSystem.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/InputSystem.res): New module detected. Please classify. #new
* [src/systems/LinkEditorLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/LinkEditorLogic.res): New module detected. Please classify. #new
* [src/systems/NavigationRenderer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationRenderer.res): New module detected. Please classify. #new
* [src/systems/NavigationUI.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationUI.res): New module detected. Please classify. #new
* [src/systems/ProjectData.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ProjectData.res): New module detected. Please classify. #new
* [src/systems/Resizer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/Resizer.res): New module detected. Please classify. #new
* [src/systems/ServerTeaser.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ServerTeaser.res): New module detected. Please classify. #new
* [src/systems/SimulationChainSkipper.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SimulationChainSkipper.res): New module detected. Please classify. #new
* [src/systems/SimulationLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SimulationLogic.res): New module detected. Please classify. #new
* [src/systems/SimulationNavigation.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SimulationNavigation.res): New module detected. Please classify. #new
* [src/systems/SimulationPathGenerator.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SimulationPathGenerator.res): New module detected. Please classify. #new
* [src/systems/SvgRenderer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SvgRenderer.res): New module detected. Please classify. #new
* [src/systems/TeaserPathfinder.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserPathfinder.res): New module detected. Please classify. #new
* [src/systems/TeaserRecorder.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserRecorder.res): New module detected. Please classify. #new
* [src/systems/TourTemplateAssets.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TourTemplateAssets.res): New module detected. Please classify. #new
* [src/systems/TourTemplateScripts.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TourTemplateScripts.res): New module detected. Please classify. #new
* [src/systems/TourTemplateStyles.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TourTemplateStyles.res): New module detected. Please classify. #new
* [src/systems/TourTemplates.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TourTemplates.res): New module detected. Please classify. #new
* [src/systems/UploadProcessorTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/UploadProcessorTypes.res): New module detected. Please classify. #new
* [src/systems/ViewerFollow.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ViewerFollow.res): New module detected. Please classify. #new
* [src/systems/api/ApiTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/api/ApiTypes.res): New module detected. Please classify. #new
* [src/utils/ColorPalette.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/ColorPalette.res): New module detected. Please classify. #new
* [src/utils/Constants.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/Constants.res): New module detected. Please classify. #new
* [src/utils/GeoUtils.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/GeoUtils.res): New module detected. Please classify. #new
* [src/utils/ImageOptimizer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/ImageOptimizer.res): New module detected. Please classify. #new
* [src/utils/PathInterpolation.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/PathInterpolation.res): New module detected. Please classify. #new
* [src/utils/ProgressBar.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/ProgressBar.res): New module detected. Please classify. #new
* [src/utils/StateInspector.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/StateInspector.res): New module detected. Please classify. #new
* [src/utils/TourLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/TourLogic.res): New module detected. Please classify. #new
* [src/utils/UrlUtils.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/UrlUtils.res): New module detected. Please classify. #new
* [src/utils/Version.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/Version.res): New module detected. Please classify. #new
* [backend/src/api/geocoding.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/geocoding.rs): New module detected. Please classify. #new
* [backend/src/api/media/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/mod.rs): New module detected. Please classify. #new
* [backend/src/api/media/serve.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/serve.rs): New module detected. Please classify. #new
* [backend/src/api/media/similarity.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/similarity.rs): New module detected. Please classify. #new
* [backend/src/api/media/video.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/video.rs): New module detected. Please classify. #new
* [backend/src/api/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/mod.rs): New module detected. Please classify. #new
* [backend/src/api/project/export.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project/export.rs): New module detected. Please classify. #new
* [backend/src/api/project/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project/mod.rs): New module detected. Please classify. #new
* [backend/src/api/project/navigation.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project/navigation.rs): New module detected. Please classify. #new
* [backend/src/api/project/storage.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project/storage.rs): New module detected. Please classify. #new
* [backend/src/api/project/validation.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project/validation.rs): New module detected. Please classify. #new
* [backend/src/api/telemetry.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/telemetry.rs): New module detected. Please classify. #new
* [backend/src/api/utils.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/utils.rs): New module detected. Please classify. #new
* [backend/src/lib.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/lib.rs): New module detected. Please classify. #new
* [backend/src/metrics.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/metrics.rs): New module detected. Please classify. #new
* [backend/src/middleware/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/middleware/mod.rs): New module detected. Please classify. #new
* [backend/src/middleware/quota_check.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/middleware/quota_check.rs): New module detected. Please classify. #new
* [backend/src/middleware/request_tracker.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/middleware/request_tracker.rs): New module detected. Please classify. #new
* [backend/src/models/errors.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/models/errors.rs): New module detected. Please classify. #new
* [backend/src/models/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/models/mod.rs): New module detected. Please classify. #new
* [backend/src/models/project.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/models/project.rs): New module detected. Please classify. #new
* [backend/src/models/user.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/models/user.rs): New module detected. Please classify. #new
* [backend/src/pathfinder/graph.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/pathfinder/graph.rs): New module detected. Please classify. #new
* [backend/src/pathfinder/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/pathfinder/mod.rs): New module detected. Please classify. #new
* [backend/src/pathfinder/utils.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/pathfinder/utils.rs): New module detected. Please classify. #new
* [backend/src/services/auth.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/auth.rs): New module detected. Please classify. #new
* [backend/src/services/database.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/database.rs): New module detected. Please classify. #new
* [backend/src/services/geocoding.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/geocoding.rs): New module detected. Please classify. #new
* [backend/src/services/media.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/media.rs): New module detected. Please classify. #new
* [backend/src/services/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/mod.rs): New module detected. Please classify. #new
* [backend/src/services/project/load.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/project/load.rs): New module detected. Please classify. #new
* [backend/src/services/project/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/project/mod.rs): New module detected. Please classify. #new
* [backend/src/services/project/package.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/project/package.rs): New module detected. Please classify. #new
* [backend/src/services/project/validate.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/project/validate.rs): New module detected. Please classify. #new
* [backend/src/services/shutdown.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/shutdown.rs): New module detected. Please classify. #new
* [backend/src/services/upload_quota.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/upload_quota.rs): New module detected. Please classify. #new
* [backend/src/services/upload_quota_tests.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/upload_quota_tests.rs): New module detected. Please classify. #new
