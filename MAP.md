# 🗺️ Robust Virtual Tour Builder - Codebase Map

This map provides a semantic overview of the project structure to optimize context acquisition and pinpoint intent through tagging.

---

## 🏗️ Core Architecture

### 🚀 Entry & Foundational Bindings
*   [src/Main.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/Main.res): Entry point, global initialization, and React root mounting. `#entry-point` `#initialization`
*   [src/ServiceWorker.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/ServiceWorker.res): Offline capabilities and asset caching. `#pwa` `#service-worker`
*   [src/ServiceWorkerMain.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/ServiceWorkerMain.res): Main thread logic for service worker coordination. `#pwa` `#orchestration`
*   [src/App.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/App.res): Root React component orchestrating the high-level UI layout. `#root-component` `#layout`
*   [src/ReBindings.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/ReBindings.res): Lightweight facade for centralized external bindings. `#rescript` `#bindings` `#facade`
    *   [src/bindings/BrowserBindings.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/bindings/BrowserBindings.res): Core browser types (Blob, File), JSZip, and AbortController. `#browser` `#types`
    *   [src/bindings/DomBindings.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/bindings/DomBindings.res): DOM, Window, and React-specific bindings. `#dom` `#react` `#window`
    *   [src/bindings/WebApiBindings.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/bindings/WebApiBindings.res): Fetch, URL, and FormData APIs. `#api` `#fetch` `#network`
    *   [src/bindings/GraphicsBindings.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/bindings/GraphicsBindings.res): Canvas 2D and SVG rendering bindings. `#graphics` `#canvas` `#svg`
    *   [src/bindings/ViewerBindings.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/bindings/ViewerBindings.res): Pannellum and 360 viewer-specific bindings. `#viewer` `#pannellum`
* [src/utils/Logger.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/Logger.res): Lightweight facade for the unified logging and telemetry system. `#logging` `#telemetry` `#facade`
    * [src/utils/LoggerLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/LoggerLogic.res): Core logging logic, console output, and performance tracking. `#logic`
    * [src/utils/LoggerTelemetry.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/LoggerTelemetry.res): Async telemetry batching and backend synchronization. `#telemetry`
    * [src/utils/LoggerTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/LoggerTypes.res): Shared types, levels, and error helpers for the logger. `#types`

### 🛡️ State Management & Logic
*   [src/core/State.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/State.res): Central application state definition. `#state` `#immutability`
*   [src/core/Reducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/Reducer.res): Root reducer orchestrating domain updates. `#reducer` `#action-dispatch`
*   [src/core/Actions.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/Actions.res): All supported user and system actions. `#actions` `#events`
*   [src/core/Types.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/Types.res): Global domain types and application-wide interfaces. `#types`
*   [src/core/SharedTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/SharedTypes.res): Utility types shared across frontend and backend logic. `#types`
*   [src/core/JsonTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/JsonTypes.res): Strictly-typed JSON structures for project persistence. `#json` `#types`
*   [src/core/ViewerTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/ViewerTypes.res): Types specialized for 360 viewer state and configuration. `#viewer` `#types`
*   [src/core/ViewerState.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/ViewerState.res): Localized state for the active viewer instance. `#state` `#viewer`
*   [src/core/SceneCache.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/SceneCache.res): In-memory cache for processed scene assets and metadata. `#cache` `#performance`
*   [src/core/GlobalStateBridge.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/GlobalStateBridge.res): Bridge for synchronizing state across different contexts. `#state` `#sync`
*   [src/core/reducers/mod.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/mod.res): Directory entry for the domain-specific reducers. `#reducer`
    *   [src/core/reducers/RootReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/RootReducer.res): Combinator for all sub-reducers into a single state tree. `#reducer` `#composition`
    *   [src/core/reducers/ProjectReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/ProjectReducer.res): Reducer for project-level state (metadata, settings). `#reducer`
    *   [src/core/reducers/SceneReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/SceneReducer.res): Reducer for scene collection and image management. `#reducer` `#scene`
    *   [src/core/reducers/HotspotReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/HotspotReducer.res): Reducer for interactive hotspots and their actions. `#reducer` `#hotspots`
    *   [src/core/reducers/NavigationReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/NavigationReducer.res): Reducer for active navigation state and history. `#reducer` `#navigation`
    *   [src/core/reducers/SimulationReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/SimulationReducer.res): Reducer for autopilot and simulation parameters. `#reducer` `#simulation`
    *   [src/core/reducers/TimelineReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/TimelineReducer.res): Reducer for the visual timeline and event sequencing. `#reducer` `#timeline`
    *   [src/core/reducers/UiReducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/reducers/UiReducer.res): Reducer for non-persistent UI state (modals, tooltips). `#reducer` `#ui`
