# 📂 Project Directory Tree

```
/
├── [src/](src/) – ReScript frontend (components, systems, core state, utils).
├── [backend/](backend/) – Rust backend (Actix-web) with API/services/pathfinding.
├── [public/](public/) – Static assets and web app manifest files.
├── [css/](css/) – Tailwind and style assets.
├── [tests/](tests/) – Vitest and Playwright tests.
├── [cypress/](cypress/) – Cypress test assets and specs.
├── [docs/](docs/) – Documentation and runbooks.
├── [scripts/](scripts/) – Build/test/dev automation.
├── [tasks/](tasks/) – Task workflow files.
├── [dist/](dist/) – Build artifacts.
├── [dist-portal/](dist-portal/) – Portal build artifacts.
├── [data/](data/) – Supporting datasets.
├── [cache/](cache/) – Generated cache data.
├── [node_modules/](node_modules/) – Installed dependencies.
└── [_dev-system/](./_dev-system/) – Analyzer, config, and dev-task generation.
```

# 🗺️ Robust Virtual Tour Builder - Orchestrator Map

This map is intentionally compact. It lists high-signal entrypoints, orchestrators, and facades so agents can quickly locate control flow. Leaf/helper modules are discovered on demand from these anchors.

---

## 🚀 Entrypoints
* [src/Main.res](src/Main.res): Frontend bootstrap, app initialization, root mounting. `#entry-point`
* [src/index.js](src/index.js): React web entrypoint. `#entry-point`
* [src/App.res](src/App.res): Top-level UI shell and composition root. `#orchestrator`
* [backend/src/main.rs](backend/src/main.rs): Backend server bootstrap. `#entry-point`
* [backend/src/startup.rs](backend/src/startup.rs): Backend wiring, middleware, route registration. `#orchestrator`

## 🧠 Core State Orchestrators
* [src/core/Reducer.res](src/core/Reducer.res): Composite reducer coordinating domain reducers. `#state` `#orchestrator`
* [src/core/AppFSM.res](src/core/AppFSM.res): Global app lifecycle FSM. `#fsm` `#orchestrator`
* [src/core/NavigationState.res](src/core/NavigationState.res): Navigation domain state transitions and journey state. `#state`
* [src/core/AppContext.res](src/core/AppContext.res): Global state/dispatch provider boundary. `#context`
* [src/core/AppStateBridge.res](src/core/AppStateBridge.res): Bridge between React and non-React systems. `#bridge`

