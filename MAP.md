# 🗺️ Robust Virtual Tour Builder - Codebase Map

This map provides a semantic overview of the project structure to optimize context acquisition and pinpoint intent through tagging.

---

## 🏗️ Core Architecture

### 🚀 Entry & Foundational Bindings
*   [src/Main.res](src/Main.res): Entry point, global initialization, and React root mounting. `#entry-point` `#initialization`
*   [src/ServiceWorker.res](src/ServiceWorker.res): Offline capabilities and asset caching. `#pwa` `#service-worker`
*   [src/ServiceWorkerMain.res](src/ServiceWorkerMain.res): Main thread logic for service worker coordination. `#pwa` `#orchestration`
*   [src/App.res](src/App.res): Root React component orchestrating the high-level UI layout. `#root-component` `#layout`
*   [src/index.js](src/index.js): React entry point. `#entry` `#react`
*   [src/ReBindings.res](src/ReBindings.res): Lightweight facade for centralized external bindings. `#rescript` `#bindings` `#facade`
    *   [src/bindings/BrowserBindings.res](src/bindings/BrowserBindings.res): Core browser types (Blob, File), JSZip, and AbortController. `#browser` `#types`
    *   [src/bindings/DomBindings.res](src/bindings/DomBindings.res): DOM, Window, and React-specific bindings. `#dom` `#react` `#window`
    *   [src/bindings/WebApiBindings.res](src/bindings/WebApiBindings.res): Fetch, URL, and FormData APIs. `#api` `#fetch` `#network`
    *   [src/bindings/GraphicsBindings.res](src/bindings/GraphicsBindings.res): Canvas 2D and SVG rendering bindings. `#graphics` `#canvas` `#svg`
    *   [src/bindings/ViewerBindings.res](src/bindings/ViewerBindings.res): Pannellum and 360 viewer-specific bindings. `#viewer` `#pannellum`
    *   [src/bindings/IdbBindings.res](src/bindings/IdbBindings.res): IndexedDB bindings for persistent client-side storage. `#browser` `#indexeddb` `#bindings`
* [src/utils/Logger.res](src/utils/Logger.res): Lightweight facade for the unified logging and telemetry system. `#logging` `#telemetry` `#facade`
    * [src/utils/LoggerLogic.res](src/utils/LoggerLogic.res): Core logging logic, console output, and performance tracking. `#logic`
    * [src/utils/LoggerTelemetry.res](src/utils/LoggerTelemetry.res): Async telemetry batching and backend synchronization. `#telemetry`
    * [src/utils/LoggerTypes.res](src/utils/LoggerTypes.res): Shared types, levels, and error helpers for the logger. `#types`

### 🛡️ State Management & Logic
*   [src/core/State.res](src/core/State.res): Central application state definition. `#state` `#immutability`
*   [src/core/Reducer.res](src/core/Reducer.res): Root reducer orchestrating domain updates. `#reducer` `#action-dispatch`
*   [src/core/Actions.res](src/core/Actions.res): All supported user and system actions. `#actions` `#events`
*   [src/core/Types.res](src/core/Types.res): Global domain types and application-wide interfaces. `#types`
*   [src/core/SharedTypes.res](src/core/SharedTypes.res): Utility types shared across frontend and backend logic. `#types`
*   [src/core/JsonTypes.res](src/core/JsonTypes.res): Strictly-typed JSON structures for project persistence. `#json` `#types`
*   [src/core/ViewerTypes.res](src/core/ViewerTypes.res): Types specialized for 360 viewer state and configuration. `#viewer` `#types`
*   [src/core/ViewerState.res](src/core/ViewerState.res): Localized state for the active viewer instance. `#state` `#viewer`
*   [src/core/AuthContext.res](src/core/AuthContext.res): React Context for authentication and session state. `#auth` `#react-context`
*   [src/core/SceneCache.res](src/core/SceneCache.res): In-memory cache for processed scene assets and metadata. `#cache` `#performance`
*   [src/core/GlobalStateBridge.res](src/core/GlobalStateBridge.res): Bridge for synchronizing state across different contexts. `#state` `#sync`
*   [src/i18n/I18n.res](src/i18n/I18n.res): Internationalization orchestrator for multi-language support. `#i18n` `#ui`
*   [src/core/reducers/mod.res](src/core/reducers/mod.res): Directory entry for the domain-specific reducers. `#reducer`
    *   [src/core/reducers/RootReducer.res](src/core/reducers/RootReducer.res): Combinator for all sub-reducers into a single state tree. `#reducer` `#composition`
    *   [src/core/reducers/ProjectReducer.res](src/core/reducers/ProjectReducer.res): Reducer for project-level state (metadata, settings). `#reducer`
    *   [src/core/reducers/SceneReducer.res](src/core/reducers/SceneReducer.res): Reducer for scene collection and image management. `#reducer` `#scene`
    *   [src/core/reducers/HotspotReducer.res](src/core/reducers/HotspotReducer.res): Reducer for interactive hotspots and their actions. `#reducer` `#hotspots`
    *   [src/core/reducers/NavigationReducer.res](src/core/reducers/NavigationReducer.res): Reducer for active navigation state and history. `#reducer` `#navigation`
    *   [src/core/reducers/SimulationReducer.res](src/core/reducers/SimulationReducer.res): Reducer for autopilot and simulation parameters. `#reducer` `#simulation`
    *   [src/core/reducers/TimelineReducer.res](src/core/reducers/TimelineReducer.res): Reducer for the visual timeline and event sequencing. `#reducer` `#timeline`
    *   [src/core/reducers/UiReducer.res](src/core/reducers/UiReducer.res): Reducer for non-persistent UI state (modals, tooltips). `#reducer` `#ui`