*   [src/core/AppContext.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/AppContext.res): Typed React Context for state and dispatch accessibility. `#react-context` `#hooks`
*   [src/core/SceneHelpers.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/SceneHelpers.res): Lightweight facade for scene-related helpers. `#helpers` `#scene` `#facade`
    *   [src/core/SceneHelpersParser.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/SceneHelpersParser.res): Parsing logic for hotspots, scenes, and projects. `#parsing`
    *   [src/core/SceneHelpersLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/SceneHelpersLogic.res): Complex action handlers for scene management. `#logic`
*   [src/core/UiHelpers.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/UiHelpers.res): Generic UI utilities, blob/file handling, and array manipulation. `#helpers` `#ui` `#utils`
*   [src/core/SimHelpers.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/SimHelpers.res): Simulation and timeline specific parsers and helpers. `#helpers` `#simulation`

### 🌐 System Layer (Business Logic)
*   [src/systems/UploadProcessor.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/UploadProcessor.res): Lightweight facade for the image processing pipeline. `#upload` `#facade`
*   [src/systems/UploadProcessorLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/UploadProcessorLogic.res): Lightweight facade for the image processing and upload queue logic. `#upload` `#facade`
    *   [src/systems/UploadProcessorLogicLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/UploadProcessorLogicLogic.res): Core logic for image processing, queue management, and upload finalization. `#logic`
* [src/systems/SceneLoader.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SceneLoader.res): Lightweight facade for scene transition and viewer loading orchestration. `#scene-loading` `#lifecycle` `#facade`
    * [src/systems/SceneLoaderLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SceneLoaderLogic.res): Lightweight facade for scene loading orchestration. `#logic` `#facade`
    * [src/systems/SceneLoaderLogicReuse.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SceneLoaderLogicReuse.res): Logic for viewer reuse and session persistence. `#logic`
    * [src/systems/SceneLoaderLogicConfig.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SceneLoaderLogicConfig.res): Pannellum configuration and URL generation. `#logic` `#config`
    * [src/systems/SceneLoaderLogicEvents.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SceneLoaderLogicEvents.res): Handler for viewer load events and hotspot injection. `#logic` `#events`
    * [src/systems/SceneLoaderTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SceneLoaderTypes.res): Shared types and performance tracking for scene loading. `#types`