## 🌐 Frontend System Orchestrators
* [src/systems/Navigation.res](src/systems/Navigation.res): Centralized navigation orchestration entry. `#navigation` `#orchestrator`
* [src/systems/Scene.res](src/systems/Scene.res): Scene switching/load orchestration. `#scene` `#orchestrator`
* [src/systems/ViewerSystem.res](src/systems/ViewerSystem.res): Viewer lifecycle orchestration. `#viewer` `#orchestrator`
* [src/systems/UploadProcessor.res](src/systems/UploadProcessor.res): Upload pipeline orchestrator. `#upload` `#orchestrator`
* [src/systems/ProjectSystem.res](src/systems/ProjectSystem.res): Project load/validation orchestration. `#project` `#orchestrator`
* [src/systems/ProjectManager.res](src/systems/ProjectManager.res): Save/load persistence orchestration. `#project` `#orchestrator`
* [src/systems/Exporter.res](src/systems/Exporter.res): Export assembly and delivery orchestration. `#export` `#orchestrator`
* [src/systems/Simulation.res](src/systems/Simulation.res): Autopilot simulation orchestration. `#simulation`
* [src/systems/SimulationLogic.res](src/systems/SimulationLogic.res): Main simulation orchestration logic for generated movement paths. `#simulation` `#orchestrator`
* [src/systems/SimulationDriverRuntimeSupport.res](src/systems/SimulationDriverRuntimeSupport.res): Simulation driver helper routines for transition planning and runtime advancement support. `#simulation` `#service`
* [src/systems/TeaserManager.res](src/systems/TeaserManager.res): Teaser session orchestration entry. `#teaser` `#orchestrator`
* [src/systems/TeaserLogic.res](src/systems/TeaserLogic.res): Teaser logic façade coordinating playback/render submodules. `#teaser`
* [src/systems/TeaserHeadlessLogicSupport.res](src/systems/TeaserHeadlessLogicSupport.res): Headless teaser capture helper routines for viewer sizing, branding assets, and export runtime setup. `#teaser` `#service`
* [src/systems/TourTemplates.res](src/systems/TourTemplates.res): Exported tour script/style orchestration. `#templates` `#orchestrator`
* [src/site/PortalApp.res](src/site/PortalApp.res): Portal route selection and top-level bootstrap orchestration. `#site` `#orchestrator`
* [src/site/PortalAppCore.res](src/site/PortalAppCore.res): Portal route parsing, shared date helpers, and portal URL helpers. `#site` `#service`
* [src/site/PortalAppUI.res](src/site/PortalAppUI.res): Portal branding, copy actions, and shared UI helper components. `#site` `#ui`
* [src/site/PortalAppAdminSurface.res](src/site/PortalAppAdminSurface.res): Portal administration workspace and recipient/tour management surface. `#site` `#ui`
* [src/site/PortalAppCustomerSurface.res](src/site/PortalAppCustomerSurface.res): Portal customer gallery and tour viewer surface. `#site` `#ui`
* [src/site/PageFramework.js](src/site/PageFramework.js): Static site/dashboard page orchestration entry. `#site` `#orchestrator`
* [src/systems/Api.res](src/systems/Api.res): API façade entrypoint for backend calls. `#api` `#facade`
* [src/systems/ApiLogic.res](src/systems/ApiLogic.res): API orchestration logic and transport routing. `#api` `#orchestrator`
* [src/systems/EventBus.res](src/systems/EventBus.res): Cross-system event orchestration channel. `#events`
* [src/systems/OperationLifecycle.res](src/systems/OperationLifecycle.res): Unified long-running operation lifecycle manager. `#operations` `#orchestrator`
* [src/systems/HotspotLineLogic.res](src/systems/HotspotLineLogic.res): Hotspot line rendering orchestration for navigation overlays. `#hotspots` `#orchestrator`
* [src/systems/Resizer.res](src/systems/Resizer.res): Image resize workflow orchestration entry for upload preprocessing. `#processing` `#orchestrator`
* [src/systems/ExifReportGeneratorLogic.res](src/systems/ExifReportGeneratorLogic.res): EXIF reporting orchestration for grouped extraction and report assembly. `#exif` `#orchestrator`

## 🧩 UI Orchestrators
* [src/components/Sidebar.res](src/components/Sidebar.res): Sidebar composition root for project operations. `#ui` `#orchestrator`
* [src/components/Sidebar/SidebarLogic.res](src/components/Sidebar/SidebarLogic.res): Sidebar orchestration and action wiring. `#ui` `#logic`
* [src/components/Sidebar/SidebarLogicHandler.res](src/components/Sidebar/SidebarLogicHandler.res): Sidebar action dispatcher boundary. `#ui` `#orchestrator`
* [src/components/ViewerUI.res](src/components/ViewerUI.res): Viewer-level UI composition root. `#ui` `#orchestrator`
* [src/components/ViewerHUD.res](src/components/ViewerHUD.res): HUD orchestration for controls and overlays. `#ui`
* [src/components/ViewerManager.res](src/components/ViewerManager.res): Viewer integration façade and lifecycle orchestration. `#viewer` `#orchestrator`
* [src/components/VisualPipeline.res](src/components/VisualPipeline.res): Visual pipeline orchestration facade. `#ui` `#orchestrator`

## 🔧 Frontend Facades / Boundaries
* [src/ReBindings.res](src/ReBindings.res): External bindings façade. `#bindings`
* [src/core/JsonParsers.res](src/core/JsonParsers.res): JSON decode/encode façade boundary. `#json`
* [src/utils/Logger.res](src/utils/Logger.res): Logging façade boundary. `#telemetry`
* [src/utils/LoggerLogic.res](src/utils/LoggerLogic.res): Logger entry construction and buffer management helpers. `#telemetry` `#service`
* [src/utils/LoggerPerf.res](src/utils/LoggerPerf.res): Logger performance timing and threshold helpers. `#telemetry` `#service`
* [src/utils/LoggerDiagnostics.res](src/utils/LoggerDiagnostics.res): Logger diagnostics and global observer helpers. `#telemetry` `#service`
* [src/utils/AsyncQueue.res](src/utils/AsyncQueue.res): Adaptive/weighted async queue facade. `#concurrency` `#facade`
* [src/utils/AsyncQueueRuntime.res](src/utils/AsyncQueueRuntime.res): Async queue runtime orchestration bridge. `#concurrency` `#service`
* [src/utils/AsyncQueueAdaptiveRuntime.res](src/utils/AsyncQueueAdaptiveRuntime.res): Adaptive concurrency executor internals. `#concurrency` `#service`
* [src/utils/AsyncQueueWeightedRuntime.res](src/utils/AsyncQueueWeightedRuntime.res): Weighted concurrency executor internals. `#concurrency` `#service`
* [src/utils/PersistenceLayer.res](src/utils/PersistenceLayer.res): Persistence orchestration boundary. `#persistence`
* [src/utils/OperationJournal.res](src/utils/OperationJournal.res): Durable operation journal boundary. `#recovery`
* [src/utils/RecoveryManager.res](src/utils/RecoveryManager.res): Recovery orchestration boundary. `#recovery`
* [src/ServiceWorkerMain.res](src/ServiceWorkerMain.res): Service worker install/activate/fetch runtime entry. `#service-worker` `#orchestrator`
* [src/ServiceWorkerMainSupport.res](src/ServiceWorkerMainSupport.res): Service worker cache/install/activate helper routines. `#service-worker` `#service`
* [src/systems/Scene/SceneLoaderSupport.res](src/systems/Scene/SceneLoaderSupport.res): Scene loader helper routines for reusable and fresh viewer setup. `#scene` `#service`
* [src/systems/Scene/SceneTransitionSupport.res](src/systems/Scene/SceneTransitionSupport.res): Scene swap synchronization and DOM transition helpers. `#scene` `#service`