*   [src/core/AppContext.res](src/core/AppContext.res): Typed React Context for state and dispatch accessibility. `#react-context` `#hooks`
*   [src/core/Schemas.res](src/core/Schemas.res): Lightweight facade for data validation and parsing. `#json` `#validation` `#facade`
    *   [src/core/SchemasShared.res](src/core/SchemasShared.res): Shared validation schemas for backend communication. `#json` `#types`
    *   [src/core/SchemasDomain.res](src/core/SchemasDomain.res): Domain-specific validation schemas for tour state. `#json` `#types`
*   [src/core/SceneHelpers.res](src/core/SceneHelpers.res): Lightweight facade for scene-related helpers. `#helpers` `#scene` `#facade`
    *   [src/core/SceneHelpersParser.res](src/core/SceneHelpersParser.res): Parsing logic for hotspots, scenes, and projects. `#parsing`
    *   [src/core/SceneHelpersLogic.res](src/core/SceneHelpersLogic.res): Complex action handlers for scene management. `#logic`
*   [src/core/UiHelpers.res](src/core/UiHelpers.res): Generic UI utilities, blob/file handling, and array manipulation. `#helpers` `#ui` `#utils`
*   [src/core/SimHelpers.res](src/core/SimHelpers.res): Simulation and timeline specific parsers and helpers. `#helpers` `#simulation`

### 🌐 System Layer (Business Logic)
*   [src/systems/UploadProcessor.res](src/systems/UploadProcessor.res): Lightweight facade for the image processing pipeline. `#upload` `#facade`
*   [src/systems/UploadProcessorLogic.res](src/systems/UploadProcessorLogic.res): Lightweight facade for the image processing and upload queue logic. `#upload` `#facade`
    *   [src/systems/UploadProcessorLogicLogic.res](src/systems/UploadProcessorLogicLogic.res): Core logic for image processing, queue management, and upload finalization. `#logic`
*   [src/systems/UploadTypes.res](src/systems/UploadTypes.res): Types for upload processing system. `#types`
* [src/systems/SceneLoader.res](src/systems/SceneLoader.res): Lightweight facade for scene transition and viewer loading orchestration. `#scene-loading` `#lifecycle` `#facade`
    * [src/systems/SceneLoaderLogic.res](src/systems/SceneLoaderLogic.res): Lightweight facade for scene loading orchestration. `#logic` `#facade`
    * [src/systems/SceneLoaderLogicReuse.res](src/systems/SceneLoaderLogicReuse.res): Logic for viewer reuse and session persistence. `#logic`
    * [src/systems/SceneLoaderLogicConfig.res](src/systems/SceneLoaderLogicConfig.res): Pannellum configuration and URL generation. `#logic` `#config`
    * [src/systems/SceneLoaderLogicEvents.res](src/systems/SceneLoaderLogicEvents.res): Handler for viewer load events and hotspot injection. `#logic` `#events`
    * [src/systems/SceneLoaderTypes.res](src/systems/SceneLoaderTypes.res): Shared types and performance tracking for scene loading. `#types`
*   [src/systems/Scene.res](src/systems/Scene.res): Core scene management logic. `#scene` `#management`
*   [src/systems/SceneTransitionManager.res](src/systems/SceneTransitionManager.res): Manages DOM transitions and viewer swapping logic. `#transition` `#dom`
*   [src/systems/PannellumLifecycle.res](src/systems/PannellumLifecycle.res): Lifecycle bindings for Pannellum viewer initialization and destruction. `#pannellum` `#bindings`
*   [src/systems/HotspotLine.res](src/systems/HotspotLine.res): Facade for visual hotspot connections and simulation arrows. `#hotspots` `#rendering` `#facade`
*   [src/core/interfaces/ViewerDriver.res](src/core/interfaces/ViewerDriver.res): Interface contract for 360 renderer drivers. `#interface` `#abstraction`
*   [src/systems/PannellumAdapter.res](src/systems/PannellumAdapter.res): Pannellum-specific implementation of ViewerDriver. `#adapter` `#rendering`
*   [src/systems/ViewerSystem.res](src/systems/ViewerSystem.res): Unified viewer system orchestrator. `#viewer` `#orchestration`
*   [src/systems/ViewerLogic.res](src/systems/ViewerLogic.res): Core logic for viewer interactions and state. `#viewer` `#logic`
*   [src/systems/ViewerPool.res](src/systems/ViewerPool.res): Manager for multiple viewport instances and their lifecycles. `#orchestration` `#efficiency`
*   [src/systems/HotspotLineLogic.res](src/systems/HotspotLineLogic.res): Lightweight facade for coordinate projection and SVG drawing. `#math` `#rendering` `#facade`
    *   [src/systems/HotspotLineLogicLogic.res](src/systems/HotspotLineLogicLogic.res): Main logic for persistent lines and linking drafts. `#logic`
    *   [src/systems/HotspotLineLogicArrow.res](src/systems/HotspotLineLogicArrow.res): Specialized logic for simulation arrow rendering and animation. `#logic` `#animation`
    *   [src/systems/HotspotLineLogicTypes.res](src/systems/HotspotLineLogicTypes.res): Internal types for hotspot line logic and caching. `#types`
    *   [src/systems/HotspotLineUtils.res](src/systems/HotspotLineUtils.res): State and caching for hotspot line rendering. `#utils` `#caching`
