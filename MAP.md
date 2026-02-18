# 📂 Project Directory Tree

```
/ 
├── [src/](src/) – ReScript frontend (components, systems, hooks, utils, bindings, and FSMs).
│   ├── [components/](src/components/) – UI widgets and HUD overlays.
│   ├── [systems/](src/systems/) – Business logic, navigation, upload, and viewer orchestration.
│   ├── [core/](src/core/) – Immutable state, reducers, actions, helpers, and JSON parsers.
│   ├── [hooks/](src/hooks/) – Shared React hooks and policies.
│   ├── [utils/](src/utils/) – Persistence, logging, concurrency, and math utilities.
│   ├── [bindings/](src/bindings/) – Browser and viewer bindings.
│   ├── [i18n/](src/i18n/) – Internationalization resources.
│   └── [ReBindings.res](src/ReBindings.res), [Main.res](src/Main.res), and service worker entrypoints.
├── [public/](public/) – Static assets and manifest files for PWA deployment.
├── [css/](css/) – Tailwind CSS config, global styles, and generated artifacts.
├── [backend/](backend/) – Rust backend (Actix-web) with [src/](backend/src/) for API, services, and pathfinding.
├── [tests/](tests/) – Vitest unit suites and Playwright end-to-end tests.
├── [docs/](docs/) – Supplemental documentation, runbooks, and guides.
├── [scripts/](scripts/) – Automation helpers (lint, fast-commit, diagnostics).
├── [tasks/](tasks/) – Workflow definitions and pending/active/completed tasks.
├── [dist/](dist/) – Built artifacts.
├── [data/](data/) & [cache/](cache/) – Supporting datasets and caches.
└── [node_modules/](node_modules/) – Installed dependencies (generated).
```

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
*   [src/utils/Logger.res](src/utils/Logger.res): Lightweight facade for the unified logging and telemetry system. `#logging` `#telemetry` `#facade`
    * [src/utils/LoggerTelemetry.res](src/utils/LoggerTelemetry.res): Async telemetry batching and backend synchronization. `#telemetry`
    * [src/utils/LoggerConsole.res](src/utils/LoggerConsole.res): Console-specific logging output implementation. `#logging` `#console`
    * [src/utils/LoggerCommon.res](src/utils/LoggerCommon.res): Shared logging logic and timestamp formatting. `#logging` `#utils`
    * [src/utils/LoggerLogic.res](src/utils/LoggerLogic.res): Extracted logic for performance thresholds and error data enrichment. `#logging` `#logic`
*   [src/Hooks.res](src/Hooks.res): Common React hooks for throttled actions and interaction permissions. `#react` `#hooks`
*   [src/hooks/UseInteraction.res](src/hooks/UseInteraction.res): Specialized hook for managing interaction policies and feedback. `#react` `#hooks` `#interaction`
*   [src/utils/PerfUtils.res](src/utils/PerfUtils.res): React hook for monitoring component render budget and performance metrics. `#performance` `#react` `#hooks` `#telemetry`


### 🛡️ State Management & Logic
*   [src/core/State.res](src/core/State.res): Central application state definition. `#state` `#immutability`
*   [src/core/Reducer.res](src/core/Reducer.res): Root reducer orchestrating domain updates. `#reducer` `#action-dispatch`
*   [src/core/Actions.res](src/core/Actions.res): All supported user and system actions. `#actions` `#events`
*   [src/core/Types.res](src/core/Types.res): Global domain types and application-wide interfaces. `#types`
*   [src/core/SharedTypes.res](src/core/SharedTypes.res): Utility types shared across frontend and backend logic. `#types`
*   [src/core/ViewerTypes.res](src/core/ViewerTypes.res): Types specialized for 360 viewer state and configuration. `#viewer` `#types`
*   [src/core/ViewerState.res](src/core/ViewerState.res): Localized state for the active viewer instance. `#state` `#viewer`
*   [src/core/SceneCache.res](src/core/SceneCache.res): In-memory cache for processed scene assets and metadata. `#cache` `#performance`
*   [src/core/AppStateBridge.res](src/core/AppStateBridge.res): Canonical bridge for synchronizing global state/dispatch with non-React systems and readiness callbacks. `#state` `#sync` `#bridge`
*   [src/core/StateSnapshot.res](src/core/StateSnapshot.res): Manager for capturing and rolling back application state snapshots. `#state` `#rollback` `#reliability`
*   [src/core/OptimisticAction.res](src/core/OptimisticAction.res): Wrapper for executing actions optimistically with automatic rollback on failure. `#actions` `#optimistic-update` `#reliability`
*   [src/core/AppFSM.res](src/core/AppFSM.res): Global Finite State Machine orchestrating top-level application modes. `#fsm` `#state` `#architecture`
*   [src/core/NavigationState.res](src/core/NavigationState.res): Navigation domain state slice reducer (FSM/status/journey/auto-forward chain). `#state` `#navigation` `#reducer`
*   [src/i18n/I18n.res](src/i18n/I18n.res): Internationalization orchestrator for multi-language support. `#i18n` `#ui`
*   [src/core/Reducer.res](src/core/Reducer.res): Consolidated state reducer handling scenes, hotspots, navigation, and projects. `#reducer` `#logic`
    *   [src/core/ReducerModules.res](src/core/ReducerModules.res): Domain-specific reducer sub-modules for Scene, Hotspot, Ui, AppFsm, Simulation, and Timeline. `#reducer` `#logic` `#modular`
    *   [src/core/NavigationProjectReducer.res](src/core/NavigationProjectReducer.res): Cross-domain coordination reducers for Navigation and Project state handling. `#reducer` `#navigation` `#project`
    *   [src/core/SceneMutations.res](src/core/SceneMutations.res): Complex state mutation logic for scene renaming, deletion, and reordering. `#state` `#scene` `#logic`
    *   [src/core/SceneInventory.res](src/core/SceneInventory.res): Internal logic for scene collection and inventory management. `#state` `#inventory`
    *   [src/core/SceneNaming.res](src/core/SceneNaming.res): Specialized logic for unique scene name generation and collision detection. `#logic` `#naming`
    *   [src/core/SceneOperations.res](src/core/SceneOperations.res): Atomic operations for scene data manipulation. `#logic` `#operations`