*   [src/systems/SceneTransitionManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SceneTransitionManager.res): Manages DOM transitions and viewer swapping logic. `#transition` `#dom`
*   [src/systems/PannellumLifecycle.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/PannellumLifecycle.res): Lifecycle bindings for Pannellum viewer initialization and destruction. `#pannellum` `#bindings`
*   [src/systems/HotspotLine.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/HotspotLine.res): Facade for visual hotspot connections and simulation arrows. `#hotspots` `#rendering` `#facade`
*   [src/systems/HotspotLineUtils.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/HotspotLineUtils.res): State and caching for hotspot line rendering. `#utils` `#caching`
*   [src/core/interfaces/ViewerDriver.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/interfaces/ViewerDriver.res): Interface contract for 360 renderer drivers. `#interface` `#abstraction`
*   [src/systems/PannellumAdapter.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/PannellumAdapter.res): Pannellum-specific implementation of ViewerDriver. `#adapter` `#rendering`
*   [src/systems/ViewerPool.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ViewerPool.res): Manager for multiple viewport instances and their lifecycles. `#orchestration` `#efficiency`
*   [src/systems/HotspotLineLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/HotspotLineLogic.res): Coordinate projection math and SVG drawing primitives. `#math` `#rendering` `#logic`
*   [src/systems/HotspotLineUtils.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/HotspotLineUtils.res): State and caching for hotspot line rendering. `#utils` `#caching`
*   [src/systems/SimulationDriver.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SimulationDriver.res): Logic for Autopilot and route simulations. `#autopilot` `#simulation` `#navigation`
*   [src/systems/NavigationController.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationController.res): Manages movement between scenes. `#navigation` `#scene-switching`
*   [src/systems/NavigationFSM.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationFSM.res): Pure deterministic Finite State Machine for navigation lifecycle. `#orchestration` `#reliability`
*   [src/systems/NavigationGraph.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationGraph.res): Viewport math and link projection logic. `#math` `#navigation`
*   [src/systems/SceneSwitcher.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SceneSwitcher.res): Handles the state transitions and side effects of changing scenes. `#scene-switching` `#transition`
*   [src/systems/TeaserPlayback.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserPlayback.res): Orchestrates teaser and autopilot playback logic. `#teaser` `#playback`
*   [src/systems/TeaserState.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserState.res): State management for the teaser system. `#teaser` `#state`
*   [src/systems/TeaserManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserManager.res): Manager for teaser recording and playback sessions. `#teaser` `#manager`
*   [src/systems/ProjectManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ProjectManager.res): Lightweight facade for project save/load operations. `#persistence` `#save-load` `#facade`
    * [src/systems/ProjectManagerLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ProjectManagerLogic.res): Core logic for project packaging and resolution. `#logic`
    * [src/systems/ProjectManagerTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ProjectManagerTypes.res): Shared types for project management. `#types`
*   [src/systems/Exporter.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/Exporter.res): Generates production-ready tour clusters. `#export` `#deployment`
*   [src/systems/api/ProjectApi.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/api/ProjectApi.res): Frontend API client for project operations. `#api` `#client`
*   [src/systems/api/MediaApi.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/api/MediaApi.res): Frontend API client for media operations. `#api` `#media`
*   [src/systems/FingerprintService.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/FingerprintService.res): Image fingerprinting for deduplication. `#image` `#fingerprint`
*   [src/systems/PanoramaClusterer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/PanoramaClusterer.res): Logic for grouping and clustering panoramas. `#logic` `#clustering`
*   [src/systems/SvgManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SvgManager.res): Management of SVG overlays and elements. `#svg` `#rendering`
*   [src/systems/VideoEncoder.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/VideoEncoder.res): Logic for encoding tour sequences into video. `#video` `#encoding`
*   [src/systems/DownloadSystem.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/DownloadSystem.res): Management of asset downloading and caching. `#download` `#cache`
*   [src/systems/AudioManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/AudioManager.res): Orchestrator for spatial audio and background soundscapes. `#audio` `#spatial-sound`
*   [src/systems/EventBus.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/EventBus.res): Centralized pub/sub broker for decoupled system communication. `#events` `#orchestration`
*   [src/systems/InputSystem.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/InputSystem.res): Unified handler for mouse, touch, and keyboard input. `#input` `#gestures`
*   [src/systems/CursorPhysics.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/CursorPhysics.res): Physics-based cursor and interaction smoothing. `#physics` `#ux`
*   [src/systems/ExifParser.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ExifParser.res): Frontend-side EXIF data parsing and normalization. `#exif` `#parsing`
*   [src/systems/ExifReportGenerator.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ExifReportGenerator.res): Lightweight facade for EXIF report generation and downloading. `#exif` `#reporting` `#facade`
    *   [src/systems/ExifReportGeneratorLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ExifReportGeneratorLogic.res): Main report generation orchestrator. `#logic`
    *   [src/systems/ExifReportGeneratorLogicExtraction.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ExifReportGeneratorLogicExtraction.res): EXIF data extraction from file batches. `#logic` `#extraction`
    *   [src/systems/ExifReportGeneratorLogicLocation.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ExifReportGeneratorLogicLocation.res): GPS analysis, centroid calculation, and geocoding. `#logic` `#geo`
    *   [src/systems/ExifReportGeneratorLogicGroups.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ExifReportGeneratorLogicGroups.res): Camera device grouping and file listing logic. `#logic`
    *   [src/systems/ExifReportGeneratorLogicTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ExifReportGeneratorLogicTypes.res): Internal types for EXIF report analysis. `#types`
    *   [src/systems/ExifReportGeneratorTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ExifReportGeneratorTypes.res): Shared types for EXIF reporting. `#types`
    *   [src/systems/ExifReportGeneratorUtils.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ExifReportGeneratorUtils.res): Project name generation and report downloading utilities. `#utils`