*   [src/systems/Simulation.res](src/systems/Simulation.res): Core logic for autopilot simulations. `#simulation` `#autopilot`
*   [src/systems/SimulationDriver.res](src/systems/SimulationDriver.res): Logic for Autopilot and route simulations. `#autopilot` `#simulation` `#navigation`
*   [src/systems/Navigation.res](src/systems/Navigation.res): Centralized navigation system. `#navigation` `#orchestration`
*   [src/systems/NavigationLogic.res](src/systems/NavigationLogic.res): Core logic for navigation state transitions. `#navigation` `#logic`
*   [src/systems/NavigationController.res](src/systems/NavigationController.res): Manages movement between scenes. `#navigation` `#scene-switching`
*   [src/systems/NavigationFSM.res](src/systems/NavigationFSM.res): Pure deterministic Finite State Machine for navigation lifecycle. `#orchestration` `#reliability`
*   [src/systems/NavigationGraph.res](src/systems/NavigationGraph.res): Viewport math and link projection logic. `#math` `#navigation`
*   [src/systems/SceneSwitcher.res](src/systems/SceneSwitcher.res): Handles the state transitions and side effects of changing scenes. `#scene-switching` `#transition`
*   [src/systems/Teaser.res](src/systems/Teaser.res): Teaser generation system. `#teaser` `#video`
*   [src/systems/TeaserLogic.res](src/systems/TeaserLogic.res): Core playback, recording orchestration, and cinematic movement logic for teasers. `#teaser` `#playback` `#logic`
*   [src/systems/TeaserPlayback.res](src/systems/TeaserPlayback.res): Orchestrates teaser and autopilot playback logic. `#teaser` `#playback`
*   [src/systems/TeaserState.res](src/systems/TeaserState.res): State management for the teaser system. `#teaser` `#state`
*   [src/systems/TeaserManager.res](src/systems/TeaserManager.res): Manager for teaser recording and playback sessions. `#teaser` `#manager`
*   [src/systems/ProjectManager.res](src/systems/ProjectManager.res): Lightweight facade for project save/load operations. `#persistence` `#save-load` `#facade`
    * [src/systems/ProjectManagerLogic.res](src/systems/ProjectManagerLogic.res): Core logic for project packaging and resolution. `#logic`
    * [src/systems/ProjectManagerTypes.res](src/systems/ProjectManagerTypes.res): Shared types for project management. `#types`
*   [src/systems/Exporter.res](src/systems/Exporter.res): Generates production-ready tour clusters. `#export` `#deployment`
*   [src/systems/Api.res](src/systems/Api.res): Consolidated API module for media, projects, and authentication. `#api` `#client` `#consolidated`
    *   [src/systems/Api/AuthenticatedClient.res](src/systems/Api/AuthenticatedClient.res): Fetch wrapper with token injection and error handling. `#api` `#auth` `#client` `#adapter`
    *   [src/systems/Api/ApiTypes.res](src/systems/Api/ApiTypes.res): Type definitions and JSON decoders for API responses. `#api` `#types` `#json` `#schema`
    *   [src/systems/Api/MediaApi.res](src/systems/Api/MediaApi.res): Logic for media-related API operations (metadata, processing, similarity). `#api` `#media` `#logic` `#client`
*   [src/systems/ApiLogic.res](src/systems/ApiLogic.res): Implementation of API client logic, including decoders and authenticated requests. `#api` `#client` `#logic`
*   [src/systems/FingerprintService.res](src/systems/FingerprintService.res): Image fingerprinting for deduplication. `#image` `#fingerprint`
*   [src/systems/PanoramaClusterer.res](src/systems/PanoramaClusterer.res): Logic for grouping and clustering panoramas. `#logic` `#clustering`
*   [src/systems/SvgManager.res](src/systems/SvgManager.res): Management of SVG overlays and elements. `#svg` `#rendering`
*   [src/systems/VideoEncoder.res](src/systems/VideoEncoder.res): Logic for encoding tour sequences into video. `#video` `#encoding`
*   [src/systems/Resizer.res](src/systems/Resizer.res): Lightweight facade for client-side image resizing. `#processing` `#image` `#facade`
    *   [src/systems/ResizerLogic.res](src/systems/ResizerLogic.res): Core canvas-based resizing and blob generation logic. `#logic`
    *   [src/systems/ResizerTypes.res](src/systems/ResizerTypes.res): Internal types for the resizing pipeline. `#types`
    *   [src/systems/ResizerUtils.res](src/systems/ResizerUtils.res): Shared utilities for image dimension calculations. `#utils`