## ⚙️ Backend API Orchestrators
* [backend/src/api/mod.rs](backend/src/api/mod.rs): API router composition root. `#api` `#orchestrator`
* [backend/src/api/config_routes.rs](backend/src/api/config_routes.rs): API route tree builder for standard and portal scopes. `#api` `#orchestrator`
* [backend/src/api/config_routes_project.rs](backend/src/api/config_routes_project.rs): Project route tree builder. `#api` `#orchestrator`
* [backend/src/api/config_routes_portal.rs](backend/src/api/config_routes_portal.rs): Portal route tree builder. `#api` `#orchestrator`
* [backend/src/api/portal_support.rs](backend/src/api/portal_support.rs): Portal session and URL helper boundary. `#api` `#service`
* [backend/src/api/portal.rs](backend/src/api/portal.rs): Portal API façade re-exporting admin and public handlers. `#api` `#facade`
* [backend/src/api/portal_admin_routes.rs](backend/src/api/portal_admin_routes.rs): Portal admin endpoint handlers. `#api` `#portal`
* [backend/src/api/portal_public_routes.rs](backend/src/api/portal_public_routes.rs): Portal public endpoint handlers. `#api` `#portal`
* [backend/src/middleware.rs](backend/src/middleware.rs): Shared middleware orchestration (auth/quota/rate-limit wiring). `#backend` `#orchestrator`
* [backend/src/api/project.rs](backend/src/api/project.rs): Project API entrypoints. `#api` `#project`
* [backend/src/api/project_import.rs](backend/src/api/project_import.rs): Chunked project import API entrypoints. `#api` `#project`
* [backend/src/api/media/mod.rs](backend/src/api/media/mod.rs): Media API sub-router. `#api` `#media`
* [backend/src/api/media/image.rs](backend/src/api/media/image.rs): Image processing endpoint orchestration. `#api` `#image`
* [backend/src/api/media/video.rs](backend/src/api/media/video.rs): Video/teaser endpoint orchestration. `#api` `#video`
* [backend/src/api/media/video_logic.rs](backend/src/api/media/video_logic.rs): Video logic orchestration façade. `#video` `#orchestrator`
* [backend/src/api/media/video_logic_runtime.rs](backend/src/api/media/video_logic_runtime.rs): Stable runtime entrypoints for headless teaser generation. `#video` `#runtime`
* [backend/src/api/geocoding.rs](backend/src/api/geocoding.rs): Geocoding API endpoints. `#api` `#geocoding`
* [backend/src/api/telemetry.rs](backend/src/api/telemetry.rs): Telemetry ingest endpoint. `#api` `#telemetry`
* [backend/src/api/health.rs](backend/src/api/health.rs): Healthcheck/diagnostics endpoints. `#api` `#health`

## 🔐 Backend Auth Boundaries
* [backend/src/auth.rs](backend/src/auth.rs): JWT and request-auth middleware façade. `#auth` `#orchestrator`
* [backend/src/auth_handlers.rs](backend/src/auth_handlers.rs): OAuth/JWT handler helpers for login redirects and token issuance. `#auth` `#service`
* [backend/src/auth_requests.rs](backend/src/auth_requests.rs): Request-authentication and user attachment helpers for middleware flows. `#auth` `#service`