*   [src/systems/ImageValidator.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ImageValidator.res): Client-side validation of image formats and dimensions. `#image` `#validation`
*   [src/systems/NavigationUI.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationUI.res): UI-driven navigation logic and breadcrumb management. `#navigation` `#ui`
*   [src/systems/NavigationRenderer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationRenderer.res): Specialized renderer for interactive navigation elements. `#rendering` `#navigation`
*   [src/systems/LinkEditorLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/LinkEditorLogic.res): Core logic for the visual link and hotspot editor. `#editor` `#logic`
*   [src/systems/ProjectData.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ProjectData.res): Domain logic for project structure manipulation and serialization. `#project` `#logic`
*   [src/systems/SimulationLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SimulationLogic.res): Advanced logic for waypoint-based movement simulations. `#simulation` `#logic`
*   [src/systems/SimulationNavigation.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SimulationNavigation.res): Navigation specialized for automated autopilot routes. `#simulation` `#navigation`
*   [src/systems/SimulationPathGenerator.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SimulationPathGenerator.res): Algorithm for generating optimal paths between scenes. `#simulation` `#algorithms`
*   [src/systems/SimulationChainSkipper.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SimulationChainSkipper.res): Optimization logic for skipping redundant simulation steps. `#simulation` `#optimization`
*   [src/systems/TeaserPathfinder.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserPathfinder.res): Specialized pathfinding for cinematic teaser sequences. `#teaser` `#pathfinding`
*   [src/systems/ServerTeaser.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ServerTeaser.res): Client-side bridge for server-side teaser generation requests. `#teaser` `#api`
*   [src/systems/ViewerFollow.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ViewerFollow.res): Logic for synchronizing viewer orientations across sessions. `#sync` `#viewer`
*   [src/systems/SvgRenderer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SvgRenderer.res): Low-level imperative SVG rendering for overlays. `#svg` `#rendering`
*   [src/systems/TourTemplates.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TourTemplates.res): Manager for visual tour templates and themes. `#branding` `#facade`
    *   [src/systems/TourTemplateAssets.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TourTemplateAssets.res): Static and dynamic assets for tour themes. `#assets`
    *   [src/systems/TourTemplateScripts.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TourTemplateScripts.res): Theme-specific interaction scripts and logic. `#logic`
    *   [src/systems/TourTemplateStyles.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TourTemplateStyles.res): CSS-in-JS definitions for tour branding. `#styling`
*   [src/systems/BackendApi.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/BackendApi.res): Unified frontend client for all backend interactions. `#api` `#client`
*   [src/systems/UploadProcessorTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/UploadProcessorTypes.res): Types specialized for the upload pipeline. `#upload` `#types`
*   [src/systems/HotspotLineTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/HotspotLineTypes.res): Types for visual hotspot connections. `#hotspots` `#types`
*   [src/systems/api/ApiTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/api/ApiTypes.res): Generic API request/response types. `#api` `#types`