*   [src/core/AppContext.res](src/core/AppContext.res): Typed React Context for state and dispatch accessibility. `#react-context` `#hooks`
*   [src/core/JsonParsers.res](src/core/JsonParsers.res): Facade for domain-specific JSON decoders and encoders. `#json` `#parsing` `#facade`
    *   [src/core/JsonParsersDecoders.res](src/core/JsonParsersDecoders.res): Domain-specific JSON decoders using rescript-json-combinators. `#json` `#parsing` `#decoding`
    *   [src/core/JsonParsersEncoders.res](src/core/JsonParsersEncoders.res): Domain-specific JSON encoders using rescript-json-combinators. `#json` `#encoding`
*   [src/core/JsonParsersShared.res](src/core/JsonParsersShared.res): Shared JSON parsers for cross-domain metadata (Exif, Quality). `#json` `#shared` `#parsing`
*   [src/core/JsonEncoders.res](src/core/JsonEncoders.res): Centralized JSON encoders using rescript-json-combinators for CSP compliance. `#json` `#encoding` `#csp`
*   [src/core/InteractionGuard.res](src/core/InteractionGuard.res): Cooldown and multi-click prevention for UI actions. `#concurrency` `#safety`
*   [src/core/InteractionPolicies.res](src/core/InteractionPolicies.res): Configuration for interaction cooldowns and limits. `#configuration` `#safety`
*   [src/core/NotificationManager.res](src/core/NotificationManager.res): Core logic for dispatching and managing notifications. `#logic` `#notifications`
*   [src/core/NotificationQueue.res](src/core/NotificationQueue.res): Queue management for sequential notification display. `#logic` `#queue`
*   [src/core/NotificationTypes.res](src/core/NotificationTypes.res): Type definitions for the notification system. `#types` `#notifications`

*   [src/core/SceneHelpers.res](src/core/SceneHelpers.res): Lightweight facade for scene-related helpers. `#helpers` `#scene` `#facade`

*   [src/core/UiHelpers.res](src/core/UiHelpers.res): Generic UI utilities, blob/file handling, and array manipulation. `#helpers` `#ui` `#utils`
*   [src/core/SimHelpers.res](src/core/SimHelpers.res): Simulation and timeline specific parsers and helpers. `#helpers` `#simulation`
*   [src/core/SimulationHelpers.res](src/core/SimulationHelpers.res): Advanced simulation waypoint and path helpers. `#helpers` `#simulation`
*   [src/core/NavigationHelpers.res](src/core/NavigationHelpers.res): Transition and target-aware navigation helpers. `#helpers` `#navigation`
*   [src/core/HotspotHelpers.res](src/core/HotspotHelpers.res): Hotspot placement and coordinate projection helpers. `#helpers` `#hotspots`
*   [src/core/HotspotTarget.res](src/core/HotspotTarget.res): Normalized matching logic and resolver for hotspot targets and scene linking. `#helpers` `#hotspots` `#linking`


### 🌐 System Layer (Business Logic)
*   [src/systems/UploadProcessor.res](src/systems/UploadProcessor.res): Consolidated orchestrator for image processing and upload pipeline. `#upload` `#orchestration` `#logic`
    *   [src/systems/UploadProcessorLogic.res](src/systems/UploadProcessorLogic.res): Core logic and state management for upload processing. `#upload` `#logic`
    *   [src/systems/Upload/UploadFinalizer.res](src/systems/Upload/UploadFinalizer.res): Logic for finalizing scene creation and state synchronization after upload. `#upload` `#lifecycle`
    *   [src/systems/Upload/UploadItemProcessor.res](src/systems/Upload/UploadItemProcessor.res): Transformation and resizing logic for individual upload items. `#upload` `#processing`
    *   [src/systems/Upload/UploadRecovery.res](src/systems/Upload/UploadRecovery.res): Logic for resuming interrupted uploads using the operation journal. `#upload` `#reliability`
    *   [src/systems/Upload/UploadReporting.res](src/systems/Upload/UploadReporting.res): Generation of batch upload reports and duplicate detection summaries. `#upload` `#reporting`
    *   [src/systems/Upload/UploadScanner.res](src/systems/Upload/UploadScanner.res): File scanning and MIME-type validation for batch imports. `#upload` `#validation`
    *   [src/systems/Upload/UploadUtils.res](src/systems/Upload/UploadUtils.res): Shared utilities for the upload pipeline. `#upload` `#utils`
*   [src/systems/UploadTypes.res](src/systems/UploadTypes.res): Types for upload processing system. `#types`

*   [src/systems/Scene.res](src/systems/Scene.res): Orchestrator for scene management, transitions, and loading. `#scene` `#orchestration`
    *   [src/systems/Scene/SceneLoader.res](src/systems/Scene/SceneLoader.res): Scene transition logic and viewer loading coordination. `#scene-loading` `#lifecycle`
    *   [src/systems/SceneLoaderLogic.res](src/systems/SceneLoaderLogic.res): Scene configuration and Pannellum setup logic for viewer initialization. `#scene-loading` `#logic`
    *   [src/systems/Scene/Loader/SceneLoaderConfig.res](src/systems/Scene/Loader/SceneLoaderConfig.res): Configuration factory for viewer instances and blank panoramas. `#scene-loading` `#config`
    *   [src/systems/Scene/Loader/SceneLoaderEvents.res](src/systems/Scene/Loader/SceneLoaderEvents.res): Handling of stage-level load/error events and task status. `#scene-loading` `#events`
    *   [src/systems/Scene/Loader/SceneLoaderReuse.res](src/systems/Scene/Loader/SceneLoaderReuse.res): Optimization logic for reusing existing viewer instances across transitions. `#scene-loading` `#performance`
    *   [src/systems/Scene/SceneTransition.res](src/systems/Scene/SceneTransition.res): DOM transitions and viewport swapping management. `#transition` `#dom`
    *   [src/systems/Scene/SceneSwitcher.res](src/systems/Scene/SceneSwitcher.res): High-level scene switching, journey initialization, and auto-forwarding. `#scene-switching`