*   [src/systems/TeaserRecorder.res](src/systems/TeaserRecorder.res): Lightweight facade for capturing and recording tour teasers. `#teaser` `#recording` `#facade`
    *   [src/systems/TeaserRecorderLogic.res](src/systems/TeaserRecorderLogic.res): Core recording orchestration and frame capture logic. `#logic`
    *   [src/systems/TeaserRecorderOverlay.res](src/systems/TeaserRecorderOverlay.res): Visual status indicators during recording sessions. `#ui`
    *   [src/systems/TeaserRecorderTypes.res](src/systems/TeaserRecorderTypes.res): Types for teaser recording state and configuration. `#types`
*   [src/systems/DownloadSystem.res](src/systems/DownloadSystem.res): Management of asset downloading and caching. `#download` `#cache`
*   [src/systems/AudioManager.res](src/systems/AudioManager.res): Orchestrator for spatial audio and background soundscapes. `#audio` `#spatial-sound`
*   [src/systems/EventBus.res](src/systems/EventBus.res): Centralized pub/sub broker for decoupled system communication. `#events` `#orchestration`
*   [src/systems/InputSystem.res](src/systems/InputSystem.res): Unified handler for mouse, touch, and keyboard input. `#input` `#gestures`
*   [src/systems/CursorPhysics.res](src/systems/CursorPhysics.res): Physics-based cursor and interaction smoothing. `#physics` `#ux`
*   [src/systems/ExifParser.res](src/systems/ExifParser.res): Frontend-side EXIF data parsing and normalization. `#exif` `#parsing`
*   [src/systems/ExifReportGenerator.res](src/systems/ExifReportGenerator.res): Lightweight facade for EXIF report generation and downloading. `#exif` `#reporting` `#facade`
    *   [src/systems/ExifReportGeneratorLogic.res](src/systems/ExifReportGeneratorLogic.res): Main report generation orchestrator. `#logic`
    *   [src/systems/ExifReportGeneratorLogicExtraction.res](src/systems/ExifReportGeneratorLogicExtraction.res): EXIF data extraction from file batches. `#logic` `#extraction`
    *   [src/systems/ExifReportGeneratorLogicLocation.res](src/systems/ExifReportGeneratorLogicLocation.res): GPS analysis, centroid calculation, and geocoding. `#logic` `#geo`
    *   [src/systems/ExifReportGeneratorLogicGroups.res](src/systems/ExifReportGeneratorLogicGroups.res): Camera device grouping and file listing logic. `#logic`
    *   [src/systems/ExifReportGeneratorLogicTypes.res](src/systems/ExifReportGeneratorLogicTypes.res): Internal types for EXIF report analysis. `#types`
    *   [src/systems/ExifReportGeneratorTypes.res](src/systems/ExifReportGeneratorTypes.res): Shared types for EXIF reporting. `#types`
    *   [src/systems/ExifReportGeneratorUtils.res](src/systems/ExifReportGeneratorUtils.res): Project name generation and report downloading utilities. `#utils`
*   [src/systems/ImageValidator.res](src/systems/ImageValidator.res): Client-side validation of image formats and dimensions. `#image` `#validation`
*   [src/systems/NavigationUI.res](src/systems/NavigationUI.res): UI-driven navigation logic and breadcrumb management. `#navigation` `#ui`
*   [src/systems/NavigationRenderer.res](src/systems/NavigationRenderer.res): Specialized renderer for interactive navigation elements. `#rendering` `#navigation`
*   [src/systems/LinkEditorLogic.res](src/systems/LinkEditorLogic.res): Core logic for the visual link and hotspot editor. `#editor` `#logic`
*   [src/systems/ProjectData.res](src/systems/ProjectData.res): Domain logic for project structure manipulation and serialization. `#project` `#logic`
*   [src/systems/SimulationLogic.res](src/systems/SimulationLogic.res): Advanced logic for waypoint-based movement simulations. `#simulation` `#logic`
*   [src/systems/SimulationNavigation.res](src/systems/SimulationNavigation.res): Navigation specialized for automated autopilot routes. `#simulation` `#navigation`
*   [src/systems/SimulationPathGenerator.res](src/systems/SimulationPathGenerator.res): Algorithm for generating optimal paths between scenes. `#simulation` `#algorithms`
*   [src/systems/SimulationChainSkipper.res](src/systems/SimulationChainSkipper.res): Optimization logic for skipping redundant simulation steps. `#simulation` `#optimization`
*   [src/systems/TeaserPathfinder.res](src/systems/TeaserPathfinder.res): Specialized pathfinding for cinematic teaser sequences. `#teaser` `#pathfinding`
*   [src/systems/ServerTeaser.res](src/systems/ServerTeaser.res): Client-side bridge for server-side teaser generation requests. `#teaser` `#api`
*   [src/systems/ViewerFollow.res](src/systems/ViewerFollow.res): Logic for synchronizing viewer orientations across sessions. `#sync` `#viewer`
*   [src/systems/SvgRenderer.res](src/systems/SvgRenderer.res): Low-level imperative SVG rendering for overlays. `#svg` `#rendering`
*   [src/systems/TourTemplates.res](src/systems/TourTemplates.res): Manager for visual tour templates and themes. `#branding` `#facade`
    *   [src/systems/TourTemplateAssets.res](src/systems/TourTemplateAssets.res): Static and dynamic assets for tour themes. `#assets`
    *   [src/systems/TourTemplateScripts.res](src/systems/TourTemplateScripts.res): Theme-specific interaction scripts and logic. `#logic`
    *   [src/systems/TourTemplateStyles.res](src/systems/TourTemplateStyles.res): CSS-in-JS definitions for tour branding. `#styling`