### 🎨 Visual & UI Components
*   [src/components/ViewerUI.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerUI.res): High-level orchestrator for the viewer interface. `#ui` `#hud` `#orchestration`
*   [src/components/ViewerHUD.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerHUD.res): Primary overlay system (UtilityBar, FloorNav, Labels). `#ui` `#hud` `#overlays`
*   [src/components/SnapshotOverlay.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/SnapshotOverlay.res): Visual transition "flash" layer. `#ui` `#transition`
*   [src/components/NotificationLayer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/NotificationLayer.res): Centralized notification and processing status layer. `#ui` `#notifications`
*   [src/components/Sidebar.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Sidebar.res): Lightweight facade for sidebar management. `#sidebar` `#scene-management` `#facade`
    *   [src/components/Sidebar/SidebarMain.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Sidebar/SidebarMain.res): Lightweight facade for sidebar orchestration. `#ui` `#facade`
    *   [src/components/Sidebar/SidebarMainLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Sidebar/SidebarMainLogic.res): Core project management and upload logic. `#logic`
    *   [src/components/Sidebar/SidebarMainTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Sidebar/SidebarMainTypes.res): Types for sidebar processing and state. `#types`
    *   [src/components/Sidebar/SidebarBranding.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Sidebar/SidebarBranding.res): Sidebar branding and version header. `#ui`
    *   [src/components/Sidebar/SidebarActions.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Sidebar/SidebarActions.res): Primary action buttons for project management. `#ui` `#actions`
    *   [src/components/Sidebar/SidebarProjectInfo.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Sidebar/SidebarProjectInfo.res): Project name input and upload triggers. `#ui`
    *   [src/components/Sidebar/SidebarProcessing.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Sidebar/SidebarProcessing.res): Processing progress and status overlay. `#ui` `#progress`
*   [src/components/SceneList.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/SceneList.res): Virtualized list of tour scenes. `#ui` `#virtualization` `#facade`
    *   [src/components/SceneList/SceneListMain.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/SceneList/SceneListMain.res): Main virtualization and list management logic. `#logic`
    *   [src/components/SceneList/SceneItem.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/SceneList/SceneItem.res): Individual scene item component. `#ui`
*   [src/components/HotspotManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/HotspotManager.res): Visual editor for placement and editing of nav links. `#hotspots` `#editor`
*   [src/components/AppErrorBoundary.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/AppErrorBoundary.res): Top-level safety net for render failures. `#error-handling` `#stability`
*   [src/components/ErrorFallbackUI.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ErrorFallbackUI.res): Visual fallback for caught rendering errors. `#ui` `#error-handling`
*   [src/components/HotspotManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/HotspotManager.res): Visual editor for placement and editing of nav links. `#hotspots` `#editor`
*   [src/components/HotspotActionMenu.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/HotspotActionMenu.res): Contextual menu for hotspot-specific actions. `#ui` `#hotspots`
*   [src/components/HotspotLayer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/HotspotLayer.res): Interactive SVG/DOM layer for hotspot rendering. `#ui` `#rendering` `#hotspots`
*   [src/components/HotspotMenuLayer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/HotspotMenuLayer.res): Dedicated layer for hotspot-related context menus. `#ui` `#overlays`
*   [src/components/LabelMenu.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/LabelMenu.res): Interface for adding and editing persistent labels. `#ui` `#labels`
*   [src/components/LinkModal.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/LinkModal.res): Modal for configuring inter-scene navigation links. `#ui` `#navigation` `#modal`
*   [src/components/ModalContext.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ModalContext.res): Context provider for managing application-wide modals. `#state` `#ui` `#modal`
*   [src/components/NotificationContext.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/NotificationContext.res): Context for dispatching and managing notifications. `#state` `#ui` `#notifications`
*   [src/components/PersistentLabel.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/PersistentLabel.res): Visual representation of fixed spatial labels in the viewer. `#ui` `#labels`
*   [src/components/PopOver.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/PopOver.res): Generic popup/hover overlay component. `#ui` `#popover`
*   [src/components/Portal.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Portal.res): React portal utility for detached DOM rendering. `#ui` `#dom`
*   [src/components/PreviewArrow.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/PreviewArrow.res): Visual indicator for navigation previews. `#ui` `#navigation`
*   [src/components/QualityIndicator.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/QualityIndicator.res): Visual badge for image quality scores. `#ui` `#quality`
*   [src/components/ReturnPrompt.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ReturnPrompt.res): Confirmation dialog for unsaved changes or exits. `#ui` `#dialog`
*   [src/components/Tooltip.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Tooltip.res): Accessible and styled hover tooltips. `#ui` `#accessibility`
*   [src/components/UploadReport.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/UploadReport.res): Detailed report UI for batch upload results. `#ui` `#reporting` `#upload`
*   [src/components/ViewerLabelMenu.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerLabelMenu.res): Label management interface specialized for the viewer HUD. `#ui` `#hud`
*   [src/components/ViewerLoader.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerLoader.res): Loading state and splash screen for the 360 viewer. `#ui` `#loading`
*   [src/components/ViewerManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerManager.res): Lightweight facade orchestrating viewer logic. `#rendering` `#orchestration` `#facade`
    *   [src/components/ViewerManagerLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerManagerLogic.res): Core logic hooks for viewer initialization, scene loading, and sync. `#logic` `#hooks`