*   [src/systems/ProjectSystem.res](src/systems/ProjectSystem.res): Project validation, loading, and post-processing orchestration. `#project` `#loading` `#validation`
*   [src/systems/HotspotLine.res](src/systems/HotspotLine.res): Orchestrator for visual hotspot connections and simulation arrows. `#hotspots` `#rendering` `#orchestration`
*   [src/core/interfaces/ViewerDriver.res](src/core/interfaces/ViewerDriver.res): Interface contract for 360 renderer drivers. `#interface` `#abstraction`
*   [src/systems/PannellumAdapter.res](src/systems/PannellumAdapter.res): Pannellum-specific implementation of ViewerDriver. `#adapter`
*   [src/systems/PannellumLifecycle.res](src/systems/PannellumLifecycle.res): Management of Pannellum instance creation and destruction. `#lifecycle` `#adapter`
*   [src/systems/ViewerSystem.res](src/systems/ViewerSystem.res): Unified viewer system orchestrator. `#viewer` `#orchestration`
    *   [src/systems/Viewer/ViewerAdapter.res](src/systems/Viewer/ViewerAdapter.res): Platform-agnostic adapter for the underlying 360 renderer. `#viewer` `#adapter`
    *   [src/systems/Viewer/ViewerPool.res](src/systems/Viewer/ViewerPool.res): Lifecycle management for the dual-viewport instance pool. `#viewer` `#performance`
    *   [src/systems/Viewer/ViewerFollow.res](src/systems/Viewer/ViewerFollow.res): Logic for synchronizing viewer orientations and animation frames. `#viewer` `#sync`
*   [src/systems/ViewerLogic.res](src/systems/ViewerLogic.res): Core logic for viewer interactions and state. `#viewer` `#logic`
*   [src/systems/ViewerPool.res](src/systems/ViewerPool.res): Manager for multiple viewport instances and their lifecycles. `#orchestration` `#efficiency`
*   [src/systems/HotspotLineLogic.res](src/systems/HotspotLineLogic.res): Orchestrator for coordinate projection and SVG drawing. `#math` `#rendering` `#orchestration`
    *   [src/systems/HotspotLine/HotspotLineDrawing.res](src/systems/HotspotLine/HotspotLineDrawing.res): Main logic for persistent lines and linking drafts. `#logic`
    *   [src/systems/HotspotLine/HotspotLineLogicArrow.res](src/systems/HotspotLine/HotspotLineLogicArrow.res): Specialized logic for simulation arrow rendering and animation. `#logic` `#animation`
    *   [src/systems/HotspotLine/HotspotLineState.res](src/systems/HotspotLine/HotspotLineState.res): Centralized state, types, and caches for the hotspot line system. `#types` `#state` `#caching`
    *   [src/systems/HotspotLine/HotspotLineUtils.res](src/systems/HotspotLine/HotspotLineUtils.res): Pure utility functions for path calculations and cache facades. `#utils`
*   [src/systems/Simulation.res](src/systems/Simulation.res): Core logic for autopilot simulations. `#simulation` `#autopilot`

*   [src/systems/Navigation.res](src/systems/Navigation.res): Orchestrator for the centralized navigation system. `#navigation` `#orchestration`
    *   [src/systems/Navigation/NavigationSupervisor.res](src/systems/Navigation/NavigationSupervisor.res): Centralized coordinator for scene transitions using structured concurrency with AbortSignal. `#navigation` `#orchestration` `#concurrency`
    *   [src/systems/Navigation/NavigationFSM.res](src/systems/Navigation/NavigationFSM.res): Pure deterministic Finite State Machine for navigation lifecycle. `#logic` `#reliability`
    *   [src/systems/Navigation/NavigationGraph.res](src/systems/Navigation/NavigationGraph.res): Viewport math and link projection logic. `#math` `#navigation`
    *   [src/systems/Navigation/NavigationRenderer.res](src/systems/Navigation/NavigationRenderer.res): Specialized renderer for interactive navigation elements. `#rendering`
    *   [src/systems/Navigation/NavigationUI.res](src/systems/Navigation/NavigationUI.res): UI-driven navigation logic and prompt management. `#ui` `#navigation`
    *   [src/systems/Navigation/NavigationController.res](src/systems/Navigation/NavigationController.res): React hooks and controller for navigation side effects. `#logic` `#controller`
*   [src/systems/NavigationLogic.res](src/systems/NavigationLogic.res): Core logic for navigation state transitions. `#navigation` `#logic`
*   [src/systems/Teaser.res](src/systems/Teaser.res): Teaser generation system. `#teaser` `#video`
*   [src/systems/TeaserLogic.res](src/systems/TeaserLogic.res): Core playback, recording orchestration, and cinematic movement logic for teasers. `#teaser` `#playback` `#logic`
*   [src/systems/TeaserPlayback.res](src/systems/TeaserPlayback.res): Extracted playback helpers for viewer readiness waits, pan animation, and shot transitions. `#teaser` `#playback` `#helpers`
*   [src/systems/TeaserStyleConfig.res](src/systems/TeaserStyleConfig.res): Style-specific teaser timing and camera offset configuration. `#teaser` `#config`

*   [src/systems/TeaserState.res](src/systems/TeaserState.res): State management for the teaser system. `#teaser` `#state`
*   [src/systems/TeaserManager.res](src/systems/TeaserManager.res): Manager for teaser recording and playback sessions. `#teaser` `#manager`
*   [src/systems/ProjectManager.res](src/systems/ProjectManager.res): Consolidated project save/load operations. `#persistence` `#save-load` `#consolidated`
    *   [src/systems/Project/ProjectLoader.res](src/systems/Project/ProjectLoader.res): Logic for importing and patching project data from ZIP archives. `#persistence` `#loading`
    *   [src/systems/Project/ProjectSaver.res](src/systems/Project/ProjectSaver.res): Logic for packaging and exporting tour data into ZIP files. `#persistence` `#saving`
    *   [src/systems/Project/ProjectValidator.res](src/systems/Project/ProjectValidator.res): Deep structural validation for tour projects and schemas. `#validation` `#project`
    *   [src/systems/ProjectManagerUrl.res](src/systems/ProjectManagerUrl.res): Specialized logic for rebuilding and validating tour URLs. `#persistence` `#url` `#logic`
*   [src/systems/Exporter.res](src/systems/Exporter.res): Generates production-ready tour clusters. `#export` `#deployment`
*   [src/systems/Api.res](src/systems/Api.res): Consolidated API module for media, projects, and authentication. `#api` `#client` `#consolidated`
*   [src/systems/ApiLogic.res](src/systems/ApiLogic.res): Orchestrator for API client logic and sub-modules. `#api` `#client` `#orchestration`
    *   [src/systems/Api/AuthenticatedClient.res](src/systems/Api/AuthenticatedClient.res): Fetch wrapper with token injection and error handling. `#api` `#auth` `#adapter`
    *   [src/systems/Api/MediaApi.res](src/systems/Api/MediaApi.res): Logic for media-related API operations (metadata, processing, similarity). `#api` `#media`
    *   [backend/src/api/media/image_tasks.rs](backend/src/api/media/image_tasks.rs): Backend processing tasks for multi-resolution images. `#api` `#processing`
    *   [backend/src/api/media/image_multipart.rs](backend/src/api/media/image_multipart.rs): Handling of large image uploads via multipart/form-data. `#api` `#upload`
    *   [backend/src/api/project_multipart.rs](backend/src/api/project_multipart.rs): Specialized multipart handling for project ZIP imports. `#api` `#project`

    *   [src/systems/Api/ProjectApi.res](src/systems/Api/ProjectApi.res): Logic for project-related API operations (import, save, pathfinding, geocode). `#api` `#project`
    *   [src/systems/ApiHelpers.res](src/systems/ApiHelpers.res): Shared helper functions and types for the API system. `#api` `#helpers`
