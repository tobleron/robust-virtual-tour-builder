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
*   [src/systems/HotspotLineLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/HotspotLineLogic.res): Coordinate projection math and SVG drawing primitives. `#math` `#rendering` `#logic`
*   [src/systems/SimulationDriver.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SimulationDriver.res): Logic for Autopilot and route simulations. `#autopilot` `#simulation` `#navigation`
*   [src/systems/NavigationController.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationController.res): Manages movement between scenes. `#navigation` `#scene-switching`
*   [src/systems/NavigationGraph.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationGraph.res): Graph data structure and BFS pathfinding for scene navigation. `#navigation` `#graph` `#pathfinding`
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
| `scripts` | Automation, setup, and maintenance tools. | `#automation` `#scripts` `#ci` |