*   [src/components/ViewerSnapshot.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerSnapshot.res): UI for triggering and managing viewer captures. `#ui` `#snapshot`
*   [src/components/ui/Shadcn.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/Shadcn.res): Centralized bindings for Shadcn UI primitives. `#ui` `#shadcn` `#bindings`

### ⚙️ Utilities & Infrastructure
*   [src/utils/VersionData.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/VersionData.res): Versioning and build metadata. `#utils` `#version`
*   [src/utils/SessionStore.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/SessionStore.res): Session-based storage and state persistence. `#utils` `#storage`
*   [src/utils/RequestQueue.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/RequestQueue.res): Queue management for network requests. `#utils` `#network`
*   [src/utils/LazyLoad.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/LazyLoad.res): Helpers for lazy loading components and assets. `#utils` `#performance`
*   [src/utils/ProjectionMath.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/ProjectionMath.res): Mathematical utilities for 3D/2D projection. `#utils` `#math`
*   [src/utils/ColorPalette.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/ColorPalette.res): UI color system and palette definitions. `#utils` `#styling`
*   [src/utils/Constants.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/Constants.res): Centralized application constants and configuration. `#utils` `#config`
*   [src/utils/GeoUtils.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/GeoUtils.res): Geospatial calculation utilities for tour locations. `#utils` `#geo`
*   [src/utils/ImageOptimizer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/ImageOptimizer.res): Client-side image optimization and compression helpers. `#utils` `#image`
*   [src/utils/PathInterpolation.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/PathInterpolation.res): Smooth path interpolation for cinematic movements. `#utils` `#math`
*   [src/utils/ProgressBar.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/ProgressBar.res): Logic for managing multi-step progress indicators. `#utils` `#ui`
*   [src/utils/StateInspector.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/StateInspector.res): Debug utilities for inspecting the application state tree. `#utils` `#debug`
*   [src/utils/TourLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/TourLogic.res): Core domain logic for tour structure and state validation. `#utils` `#logic`
*   [src/utils/UrlUtils.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/UrlUtils.res): Utilities for parsing and generating tour URLs. `#utils` `#url`
*   [src/utils/Version.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/Version.res): Semantic versioning and build manifest utilities. `#utils` `#version`

### ⚙️ Backend API (Rust)
*   [backend/src/main.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/main.rs): Server entry point, middleware setup, and routing. `#rust` `#api` `#server`
*   [backend/src/api/auth.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/auth.rs): Google OAuth2 authentication endpoints. `#rust` `#auth` `#google-oauth`
*   [backend/src/api/project.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project.rs): Endpoints for project packaging, imports, and validation. `#backend-logic` `#project-api`
*   [backend/src/api/media/image/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/image/mod.rs): Facade for image processing endpoints. `#image` `#api` `#facade`
    *   [backend/src/api/media/image/image_logic.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/image/image_logic.rs): Core image optimization and batch processing logic. `#logic`
    *   [backend/src/api/media/image/image_utils.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/image/image_utils.rs): Multipart form-data parsing for image uploads. `#utils`
*   [backend/src/api/media/video/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/video/mod.rs): Facade for video transcoding and teaser generation. `#video` `#api` `#facade`
    *   [backend/src/api/media/video/video_logic.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/video/video_logic.rs): Headless browser automation and FFmpeg orchestration logic. `#logic`
*   [backend/src/api/project/storage/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project/storage/mod.rs): Facade for project persistence, ZIP generation, and imports. `#storage` `#api` `#facade`
    *   [backend/src/api/project/storage/storage_logic.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project/storage/storage_logic.rs): Project validation, summary generation, and ZIP assembly logic. `#logic`