*   [src/systems/FingerprintService.res](src/systems/FingerprintService.res): Image fingerprinting for deduplication. `#image` `#fingerprint`
*   [src/systems/PanoramaClusterer.res](src/systems/PanoramaClusterer.res): Logic for grouping and clustering panoramas. `#logic` `#clustering`
*   [src/systems/SvgManager.res](src/systems/SvgManager.res): Management of SVG overlays and elements. `#svg` `#rendering`
*   [src/systems/VideoEncoder.res](src/systems/VideoEncoder.res): Logic for encoding tour sequences into video. `#video` `#encoding`
*   [src/systems/Resizer.res](src/systems/Resizer.res): Orchestrator for client-side image resizing and analysis. `#processing` `#image` `#orchestration`
    *   [src/systems/Resizer/ResizerLogic.res](src/systems/Resizer/ResizerLogic.res): Core canvas-based resizing and response processing. `#logic`
    *   [src/systems/Resizer/ResizerTypes.res](src/systems/Resizer/ResizerTypes.res): Internal types for the resizing pipeline. `#types`
    *   [src/systems/Resizer/ResizerUtils.res](src/systems/Resizer/ResizerUtils.res): Shared utilities and memory reporting for resizing. `#utils`
*   [src/systems/TeaserRecorder.res](src/systems/TeaserRecorder.res): Consolidated teaser recording system (Logic, Overlay, Types). `#teaser` `#recording` `#consolidated`
*   [src/systems/DownloadSystem.res](src/systems/DownloadSystem.res): Management of asset downloading and caching. `#download` `#cache`
*   [src/systems/AudioManager.res](src/systems/AudioManager.res): Orchestrator for spatial audio and background soundscapes. `#audio` `#spatial-sound`
*   [src/systems/EventBus.res](src/systems/EventBus.res): Centralized pub/sub broker for decoupled system communication. `#events` `#orchestration`
*   [src/systems/InputSystem.res](src/systems/InputSystem.res): Unified handler for mouse, touch, and keyboard input. `#input` `#gestures`
*   [src/systems/CursorPhysics.res](src/systems/CursorPhysics.res): Physics-based cursor and interaction smoothing. `#physics` `#ux`
*   [src/systems/ExifParser.res](src/systems/ExifParser.res): Frontend-side EXIF data parsing and normalization. `#exif` `#parsing`
*   [src/systems/ExifReportGenerator.res](src/systems/ExifReportGenerator.res): Lightweight facade for EXIF report generation. `#exif` `#reporting` `#facade`
*   [src/systems/ExifReportGeneratorLogic.res](src/systems/ExifReportGeneratorLogic.res): Orchestrator for the main report generation logic. `#exif` `#orchestration`
    *   [src/systems/ExifReport/ExifReportGeneratorLogicExtraction.res](src/systems/ExifReport/ExifReportGeneratorLogicExtraction.res): EXIF data extraction from file batches. `#logic` `#extraction`
    *   [src/systems/ExifReport/ExifReportGeneratorLogicLocation.res](src/systems/ExifReport/ExifReportGeneratorLogicLocation.res): GPS analysis, centroid calculation, and geocoding. `#logic` `#geo`
    *   [src/systems/ExifReport/ExifReportGeneratorLogicGroups.res](src/systems/ExifReport/ExifReportGeneratorLogicGroups.res): Camera device grouping and file listing logic. `#logic`
    *   [src/systems/ExifReport/ExifReportGeneratorLogicTypes.res](src/systems/ExifReport/ExifReportGeneratorLogicTypes.res): Internal types for EXIF report analysis. `#types`
*   [src/systems/ExifUtils.res](src/systems/ExifUtils.res): Shared helper functions for EXIF data and geolocation. `#exif` `#helpers`
*   [src/systems/ImageValidator.res](src/systems/ImageValidator.res): Client-side validation of image formats and dimensions. `#image` `#validation`
*   [src/systems/Navigation/NavigationRenderer.res](src/systems/Navigation/NavigationRenderer.res): Specialized renderer for interactive navigation elements. `#rendering` `#navigation`
*   [src/systems/LinkEditorLogic.res](src/systems/LinkEditorLogic.res): Core logic for the visual link and hotspot editor. `#editor` `#logic`
*   [src/systems/SimulationLogic.res](src/systems/SimulationLogic.res): Orchestrator for advanced waypoint-based movement simulations. `#simulation` `#orchestration`
    *   [src/systems/Simulation/SimulationMainLogic.res](src/systems/Simulation/SimulationMainLogic.res): Core decision logic for simulation moves and actions. `#logic`
    *   [src/systems/Simulation/SimulationNavigation.res](src/systems/Simulation/SimulationNavigation.res): Navigation specialized for automated autopilot routes. `#navigation`
    *   [src/systems/Simulation/SimulationPathGenerator.res](src/systems/Simulation/SimulationPathGenerator.res): Algorithm for generating optimal paths between scenes. `#algorithms`
    *   [src/systems/Simulation/SimulationChainSkipper.res](src/systems/Simulation/SimulationChainSkipper.res): Optimization logic for skipping redundant simulation steps. `#optimization`
    *   [src/systems/Simulation/SimulationTypes.res](src/systems/Simulation/SimulationTypes.res): Internal types for the simulation logic. `#types`
*   [src/systems/TeaserPathfinder.res](src/systems/TeaserPathfinder.res): Specialized pathfinding for cinematic teaser sequences. `#teaser` `#pathfinding`
*   [src/systems/ServerTeaser.res](src/systems/ServerTeaser.res): Client-side bridge for server-side teaser generation requests. `#teaser` `#api`
*   [src/systems/ViewerFollow.res](src/systems/ViewerFollow.res): Logic for synchronizing viewer orientations across sessions. `#sync` `#viewer`

*   [src/systems/TourTemplates.res](src/systems/TourTemplates.res): Manager for visual tour templates and themes. `#branding` `#facade`