*   [src/systems/BackendApi.res](src/systems/BackendApi.res): Facade for the consolidated API module. `#api` `#client` `#facade`
*   [src/systems/UploadProcessorTypes.res](src/systems/UploadProcessorTypes.res): Types specialized for the upload pipeline. `#upload` `#types`
*   [src/systems/HotspotLineTypes.res](src/systems/HotspotLineTypes.res): Types for visual hotspot connections. `#hotspots` `#types`

### 🎨 Visual & UI Components
*   [src/components/ViewerUI.res](src/components/ViewerUI.res): High-level orchestrator for the viewer interface. `#ui` `#hud` `#orchestration`
*   [src/components/ViewerHUD.res](src/components/ViewerHUD.res): Primary overlay system (UtilityBar, FloorNav, Labels). `#ui` `#hud` `#overlays`
*   [src/components/FloorNavigation.res](src/components/FloorNavigation.res): Interactive floor and level switcher for the viewer HUD. `#ui` `#navigation`
*   [src/components/UtilityBar.res](src/components/UtilityBar.res): Top-level action bar for viewer tools and settings. `#ui` `#hud`
*   [src/components/VisualPipeline.res](src/components/VisualPipeline.res): Consolidated visualizer pipeline module. `#ui` `#visual-pipeline` `#logic` `#rendering`
*   [src/components/SnapshotOverlay.res](src/components/SnapshotOverlay.res): Visual transition "flash" layer. `#ui` `#transition`
*   [src/components/NotificationLayer.res](src/components/NotificationLayer.res): Centralized notification and processing status layer. `#ui` `#notifications`
*   [src/components/Sidebar.res](src/components/Sidebar.res): Consolidated sidebar module for project management and UI. `#sidebar` `#scene-management` `#ui` `#logic`
    * [src/components/Sidebar/SidebarLogic.res](src/components/Sidebar/SidebarLogic.res): Core sidebar logic and upload orchestration. `#logic`
    * [src/components/Sidebar/SidebarProjectInfo.res](src/components/Sidebar/SidebarProjectInfo.res): UI for tour name and upload triggers. `#ui`
    * [src/components/Sidebar/SidebarProcessing.res](src/components/Sidebar/SidebarProcessing.res): Global processing status and progress tracking. `#ui` `#notifications`
    * [src/components/Sidebar/SidebarBranding.res](src/components/Sidebar/SidebarBranding.res): Application branding and version information. `#ui`
    * [src/components/Sidebar/SidebarActions.res](src/components/Sidebar/SidebarActions.res): Primary toolbar for project operations. `#ui`
*   [src/components/SceneList.res](src/components/SceneList.res): Virtualized list of tour scenes. `#ui` `#virtualization` `#facade`
    *   [src/components/SceneList/SceneItem.res](src/components/SceneList/SceneItem.res): Individual scene item component. `#ui`
*   [src/components/HotspotManager.res](src/components/HotspotManager.res): Visual editor for placement and editing of nav links. `#hotspots` `#editor`
*   [src/components/AppErrorBoundary.res](src/components/AppErrorBoundary.res): Top-level safety net for render failures. `#error-handling` `#stability`
*   [src/components/ErrorFallbackUI.res](src/components/ErrorFallbackUI.res): Visual fallback for caught rendering errors. `#ui` `#error-handling`
*   [src/components/HotspotActionMenu.res](src/components/HotspotActionMenu.res): Contextual menu for hotspot-specific actions. `#ui` `#hotspots`
*   [src/components/HotspotLayer.res](src/components/HotspotLayer.res): Interactive SVG/DOM layer for hotspot rendering. `#ui` `#rendering` `#hotspots`
*   [src/components/HotspotMenuLayer.res](src/components/HotspotMenuLayer.res): Dedicated layer for hotspot-related context menus. `#ui` `#overlays`
*   [src/components/LabelMenu.res](src/components/LabelMenu.res): Interface for adding and editing persistent labels. `#ui` `#labels`
*   [src/components/LinkModal.res](src/components/LinkModal.res): Modal for configuring inter-scene navigation links. `#ui` `#navigation` `#modal`
*   [src/components/ModalContext.res](src/components/ModalContext.res): Context provider for managing application-wide modals. `#state` `#ui` `#modal`
*   [src/components/NotificationContext.res](src/components/NotificationContext.res): Context for dispatching and managing notifications. `#state` `#ui` `#notifications`
*   [src/components/PersistentLabel.res](src/components/PersistentLabel.res): Visual representation of fixed spatial labels in the viewer. `#ui` `#labels`
*   [src/components/PopOver.res](src/components/PopOver.res): Generic popup/hover overlay component. `#ui` `#popover`
*   [src/components/Portal.res](src/components/Portal.res): React portal utility for detached DOM rendering. `#ui` `#dom`
*   [src/components/PreviewArrow.res](src/components/PreviewArrow.res): Visual indicator for navigation previews. `#ui` `#navigation`
*   [src/components/QualityIndicator.res](src/components/QualityIndicator.res): Visual badge for image quality scores. `#ui` `#quality`
*   [src/components/ReturnPrompt.res](src/components/ReturnPrompt.res): Confirmation dialog for unsaved changes or exits. `#ui` `#dialog`
*   [src/components/Tooltip.res](src/components/Tooltip.res): Accessible and styled hover tooltips. `#ui` `#accessibility`
*   [src/components/UploadReport.res](src/components/UploadReport.res): Detailed report UI for batch upload results. `#ui` `#reporting` `#upload`
*   [src/components/ViewerLabelMenu.res](src/components/ViewerLabelMenu.res): Label management interface specialized for the viewer HUD. `#ui` `#hud`
*   [src/components/ViewerLoader.res](src/components/ViewerLoader.res): Loading state and splash screen for the 360 viewer. `#ui` `#loading`
*   [src/components/ViewerManager.res](src/components/ViewerManager.res): Lightweight facade orchestrating viewer logic. `#rendering` `#orchestration` `#facade`
    *   [src/components/ViewerManagerLogic.res](src/components/ViewerManagerLogic.res): Core logic hooks for viewer initialization, scene loading, and sync. `#logic` `#hooks`
    *   [src/components/ViewerManager/ViewerManagerLifecycle.res](src/components/ViewerManager/ViewerManagerLifecycle.res): Lifecycle hooks for stage events and global UI state. `#logic` `#hooks`