*   [backend/src/services/geocoding/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/geocoding/mod.rs): Facade for the geocoding service with LRU caching. `#geocoding` `#services` `#facade`
    *   [backend/src/services/geocoding/logic.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/geocoding/logic.rs): OSM Nominatim API interaction and coordinate rounding logic. `#logic`
*   [backend/src/services/media/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/media/mod.rs): Facade for core media services (encoding, analysis, resizing). `#media` `#services` `#facade`
*   [backend/src/services/media/analysis/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/media/analysis/mod.rs): Facade for image quality analysis and metadata extraction. `#media` `#analysis` `#facade`
    *   [backend/src/services/media/analysis/exif.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/media/analysis/exif.rs): EXIF data parsing and normalization logic. `#exif` `#parsing`
    *   [backend/src/services/media/analysis/quality.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/media/analysis/quality.rs): Image quality analysis, histograms, and blur detection. `#image-processing` `#logic`
    *   [backend/src/services/media/webp.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/media/webp.rs): WebP encoding and metadata injection. `#encoding`
    *   [backend/src/services/media/resizing.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/media/resizing.rs): High-performance image resizing. `#processing`
    *   [backend/src/services/media/naming.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/media/naming.rs): Camera filename normalization logic. `#utils`
*   [backend/src/pathfinder/algorithms.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/pathfinder/algorithms.rs): Graph traversal logic for optimal routes. `#algorithms` `#graph-theory`
*   [backend/src/api/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/mod.rs): Root interface for the backend REST API. `#api`
*   [backend/src/api/media/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/mod.rs): Sub-router for media processing and retrieval. `#api` `#media`
    *   [backend/src/api/media/serve.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/serve.rs): Handles direct asset serving and static delivery. `#api` `#static`
    *   [backend/src/api/media/similarity.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/similarity.rs): Endpoint for image similarity and visual clustering. `#api` `#ai`
*   [backend/src/api/project/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project/mod.rs): Sub-router for project management and metadata. `#api` `#project`
    *   [backend/src/api/project/export.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project/export.rs): Trigger for tour packaging and production export. `#api` `#export`
    *   [backend/src/api/project/navigation.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project/navigation.rs): Endpoint for calculating navigation graphs on the fly. `#api` `#navigation`
    *   [backend/src/api/project/validation.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project/validation.rs): Service for validating project integrity and constraints. `#api` `#validation`
*   [backend/src/api/telemetry.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/telemetry.rs): Endpoint for receiving client-side telemetry and logs. `#api` `#telemetry`
*   [backend/src/api/utils.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/utils.rs): Shared logic for API response formatting and errors. `#api` `#utils`

### 🛡️ Backend Core & Services
*   [backend/src/lib.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/lib.rs): Shared library code and trait definitions for the backend. `#rust` `#core`
*   [backend/src/metrics.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/metrics.rs): Prometheus metrics collection and instrumentation. `#monitoring` `#telemetry`
*   [backend/src/middleware/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/middleware/mod.rs): Centralized Actix-web middleware collection. `#mw`
    *   [backend/src/middleware/quota_check.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/middleware/quota_check.rs): Enforces upload and API usage quotas. `#mw` `#security`
    *   [backend/src/middleware/request_tracker.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/middleware/request_tracker.rs): Tracks request latency and success rates. `#mw` `#telemetry`
*   [backend/src/models/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/models/mod.rs): Data model and shared type definitions. `#types` `#models`
    *   [backend/src/models/project.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/models/project.rs): Rust-side representation of the tour project structure. `#models`
    *   [backend/src/models/user.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/models/user.rs): User and session data models for authentication. `#models` `#auth`
    *   [backend/src/models/errors.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/models/errors.rs): Unified backend error system and response mapping. `#errors`
*   [backend/src/pathfinder/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/pathfinder/mod.rs): High-performance navigation pathfinding logic. `#navigation` `#logic`
    *   [backend/src/pathfinder/graph.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/pathfinder/graph.rs): Spatial graph representation of scene nodes. `#graph`
    *   [backend/src/pathfinder/utils.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/pathfinder/utils.rs): Math and spatial utilities for coordinate mapping. `#utils`