*   [src/systems/BackendApi.res](src/systems/BackendApi.res): Facade for the consolidated API module. `#api` `#client` `#facade`

### 🎨 Visual & UI Components
*   [src/components/ViewerUI.res](src/components/ViewerUI.res): High-level orchestrator for the viewer interface. `#ui` `#hud` `#orchestration`
*   [src/components/ViewerHUD.res](src/components/ViewerHUD.res): Primary overlay system (UtilityBar, FloorNav, Labels). `#ui` `#hud` `#overlays`
*   [src/components/FloorNavigation.res](src/components/FloorNavigation.res): Interactive floor and level switcher for the viewer HUD. `#ui` `#navigation`
*   [src/components/UtilityBar.res](src/components/UtilityBar.res): Top-level action bar for viewer tools and settings. `#ui` `#hud`
*   [src/components/VisualPipeline.res](src/components/VisualPipeline.res): Consolidated visualizer pipeline module. `#ui` `#visual-pipeline` `#logic` `#rendering`
    *   [src/components/VisualPipeline/VisualPipelineComponent.res](src/components/VisualPipeline/VisualPipelineComponent.res): Functional React component for the visualizer pipeline. `#ui` `#visual-pipeline`
    *   [src/components/VisualPipeline/VisualPipelineStyles.res](src/components/VisualPipeline/VisualPipelineStyles.res): CSS-in-JS definitions for the visual pipeline. `#styling`
    *   [src/components/VisualPipelineLogic.res](src/components/VisualPipelineLogic.res): Logic and utility functions for timeline item reordering and visual pipeline styling. `#logic` `#ui` `#timeline`
*   [src/components/SnapshotOverlay.res](src/components/SnapshotOverlay.res): Visual transition "flash" layer. `#ui` `#transition`
*   [src/components/NotificationCenter.res](src/components/NotificationCenter.res): High-level notification center UI orchestrator (Custom ReScript implementation). `#ui` `#notifications` `#custom-system`
*   [src/components/LockFeedback.res](src/components/LockFeedback.res): Visual feedback for transition locks and blocking states. `#ui` `#feedback`
*   [src/components/Sidebar.res](src/components/Sidebar.res): Consolidated sidebar module for project management and UI. `#sidebar` `#scene-management` `#ui` `#logic`
    * [src/components/Sidebar/SidebarLogic.res](src/components/Sidebar/SidebarLogic.res): Core sidebar logic and upload orchestration. `#logic`
    * [src/components/Sidebar/SidebarProjectInfo.res](src/components/Sidebar/SidebarProjectInfo.res): UI for tour name and upload triggers. `#ui`
    * [src/components/Sidebar/SidebarProcessing.res](src/components/Sidebar/SidebarProcessing.res): Global processing status and progress tracking. `#ui` `#notifications`
    * [src/components/Sidebar/SidebarAbout.res](src/components/Sidebar/SidebarAbout.res): Modal and information about the application. `#ui` `#about`
    * [src/components/Sidebar/UseSidebarProcessing.res](src/components/Sidebar/UseSidebarProcessing.res): Reactive hook for tracking processing state within the sidebar. `#hooks` `#processing`
    * [src/components/Sidebar/SidebarBranding.res](src/components/Sidebar/SidebarBranding.res): Application branding and version information. `#ui`
    * [src/components/Sidebar/SidebarActions.res](src/components/Sidebar/SidebarActions.res): Primary toolbar for project operations. `#ui`
*   [src/components/SceneList.res](src/components/SceneList.res): Virtualized list of tour scenes. `#ui` `#virtualization` `#facade`
    *   [src/components/SceneList/SceneItem.res](src/components/SceneList/SceneItem.res): Individual scene item component. `#ui`
*   [src/components/HotspotManager.res](src/components/HotspotManager.res): Visual editor for placement and editing of nav links. `#hotspots` `#editor`
*   [src/components/AppErrorBoundary.res](src/components/AppErrorBoundary.res): Top-level safety net for render failures. `#error-handling` `#stability`
*   [src/components/CriticalErrorMonitor.res](src/components/CriticalErrorMonitor.res): Monitor for capturing and reporting critical application errors. `#error-handling` `#monitoring`
*   [src/components/ErrorFallbackUI.res](src/components/ErrorFallbackUI.res): Visual fallback for caught rendering errors. `#ui` `#error-handling`
*   [src/components/HotspotActionMenu.res](src/components/HotspotActionMenu.res): Contextual menu for hotspot-specific actions. `#ui` `#hotspots`
*   [src/components/HotspotLayer.res](src/components/HotspotLayer.res): Interactive SVG/DOM layer for hotspot rendering. `#ui` `#rendering` `#hotspots`
*   [src/components/HotspotMenuLayer.res](src/components/HotspotMenuLayer.res): Dedicated layer for hotspot-related context menus. `#ui` `#overlays`
*   [src/components/LabelMenu.res](src/components/LabelMenu.res): Interface for adding and editing persistent labels. `#ui` `#labels`
*   [src/components/LinkModal.res](src/components/LinkModal.res): Modal for configuring inter-scene navigation links. `#ui` `#navigation` `#modal`
*   [src/components/ModalContext.res](src/components/ModalContext.res): Context provider for managing application-wide modals. `#state` `#ui` `#modal`
*   [src/components/PersistentLabel.res](src/components/PersistentLabel.res): Visual representation of fixed spatial labels in the viewer. `#ui` `#labels`
*   [src/components/PopOver.res](src/components/PopOver.res): Generic popup/hover overlay component. `#ui` `#popover`
*   [src/components/Portal.res](src/components/Portal.res): React portal utility for detached DOM rendering. `#ui` `#dom`
*   [src/components/PreviewArrow.res](src/components/PreviewArrow.res): Visual indicator for navigation previews. `#ui` `#navigation`
*   [src/components/QualityIndicator.res](src/components/QualityIndicator.res): Visual badge for image quality scores. `#ui` `#quality`
*   [src/components/RecoveryPrompt.res](src/components/RecoveryPrompt.res): UI component for displaying interrupted operations and recovery options. `#ui` `#recovery` `#persistence`
*   [src/components/RecoveryCheck.res](src/components/RecoveryCheck.res): Headless recovery orchestrator that checks for interrupted operations on startup. `#ui` `#recovery` `#persistence` `#orchestration`
*   [src/components/ReturnPrompt.res](src/components/ReturnPrompt.res): Confirmation dialog for unsaved changes or exits. `#ui` `#dialog`
*   [src/components/Tooltip.res](src/components/Tooltip.res): Accessible and styled hover tooltips. `#ui` `#accessibility`
*   [src/components/UploadReport.res](src/components/UploadReport.res): Detailed report UI for batch upload results. `#ui` `#reporting` `#upload`
*   [src/components/ViewerLabelMenu.res](src/components/ViewerLabelMenu.res): Label management interface specialized for the viewer HUD. `#ui` `#hud`
*   [src/components/ViewerLoader.res](src/components/ViewerLoader.res): Loading state and splash screen for the 360 viewer. `#ui` `#loading`
*   [src/components/ViewerManager.res](src/components/ViewerManager.res): Lightweight facade orchestrating viewer logic. `#rendering` `#orchestration` `#facade`
    *   [src/components/ViewerManagerLogic.res](src/components/ViewerManagerLogic.res): Core logic hooks for viewer initialization, scene loading, and sync. `#logic` `#hooks`
    *   [src/components/ViewerManager/ViewerManagerLifecycle.res](src/components/ViewerManager/ViewerManagerLifecycle.res): Lifecycle hooks for stage events and global UI state. `#logic` `#hooks`