*   [src/components/VisualPipeline.res](src/components/VisualPipeline.res): Consolidated visualizer pipeline module. `#ui` `#visual-pipeline` `#logic` `#rendering`
    * [src/components/VisualPipeline/VisualPipelineStyles.res](src/components/VisualPipeline/VisualPipelineStyles.res): CSS-in-JS definitions for the visual pipeline. `#styling`
*   [src/components/ViewerSnapshot.res](src/components/ViewerSnapshot.res): UI for triggering and managing viewer captures. `#ui` `#snapshot`
*   [src/components/ui/LucideIcons.res](src/components/ui/LucideIcons.res): Lightweight facade for Lucide React icons. `#ui` `#icons` `#facade`
    *   [src/components/ui/Lucide/LucideCore.res](src/components/ui/Lucide/LucideCore.res): Core UI icons (arrows, close, menu). `#ui` `#icons`
    *   [src/components/ui/Lucide/LucideActions.res](src/components/ui/Lucide/LucideActions.res): Action icons (edit, delete, save, upload). `#ui` `#icons`
    *   [src/components/ui/Lucide/LucideMedia.res](src/components/ui/Lucide/LucideMedia.res): Media control icons (play, pause, record). `#ui` `#icons`
    *   [src/components/ui/Lucide/LucideStatus.res](src/components/ui/Lucide/LucideStatus.res): Status indicators (check, alert, info). `#ui` `#icons`
*   [src/components/ui/Shadcn.res](src/components/ui/Shadcn.res): Centralized bindings for Shadcn UI primitives. `#ui` `#shadcn` `#bindings`

### ⚙️ Utilities & Infrastructure
*   [src/utils/VersionData.res](src/utils/VersionData.res): Versioning and build metadata. `#utils` `#version`
*   [src/utils/PersistenceLayer.res](src/utils/PersistenceLayer.res): Advanced persistence layer with IndexedDB and session fallback. `#utils` `#storage` `#indexeddb`
*   [src/utils/SessionStore.res](src/utils/SessionStore.res): Session-based storage and state persistence. `#utils` `#storage`
*   [src/utils/RequestQueue.res](src/utils/RequestQueue.res): Queue management for network requests. `#utils` `#network`
*   [src/utils/LazyLoad.res](src/utils/LazyLoad.res): Helpers for lazy loading components and assets. `#utils` `#performance`
*   [src/utils/ProjectionMath.res](src/utils/ProjectionMath.res): Mathematical utilities for 3D/2D projection. `#utils` `#math`
*   [src/utils/ColorPalette.res](src/utils/ColorPalette.res): UI color system and palette definitions. `#utils` `#styling`
*   [src/utils/Constants.res](src/utils/Constants.res): Centralized application constants and configuration. `#utils` `#config`
*   [src/utils/GeoUtils.res](src/utils/GeoUtils.res): Geospatial calculation utilities for tour locations. `#utils` `#geo`
*   [src/utils/ImageOptimizer.res](src/utils/ImageOptimizer.res): Client-side image optimization and compression helpers. `#utils` `#image`
*   [src/utils/PathInterpolation.res](src/utils/PathInterpolation.res): Smooth path interpolation for cinematic movements. `#utils` `#math`
*   [src/utils/ProgressBar.res](src/utils/ProgressBar.res): Logic for managing multi-step progress indicators. `#utils` `#ui`
*   [src/utils/StateInspector.res](src/utils/StateInspector.res): Debug utilities for inspecting the application state tree. `#utils` `#debug`
*   [src/utils/TourLogic.res](src/utils/TourLogic.res): Core domain logic for tour structure and state validation. `#utils` `#logic`
*   [src/utils/UrlUtils.res](src/utils/UrlUtils.res): Utilities for parsing and generating tour URLs. `#utils` `#url`
*   [src/utils/Version.res](src/utils/Version.res): Semantic versioning and build manifest utilities. `#utils` `#version`