*   [backend/src/services/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/mod.rs): Domain-specific service layer entry point. `#services`
    *   [backend/src/services/auth.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/auth.rs): Google Auth and token validation service. `#auth` `#logic`
    *   [backend/src/services/database.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/database.rs): Persistence layer for project metadata and users. `#database` `#logic`
    *   [backend/src/services/shutdown.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/shutdown.rs): Managed graceful shutdown orchestration. `#lifecycle`
    *   [backend/src/services/upload_quota.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/upload_quota.rs): Rate-limiting and quota management logic. `#quota` `#logic`
*   [backend/src/services/project/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/project/mod.rs): Core services for heavy project operations. `#services` `#project`
    *   [backend/src/services/project/load.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/project/load.rs): High-efficiency project loading and patching. `#logic`
    *   [backend/src/services/project/package.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/project/package.rs): ZIP packaging and tour assembly logic. `#logic` `#export`
    *   [backend/src/services/project/validate.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/project/validate.rs): Deep structural validation for tour projects. `#validation`

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
* [src/components/FloorNavigation.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/FloorNavigation.res): New module detected. Please classify. #new
* [src/components/UtilityBar.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/UtilityBar.res): New module detected. Please classify. #new
* [src/components/VisualPipeline/VisualPipelineLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/VisualPipeline/VisualPipelineLogic.res): New module detected. Please classify. #new
* [src/components/VisualPipeline/VisualPipelineMain.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/VisualPipeline/VisualPipelineMain.res): New module detected. Please classify. #new
* [src/components/VisualPipeline/VisualPipelineRender.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/VisualPipeline/VisualPipelineRender.res): New module detected. Please classify. #new
* [src/components/VisualPipeline/VisualPipelineStyles.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/VisualPipeline/VisualPipelineStyles.res): New module detected. Please classify. #new
* [src/components/VisualPipeline/VisualPipelineTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/VisualPipeline/VisualPipelineTypes.res): New module detected. Please classify. #new
* [src/components/VisualPipeline.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/VisualPipeline.res): New module detected. Please classify. #new
* [src/components/ui/Lucide/LucideActions.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/Lucide/LucideActions.res): New module detected. Please classify. #new
* [src/components/ui/Lucide/LucideCore.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/Lucide/LucideCore.res): New module detected. Please classify. #new
* [src/components/ui/Lucide/LucideMedia.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/Lucide/LucideMedia.res): New module detected. Please classify. #new
* [src/components/ui/Lucide/LucideStatus.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/Lucide/LucideStatus.res): New module detected. Please classify. #new
* [src/components/ui/LucideIcons.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ui/LucideIcons.res): New module detected. Please classify. #new

* [src/systems/Resizer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/Resizer.res): New module detected. Please classify. #new
* [src/systems/ResizerLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ResizerLogic.res): New module detected. Please classify. #new
* [src/systems/ResizerTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ResizerTypes.res): New module detected. Please classify. #new
* [src/systems/ResizerUtils.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ResizerUtils.res): New module detected. Please classify. #new
* [src/systems/TeaserRecorder.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserRecorder.res): New module detected. Please classify. #new
* [src/systems/TeaserRecorderLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserRecorderLogic.res): New module detected. Please classify. #new
* [src/systems/TeaserRecorderOverlay.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserRecorderOverlay.res): New module detected. Please classify. #new
* [src/systems/TeaserRecorderTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/TeaserRecorderTypes.res): New module detected. Please classify. #new
* [backend/src/api/geocoding.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/geocoding.rs): New module detected. Please classify. #new
* [backend/src/api/media/image/image_logic.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/image/image_logic.rs): New module detected. Please classify. #new
* [backend/src/api/media/image/image_utils.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/image/image_utils.rs): New module detected. Please classify. #new
* [backend/src/api/media/image/mod.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/image/mod.rs): New module detected. Please classify. #new
* [backend/src/services/upload_quota_tests.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/upload_quota_tests.rs): New module detected. Please classify. #new
* [src/bindings/IdbBindings.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/bindings/IdbBindings.res): New module detected. Please classify. #new
* [src/utils/PersistenceLayer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/utils/PersistenceLayer.res): New module detected. Please classify. #new
* [backend/src/services/media/naming_old.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/services/media/naming_old.rs): New module detected. Please classify. #new