*   [src/components/ViewerSnapshot.res](src/components/ViewerSnapshot.res): UI for triggering and managing viewer captures. `#ui` `#snapshot`
### 🪝 React Hooks

*   [src/utils/PersistenceLayer.res](src/utils/PersistenceLayer.res): Advanced persistence layer with IndexedDB and session fallback. `#utils` `#storage` `#indexeddb`
*   [src/utils/OperationJournal.res](src/utils/OperationJournal.res): Persistent journal for tracking long-running operations and recovery. `#utils` `#persistence` `#journal`
    *   [src/utils/OperationJournal/JournalLogic.res](src/utils/OperationJournal/JournalLogic.res): Core logic for journal entry management and state transitions. `#logic` `#reliability`
    *   [src/utils/OperationJournal/JournalPersistence.res](src/utils/OperationJournal/JournalPersistence.res): Logic for synchronizing the journal with local storage. `#persistence`
    *   [src/utils/OperationJournal/JournalTypes.res](src/utils/OperationJournal/JournalTypes.res): Type definitions and encoders/decoders for the journal system. `#types` `#json`
*   [src/utils/RecoveryManager.res](src/utils/RecoveryManager.res): Orchestrator for operation recovery handlers and retry logic. `#recovery` `#persistence` `#orchestration`
*   [src/utils/SessionStore.res](src/utils/SessionStore.res): Session-based storage and state persistence. `#utils` `#storage`
*   [src/utils/RequestQueue.res](src/utils/RequestQueue.res): Queue management for network requests. `#utils` `#network`
*   [src/utils/LazyLoad.res](src/utils/LazyLoad.res): Helpers for lazy loading components and assets. `#utils` `#performance`
*   [src/utils/ProjectionMath.res](src/utils/ProjectionMath.res): Mathematical utilities for 3D/2D projection. `#utils` `#math`
*   [src/utils/ColorPalette.res](src/utils/ColorPalette.res): UI color system and palette definitions. `#utils` `#styling`
*   [src/utils/Constants.res](src/utils/Constants.res): Centralized application constants and configuration. `#utils` `#config`
*   [src/utils/GeoUtils.res](src/utils/GeoUtils.res): Geospatial calculation utilities for tour locations. `#utils` `#geo`
*   [src/utils/ImageOptimizer.res](src/utils/ImageOptimizer.res): Client-side image optimization and compression helpers. `#utils` `#image`
*   [src/utils/PathInterpolation.res](src/utils/PathInterpolation.res): Smooth path interpolation for cinematic movements. `#utils` `#math`
*   [src/utils/Easing.res](src/utils/Easing.res): Premium easing functions for smooth cinematic transitions. `#utils` `#math` `#animation`
*   [src/utils/ProgressBar.res](src/utils/ProgressBar.res): Logic for managing multi-step progress indicators. `#utils` `#ui`
*   [src/utils/StateInspector.res](src/utils/StateInspector.res): Debug utilities for inspecting the application state tree. `#utils` `#debug`
*   [src/utils/StateDensityMonitor.res](src/utils/StateDensityMonitor.res): Development-time state density scoring and threshold telemetry for architecture guardrails. `#utils` `#state` `#telemetry`
*   [src/utils/TourLogic.res](src/utils/TourLogic.res): Core domain logic for tour structure and state validation. `#utils` `#logic`
*   [src/utils/UrlUtils.res](src/utils/UrlUtils.res): Utilities for parsing and generating tour URLs. `#utils` `#url`
*   [src/utils/Version.res](src/utils/Version.res): Semantic versioning and build manifest utilities. `#utils` `#version`
*   [src/utils/NetworkStatus.res](src/utils/NetworkStatus.res): Centralized authority for monitoring online/offline state and dispatching connectivity events. `#utils` `#network` `#resilience`

### 🧪 Performance Governance
*   [tests/e2e/perf-budgets.spec.ts](tests/e2e/perf-budgets.spec.ts): CI budget gate suite for rapid navigation latency, bulk upload throughput, long-task counts, and memory growth during long simulation sessions. `#e2e` `#performance` `#budgets`
*   [docs/NETWORK_RESILIENCE.md](docs/NETWORK_RESILIENCE.md): Architectural guide for network hardening, offline handling, and crash recovery. `#docs` `#architecture` `#resilience`
*   [scripts/check-bundle-budgets.mjs](scripts/check-bundle-budgets.mjs): Enforces production bundle budgets (total JS, gzip size, and largest chunk). `#ci` `#performance` `#bundle-budget`
*   [scripts/check-runtime-budgets.mjs](scripts/check-runtime-budgets.mjs): Enforces runtime budgets from Playwright perf metrics artifacts. `#ci` `#performance` `#runtime-budget`
*   [docs/_pending_integration/enterprise_reliability_performance_runbook.md](docs/_pending_integration/enterprise_reliability_performance_runbook.md): Operational runbook with budget thresholds, verification commands, and SLO alignment evidence against Task 1349 baseline. `#docs` `#runbook` `#performance`
*   [src/utils/AsyncQueue.res](src/utils/AsyncQueue.res): Generic asynchronous queue with concurrency control and progress reporting. `#utils` `#concurrency`
*   [src/utils/CircuitBreaker.res](src/utils/CircuitBreaker.res): Circuit breaker pattern for backend API calls. `#utils` `#resiliency`
*   [src/utils/Debounce.res](src/utils/Debounce.res): Utility for debouncing and throttling promise-based functions. `#utils` `#concurrency`
*   [src/utils/RateLimiter.res](src/utils/RateLimiter.res): Sliding window rate limiter for user actions. `#utils` `#rate-limiting`
*   [src/utils/Retry.res](src/utils/Retry.res): Utility for retrying async operations with exponential backoff and jitter. `#utils` `#reliability` `#async`