## 🛡️ Backend Service Orchestrators
* [backend/src/services/mod.rs](backend/src/services/mod.rs): Service layer composition root. `#services` `#orchestrator`
* [backend/src/services/project/mod.rs](backend/src/services/project/mod.rs): Project service orchestration root. `#project` `#orchestrator`
* [backend/src/services/project/import_upload.rs](backend/src/services/project/import_upload.rs): Resumable project import manager façade. `#project` `#upload`
* [backend/src/services/project/import_session.rs](backend/src/services/project/import_session.rs): Import session/chunk assembly orchestration utilities. `#project` `#upload`
* [backend/src/services/project/load.rs](backend/src/services/project/load.rs): Project load orchestration. `#project`
* [backend/src/services/project/package.rs](backend/src/services/project/package.rs): Export packaging orchestration. `#project` `#export`
* [backend/src/services/project/package_assets.rs](backend/src/services/project/package_assets.rs): Export asset collection and resolution packaging helpers. `#project` `#export`
* [backend/src/services/project/package_output.rs](backend/src/services/project/package_output.rs): Export ZIP output writer helpers. `#project` `#export`
* [backend/src/services/project/validate.rs](backend/src/services/project/validate.rs): Project validation orchestration. `#project` `#validation`
* [backend/src/services/project/export_upload_runtime_session.rs](backend/src/services/project/export_upload_runtime_session.rs): Export upload session assembly and lifecycle helpers. `#project` `#upload`
* [backend/src/services/media/mod.rs](backend/src/services/media/mod.rs): Media services façade root. `#media` `#facade`
* [backend/src/services/geocoding/mod.rs](backend/src/services/geocoding/mod.rs): Geocoding service façade root. `#geocoding` `#facade`
* [backend/src/services/portal.rs](backend/src/services/portal.rs): Portal access, assignment, and package management service orchestration. `#services` `#orchestrator`
* [backend/src/services/portal_admin.rs](backend/src/services/portal_admin.rs): Portal administrator authentication and settings orchestration. `#services` `#orchestrator`
* [backend/src/services/portal_assets.rs](backend/src/services/portal_assets.rs): Portal launch document serving, asset resolution, and cover packaging orchestration. `#services` `#orchestrator`
* [backend/src/services/portal_codes.rs](backend/src/services/portal_codes.rs): Portal short-code allocation and assignment validation helpers. `#services` `#orchestrator`
* [backend/src/services/portal_types.rs](backend/src/services/portal_types.rs): Portal domain records, views, and DTO type definitions. `#services` `#types`
* [backend/src/services/portal_assignment_queries.rs](backend/src/services/portal_assignment_queries.rs): Portal assignment lookup, session, and upsert helper queries. `#services` `#orchestrator`
* [backend/src/services/portal_assignments.rs](backend/src/services/portal_assignments.rs): Portal assignment lookup and lifecycle orchestration. `#services` `#orchestrator`
* [backend/src/services/portal_customers.rs](backend/src/services/portal_customers.rs): Portal customer lifecycle and access-link orchestration. `#services` `#orchestrator`
* [backend/src/services/portal_views.rs](backend/src/services/portal_views.rs): Portal customer, tour, and assignment view orchestration helpers. `#services` `#orchestrator`
* [backend/src/services/portal_sessions.rs](backend/src/services/portal_sessions.rs): Portal token resolution, customer session, and gallery view orchestration. `#services` `#orchestrator`
* [backend/src/services/portal_audit.rs](backend/src/services/portal_audit.rs): Portal audit logging helper routines used by the portal service. `#services` `#service`
* [backend/src/pathfinder.rs](backend/src/pathfinder.rs): Pathfinding orchestration entry. `#pathfinding` `#orchestrator`
* [backend/src/pathfinder/algorithms.rs](backend/src/pathfinder/algorithms.rs): Algorithm selection orchestration for pathfinder runtime strategies. `#pathfinding` `#orchestrator`

## 🧪 Primary Test Entrypoints
* [tests/unit/](tests/unit/): Unit test suites (Vitest + ReScript bindings). `#tests`
* [tests/e2e/](tests/e2e/): End-to-end Playwright suites. `#tests`
* [src/portal-index.js](src/portal-index.js): Portal frontend bootstrap entrypoint. `#entry-point` `#orchestrator`
* [backend/src/bin/portal.rs](backend/src/bin/portal.rs): Portal backend binary entrypoint and service bootstrap. `#entry-point` `#orchestrator`

## 🆕 Unmapped Modules
* None currently.