### ⚙️ Backend API (Rust)
*   [backend/src/main.rs](backend/src/main.rs): Server entry point, middleware setup, and routing. `#rust` `#api` `#server`
*   [backend/src/api/auth.rs](backend/src/api/auth.rs): Google OAuth2 authentication endpoints. `#rust` `#auth` `#google-oauth`
*   [backend/src/api/geocoding.rs](backend/src/api/geocoding.rs): API endpoints for address lookup and coordinate resolution. `#rust` `#api` `#geocoding`
*   [backend/src/api/project.rs](backend/src/api/project.rs): Endpoints for project packaging, imports, and validation. `#backend-logic` `#project-api`
*   [backend/src/api/media/image.rs](backend/src/api/media/image.rs): Consolidated image processing endpoints and optimization logic. `#image` `#api` `#processing`
*   [backend/src/api/media/video.rs](backend/src/api/media/video.rs): Consolidated video transcoding and teaser generation endpoints. `#video` `#api` `#teaser`
*   [backend/src/api/project_logic.rs](backend/src/api/project_logic.rs): Detailed logic for project packaging and import. `#logic`
*   [backend/src/api/media/image_logic.rs](backend/src/api/media/image_logic.rs): Logic for image processing operations. `#image` `#logic`
*   [backend/src/api/media/video_logic.rs](backend/src/api/media/video_logic.rs): Logic for video transcoding and processing. `#video` `#logic`
*   [backend/src/services/geocoding.rs](backend/src/services/geocoding.rs): Facade for the geocoding service with LRU caching. `#geocoding` `#services` `#facade`
*   [backend/src/services/media/mod.rs](backend/src/services/media/mod.rs): Facade for core media services (encoding, analysis, resizing). `#media` `#services` `#facade`
*   [backend/src/services/media/analysis.rs](backend/src/services/media/analysis.rs): Aggregated media analysis functionality. `#media` `#analysis`
*   [backend/src/services/media/analysis_quality.rs](backend/src/services/media/analysis_quality.rs): Image quality assessment logic. `#media` `#quality`
*   [backend/src/services/media/analysis_exif.rs](backend/src/services/media/analysis_exif.rs): EXIF metadata extraction logic. `#media` `#exif`
*   [backend/src/services/media/analysis/mod.rs](backend/src/services/media/analysis/mod.rs): Facade for image quality analysis and metadata extraction. `#media` `#analysis` `#facade`
    *   [backend/src/services/media/analysis/exif.rs](backend/src/services/media/analysis/exif.rs): EXIF data parsing and normalization logic. `#exif` `#parsing`
    *   [backend/src/services/media/analysis/quality.rs](backend/src/services/media/analysis/quality.rs): Image quality analysis, histograms, and blur detection. `#image-processing` `#logic`
    *   [backend/src/services/media/webp.rs](backend/src/services/media/webp.rs): WebP encoding and metadata injection. `#encoding`
    *   [backend/src/services/media/resizing.rs](backend/src/services/media/resizing.rs): High-performance image resizing. `#processing`
    *   [backend/src/services/media/naming.rs](backend/src/services/media/naming.rs): Camera filename normalization logic. `#utils`
*   [backend/src/api/mod.rs](backend/src/api/mod.rs): Root interface for the backend REST API. `#api`
*   [backend/src/api/media/mod.rs](backend/src/api/media/mod.rs): Sub-router for media processing and retrieval. `#api` `#media`
    *   [backend/src/api/media/serve.rs](backend/src/api/media/serve.rs): Handles direct asset serving and static delivery. `#api` `#static`
    *   [backend/src/api/media/similarity.rs](backend/src/api/media/similarity.rs): Endpoint for image similarity and visual clustering. `#api` `#ai`
*   [backend/src/api/project.rs](backend/src/api/project.rs): Endpoints for project packaging, imports, pathfinding, and validation. `#backend-logic` `#project-api`
*   [backend/src/api/telemetry.rs](backend/src/api/telemetry.rs): Endpoint for receiving client-side telemetry and logs. `#api` `#telemetry`
*   [backend/src/api/telemetry_logic.rs](backend/src/api/telemetry_logic.rs): Processing logic for telemetry ingestion and storage. `#telemetry` `#logic`
*   [backend/src/api/utils.rs](backend/src/api/utils.rs): Shared logic for API response formatting and errors. `#api` `#utils`