### ⚙️ Backend API (Rust)
*   [backend/src/main.rs](backend/src/main.rs): Server entry point and high-level orchestration. `#rust` `#api` `#server` `#entry-point`
*   [backend/src/api/project.rs](backend/src/api/project.rs): Endpoints for project packaging, imports, and validation. `#backend-logic` `#project-api`
*   [backend/src/api/geocoding.rs](backend/src/api/geocoding.rs): API endpoints for address lookup and coordinate resolution. `#rust` `#api` `#geocoding`
*   [backend/src/api/media/image.rs](backend/src/api/media/image.rs): Consolidated image processing endpoints and optimization logic. `#image` `#api` `#processing`
*   [backend/src/api/media/video.rs](backend/src/api/media/video.rs): Consolidated video transcoding and teaser generation endpoints. `#video` `#api` `#teaser`
*   [backend/src/api/project_logic.rs](backend/src/api/project_logic.rs): Detailed logic for project packaging and import. `#logic`
*   [backend/src/api/media/image_logic.rs](backend/src/api/media/image_logic.rs): Logic for image processing operations. `#image` `#logic`
*   [backend/src/api/media/video_logic.rs](backend/src/api/media/video_logic.rs): Orchestrator for teaser generation and transcoding flows. `#video` `#logic` `#orchestration`
*   [backend/src/api/media/video_logic_support.rs](backend/src/api/media/video_logic_support.rs): Extracted helper module for headless hydration payloads, readiness polling, and ffmpeg process guards. `#video` `#helpers`
*   [backend/src/services/media/mod.rs](backend/src/services/media/mod.rs): Facade for core media services (encoding, analysis, resizing). `#media` `#services` `#facade`
*   [backend/src/services/media/analysis.rs](backend/src/services/media/analysis.rs): Aggregated media analysis functionality. `#media` `#analysis`
*   [backend/src/services/media/analysis_quality.rs](backend/src/services/media/analysis_quality.rs): Image quality assessment logic. `#media` `#quality`
*   [backend/src/services/media/analysis_exif.rs](backend/src/services/media/analysis_exif.rs): EXIF metadata extraction logic. `#media` `#exif`

    *   [backend/src/services/media/analysis_exif.rs](backend/src/services/media/analysis_exif.rs): EXIF data parsing and normalization logic. `#exif` `#parsing`
    *   [backend/src/services/media/analysis_quality.rs](backend/src/services/media/analysis_quality.rs): Image quality analysis, histograms, and blur detection. `#image-processing` `#logic`
    *   [backend/src/services/media/webp.rs](backend/src/services/media/webp.rs): WebP encoding and metadata injection. `#encoding`
    *   [backend/src/services/media/resizing.rs](backend/src/services/media/resizing.rs): High-performance image resizing. `#processing`
    *   [backend/src/services/media/naming.rs](backend/src/services/media/naming.rs): Camera filename normalization logic. `#utils`
    *   [backend/src/services/media/storage.rs](backend/src/services/media/storage.rs): Persistent storage and retrieval of media assets. `#media` `#storage`
*   [backend/src/api/mod.rs](backend/src/api/mod.rs): API route configuration and root interface for the backend REST API. `#api` `#orchestration`
*   [backend/src/api/media/mod.rs](backend/src/api/media/mod.rs): Sub-router for media processing and retrieval. `#api` `#media`
    *   [backend/src/api/media/serve.rs](backend/src/api/media/serve.rs): Handles direct asset serving and static delivery. `#api` `#static`
    *   [backend/src/api/media/similarity.rs](backend/src/api/media/similarity.rs): Endpoint for image similarity and visual clustering. `#api` `#ai`
*   [backend/src/api/project.rs](backend/src/api/project.rs): Endpoints for project packaging, imports, pathfinding, and validation. `#backend-logic` `#project-api`
*   [backend/src/api/telemetry.rs](backend/src/api/telemetry.rs): Endpoint for receiving client-side telemetry and logs. `#api` `#telemetry`
*   [backend/src/api/utils.rs](backend/src/api/utils.rs): Shared logic for API response formatting and errors. `#api` `#utils`
*   [backend/src/auth.rs](backend/src/auth.rs): Auth service orchestrator and Google OAuth logic. `#auth` `#orchestration`


### 🛡️ Backend Core & Services
*   [backend/src/lib.rs](backend/src/lib.rs): Shared library code and trait definitions for the backend. `#rust` `#core`
*   [backend/src/metrics.rs](backend/src/metrics.rs): Prometheus metrics collection and instrumentation. `#monitoring` `#telemetry`
*   [backend/src/middleware.rs](backend/src/middleware.rs): Centralized Actix-web middleware collection (Auth, Quota, Request Tracker). `#mw`
*   [backend/src/models.rs](backend/src/models.rs): Aggregated model facade for shared backend types and error contracts. `#types` `#models` `#facade`
*   [backend/src/models_common.rs](backend/src/models_common.rs): Shared backend DTO/data structs for geocoding, metadata, similarity, and telemetry payloads. `#types` `#models` `#shared`
*   [backend/src/models_identity.rs](backend/src/models_identity.rs): User and auth persistence models with query helpers. `#types` `#models` `#auth`
*   [backend/src/models_project_session.rs](backend/src/models_project_session.rs): Project/session persistence models and create helpers. `#types` `#models` `#project`

*   [backend/src/pathfinder.rs](backend/src/pathfinder.rs): Orchestrator for high-performance navigation pathfinding logic. `#navigation` `#orchestration`
    *   [backend/src/pathfinder/graph.rs](backend/src/pathfinder/graph.rs): Data models and types for the pathfinding graph. `#navigation` `#models`
    *   [backend/src/pathfinder/utils.rs](backend/src/pathfinder/utils.rs): Shared utilities for scene indexing and view calculations. `#navigation` `#utils`
    *   [backend/src/pathfinder/timeline.rs](backend/src/pathfinder/timeline.rs): Logic for calculating guided paths based on timelines. `#navigation` `#logic`
    *   [backend/src/pathfinder/walk.rs](backend/src/pathfinder/walk.rs): Logic for calculating exploratory walk paths. `#navigation` `#logic`
    *   [backend/src/pathfinder/algorithms.rs](backend/src/pathfinder/algorithms.rs): High-level pathfinding algorithm selection. `#navigation` `#algorithms`