### 🛡️ Backend Core & Services
*   [backend/src/lib.rs](backend/src/lib.rs): Shared library code and trait definitions for the backend. `#rust` `#core`
*   [backend/src/metrics.rs](backend/src/metrics.rs): Prometheus metrics collection and instrumentation. `#monitoring` `#telemetry`
*   [backend/src/middleware.rs](backend/src/middleware.rs): Centralized Actix-web middleware collection (Auth, Quota, Request Tracker). `#mw`
*   [backend/src/models.rs](backend/src/models.rs): Aggregated data models and shared type definitions. `#types` `#models`
*   [backend/src/models/mod.rs](backend/src/models/mod.rs): Data model and shared type definitions. `#types` `#models`
    *   [backend/src/models/project.rs](backend/src/models/project.rs): Rust-side representation of the tour project structure. `#models`
    *   [backend/src/models/user.rs](backend/src/models/user.rs): User account data model. `#models` `#auth`
    *   [backend/src/models/session.rs](backend/src/models/session.rs): Active session and token data model. `#models` `#auth`
    *   [backend/src/models/telemetry.rs](backend/src/models/telemetry.rs): Client-side telemetry event model. `#models` `#telemetry`
    *   [backend/src/models/metadata.rs](backend/src/models/metadata.rs): Generic metadata and tag models. `#models`
    *   [backend/src/models/similarity.rs](backend/src/models/similarity.rs): Visual similarity and vector model definitions. `#models` `#ai`
    *   [backend/src/models/validation.rs](backend/src/models/validation.rs): Structural validation result models. `#models` `#validation`
    *   [backend/src/models/geocoding.rs](backend/src/models/geocoding.rs): Spatial and geocoding result models. `#models` `#geocoding`
    *   [backend/src/models/errors.rs](backend/src/models/errors.rs): Unified backend error system and response mapping. `#errors`
    *   [backend/src/models/errors_impl.rs](backend/src/models/errors_impl.rs): Domain-specific implementation of the error system. `#models` `#errors`
    *   [backend/src/models/errors_tests.rs](backend/src/models/errors_tests.rs): Unit tests for the backend error system. `#models` `#testing`
*   [backend/src/pathfinder.rs](backend/src/pathfinder.rs): Consolidated high-performance navigation pathfinding logic. `#navigation` `#logic` `#algorithms`
*   [backend/src/pathfinder/graph.rs](backend/src/pathfinder/graph.rs): Data models and types for the pathfinding graph. `#navigation` `#models` `#types`
*   [backend/src/pathfinder/algorithms.rs](backend/src/pathfinder/algorithms.rs): Graph traversal logic for optimal routes. `#algorithms` `#graph-theory`
*   [backend/src/services/mod.rs](backend/src/services/mod.rs): Domain-specific service layer entry point. `#services`
    *   [backend/src/services/auth.rs](backend/src/services/auth.rs): Orchestrator for authentication and identity services. `#auth` `#facade`
    *   [backend/src/services/database.rs](backend/src/services/database.rs): Persistence layer for project metadata and users. `#database` `#logic`
    *   [backend/src/services/shutdown.rs](backend/src/services/shutdown.rs): Managed graceful shutdown orchestration. `#lifecycle`
    *   [backend/src/services/upload_quota.rs](backend/src/services/upload_quota.rs): Rate-limiting and quota management logic. `#quota` `#logic`
    *   [backend/src/services/upload_quota_tests.rs](backend/src/services/upload_quota_tests.rs): Integration tests for the quota enforcement system. `#rust` `#testing`
*   [backend/src/services/project/mod.rs](backend/src/services/project/mod.rs): Core services for heavy project operations. `#services` `#project`
    *   [backend/src/services/project/load.rs](backend/src/services/project/load.rs): High-efficiency project loading and patching. `#logic`
    *   [backend/src/services/project/package.rs](backend/src/services/project/package.rs): ZIP packaging and tour assembly logic. `#logic` `#export`
    *   [backend/src/services/project/validate.rs](backend/src/services/project/validate.rs): Deep structural validation for tour projects. `#validation`
*   [backend/src/services/media/mod.rs](backend/src/services/media/mod.rs): Facade for core media services (encoding, analysis, resizing). `#media` `#services` `#facade`
*   [backend/src/services/media/storage.rs](backend/src/services/media/storage.rs): Persistent storage and retrieval of media assets. `#media` `#storage`
*   [backend/src/services/media/naming_old.rs](backend/src/services/media/naming_old.rs): Legacy camera filename normalization logic. `#rust` `#legacy`


## 🆕 Unmapped Modules
* [backend/src/services/geocoding/mod.rs](backend/src/services/geocoding/mod.rs): New module detected. Please classify. #new
* [backend/src/services/geocoding/osm.rs](backend/src/services/geocoding/osm.rs): New module detected. Please classify. #new
* [backend/src/services/geocoding/cache.rs](backend/src/services/geocoding/cache.rs): New module detected. Please classify. #new
* [backend/src/api/media/image_tasks.rs](backend/src/api/media/image_tasks.rs): New module detected. Please classify. #new
* [backend/src/api/media/image_multipart.rs](backend/src/api/media/image_multipart.rs): New module detected. Please classify. #new
* [backend/src/api/project_multipart.rs](backend/src/api/project_multipart.rs): New module detected. Please classify. #new
* [backend/src/pathfinder/walk.rs](backend/src/pathfinder/walk.rs): New module detected. Please classify. #new
* [backend/src/pathfinder/utils.rs](backend/src/pathfinder/utils.rs): New module detected. Please classify. #new
* [backend/src/pathfinder/timeline.rs](backend/src/pathfinder/timeline.rs): New module detected. Please classify. #new
* [backend/src/middleware/mod.rs](backend/src/middleware/mod.rs): New module detected. Please classify. #new
* [backend/src/middleware/auth.rs](backend/src/middleware/auth.rs): New module detected. Please classify. #new
* [backend/src/middleware/quota_check.rs](backend/src/middleware/quota_check.rs): New module detected. Please classify. #new
* [backend/src/middleware/request_tracker.rs](backend/src/middleware/request_tracker.rs): New module detected. Please classify. #new