*   [backend/src/services/geocoding/mod.rs](backend/src/services/geocoding/mod.rs): Facade for the geocoding service with OSM integration. `#geocoding` `#services` `#facade`
    *   [backend/src/services/geocoding/osm.rs](backend/src/services/geocoding/osm.rs): OpenStreetMap Nominatim API client driver. `#geocoding` `#adapter`
    *   [backend/src/services/geocoding/cache.rs](backend/src/services/geocoding/cache.rs): LRU persistent cache for geocoding results. `#geocoding` `#cache`

*   [backend/src/services/mod.rs](backend/src/services/mod.rs): Domain-specific service layer entry point. `#services`
    *   [backend/src/services/database.rs](backend/src/services/database.rs): Persistence layer for project metadata and users. `#database` `#logic`
    *   [backend/src/services/shutdown.rs](backend/src/services/shutdown.rs): Managed graceful shutdown orchestration. `#lifecycle`
    *   [backend/src/services/upload_quota.rs](backend/src/services/upload_quota.rs): Rate-limiting and quota management logic. `#quota` `#logic`
    *   [backend/src/services/upload_quota_tests.rs](backend/src/services/upload_quota_tests.rs): Integration tests for the quota enforcement system. `#rust` `#testing`
*   [backend/src/services/project/mod.rs](backend/src/services/project/mod.rs): Core services for heavy project operations. `#services` `#project`
    *   [backend/src/services/project/load.rs](backend/src/services/project/load.rs): High-efficiency project loading and patching. `#logic`
    *   [backend/src/services/project/package.rs](backend/src/services/project/package.rs): ZIP packaging and tour assembly logic. `#logic` `#export`
    *   [backend/src/services/project/validate.rs](backend/src/services/project/validate.rs): Deep structural validation for tour projects. `#validation`
*   [backend/src/startup.rs](backend/src/startup.rs): Consolidated server startup orchestration (Logging, CORS, Security). `#startup` `#logging` `#config` `#consolidated`
*   [backend/src/services/media/mod.rs](backend/src/services/media/mod.rs): Facade for core media services (encoding, analysis, resizing). `#media` `#services` `#facade`


## 🧪 Test Suite

### 🧩 Unit Tests (Key Examples)
* [tests/unit/ExifUtils_v.test.res](tests/unit/ExifUtils_v.test.res): Tests for EXIF utilities and report generation helpers. `#testing` `#unit` `#exif`
* [tests/unit/Simulation_v.test.res](tests/unit/Simulation_v.test.res): Tests for the simulation component and logic. `#testing` `#unit` `#simulation`
* [tests/unit/SvgManager_v.test.res](tests/unit/SvgManager_v.test.res): Tests for SVG rendering and management. `#testing` `#unit` `#svg`

### 🎭 End-to-End (Playwright)
* [tests/e2e/robustness.spec.ts](tests/e2e/robustness.spec.ts): Stress tests for concurrency, state transitions, and recovery. `#testing` `#e2e` `#robustness`
* [tests/e2e/upload-link-export-workflow.spec.ts](tests/e2e/upload-link-export-workflow.spec.ts): Full user journey from image upload to project export. `#testing` `#e2e` `#workflow`
* [tests/e2e/save-load-recovery.spec.ts](tests/e2e/save-load-recovery.spec.ts): Verification of project persistence and state restoration. `#testing` `#e2e` `#persistence`
* [tests/e2e/simulation-teaser.spec.ts](tests/e2e/simulation-teaser.spec.ts): Validation of autopilot simulation and teaser recording. `#testing` `#e2e` `#simulation` `#teaser`
* [tests/e2e/error-recovery.spec.ts](tests/e2e/error-recovery.spec.ts): Testing of error handling and network resilience scenarios. `#testing` `#e2e` `#recovery`
* [tests/e2e/optimistic-rollback.spec.ts](tests/e2e/optimistic-rollback.spec.ts): Validation of optimistic update rollback on API failure. `#testing` `#e2e` `#recovery`
* [tests/e2e/operation-recovery.spec.ts](tests/e2e/operation-recovery.spec.ts): Verification of interrupted operation recovery prompt. `#testing` `#e2e` `#recovery`
* [tests/e2e/performance.spec.ts](tests/e2e/performance.spec.ts): Load testing with 200+ scenes and memory leak detection. `#testing` `#e2e` `#performance`
* [tests/e2e/feature-deep-dive.spec.ts](tests/e2e/feature-deep-dive.spec.ts): Deep dive into advanced editor features and UI components. `#testing` `#e2e` `#features`
* [tests/e2e/visual-regression.spec.ts](tests/e2e/visual-regression.spec.ts): Visual regression and screenshot comparison suite. `#testing` `#e2e` `#visual`
* [tests/e2e/ai-helper.ts](tests/e2e/ai-helper.ts): Diagnostic helper for AI-observable E2E testing. `#testing` `#utils` `#ai`

*(None currently - all detected modules have been classified and integrated.)*

## 🆕 Unmapped Modules
* [src/systems/Exporter/ExporterUtils.res](src/systems/Exporter/ExporterUtils.res): New module detected. Please classify. #new
* [src/systems/Exporter/ExporterUpload.res](src/systems/Exporter/ExporterUpload.res): New module detected. Please classify. #new
* [src/systems/TourTemplates/TourStyles.res](src/systems/TourTemplates/TourStyles.res): New module detected. Please classify. #new
* [src/systems/TourTemplates/TourData.res](src/systems/TourTemplates/TourData.res): New module detected. Please classify. #new
* [src/systems/TourTemplates/TourScripts.res](src/systems/TourTemplates/TourScripts.res): New module detected. Please classify. #new
* [src/systems/TourTemplates/TourAssets.res](src/systems/TourTemplates/TourAssets.res): New module detected. Please classify. #new
* [src/systems/ProjectManager/ProjectSave.res](src/systems/ProjectManager/ProjectSave.res): New module detected. Please classify. #new
* [src/systems/ProjectManager/ProjectRecovery.res](src/systems/ProjectManager/ProjectRecovery.res): New module detected. Please classify. #new
* [src/systems/ProjectManager/ProjectUtils.res](src/systems/ProjectManager/ProjectUtils.res): New module detected. Please classify. #new
* [backend/src/api/health.rs](backend/src/api/health.rs): New module detected. Please classify. #new
