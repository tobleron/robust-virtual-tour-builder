.
|-- AGENTS.md
|-- GEMINI.md
|-- README.md
|-- backend
|   |-- Cargo.lock
|   |-- Cargo.toml
|   |-- backend.log
|   |-- backend_run.log
|   |-- bin
|   |   `-- ffmpeg
|   |-- src
|   |   |-- api
|   |   |   |-- geocoding.rs
|   |   |   |-- media
|   |   |   |   |-- image.rs
|   |   |   |   |-- mod.rs
|   |   |   |   |-- serve.rs
|   |   |   |   |-- similarity.rs
|   |   |   |   `-- video.rs
|   |   |   |-- mod.rs
|   |   |   |-- project.rs
|   |   |   |-- telemetry.rs
|   |   |   `-- utils.rs
|   |   |-- lib.rs
|   |   |-- main.rs
|   |   |-- metrics.rs
|   |   |-- middleware
|   |   |   |-- mod.rs
|   |   |   |-- quota_check.rs
|   |   |   `-- request_tracker.rs
|   |   |-- models
|   |   |   |-- errors.rs
|   |   |   `-- mod.rs
|   |   |-- pathfinder
|   |   |   |-- algorithms.rs
|   |   |   |-- graph.rs
|   |   |   |-- mod.rs
|   |   |   `-- utils.rs
|   |   `-- services
|   |       |-- geocoding.rs
|   |       |-- media.rs
|   |       |-- mod.rs
|   |       |-- project
|   |       |   |-- load.rs
|   |       |   |-- mod.rs
|   |       |   |-- package.rs
|   |       |   `-- validate.rs
|   |       |-- shutdown.rs
|   |       |-- upload_quota.rs
|   |       `-- upload_quota_tests.rs
|   |-- startup.log
|   |-- startup_debug.log
|   |-- startup_debug_v2.log
|   |-- startup_log.txt
|   `-- tests
|       `-- shutdown_test.rs
|-- bin
|   `-- tailwindcss
|-- cache
|   `-- geocoding.json
|-- css
|   |-- animations.css
|   |-- base.css
|   |-- components
|   |   |-- buttons.css
|   |   |-- floor-nav.css
|   |   |-- modals.css
|   |   |-- ui.css
|   |   `-- viewer.css
|   |-- layout.css
|   |-- legacy.css
|   |-- output.css
|   |-- style.css
|   |-- tailwind.css
|   `-- variables.css
|-- dev.log
|-- dev_prefs
|   |-- logging_debugging_system.md
|   `-- ui_preferences.md
|-- docs
|   |-- ACCESSIBILITY_SYSTEM.md
|   |-- ARCHITECTURE_DIAGRAM.md
|   |-- AntiGravity\ Workflow\ Manual.md
|   |-- IMPROVEMENTS.md
|   |-- OBSERVABILITY_AND_ERROR_HANDLING.md
|   |-- PERFORMANCE_AND_METRICS.md
|   |-- PROJECT_GOVERNANCE_AND_STATUS.md
|   |-- RELEASE_v4.0.9.md
|   |-- SECURITY_AND_STABILITY.md
|   |-- TESTING_QUICK_REFERENCE.md
|   |-- TYPOGRAPHY_AND_UI_SYSTEM.md
|   |-- UNIT_TESTING_INTEGRATION.md
|   `-- openapi.yaml
|-- index.html
|-- lib
|   |-- bs
|   |   |-- build.ninja
|   |   |-- compiler-info.json
|   |   |-- src
|   |   |   |-- App.ast
|   |   |   |-- App.bs.js
|   |   |   |-- App.cmi
|   |   |   |-- App.cmj
|   |   |   |-- App.cmt
|   |   |   |-- App.res
|   |   |   |-- Main.ast
|   |   |   |-- Main.bs.js
|   |   |   |-- Main.cmi
|   |   |   |-- Main.cmj
|   |   |   |-- Main.cmt
|   |   |   |-- Main.res
|   |   |   |-- ReBindings.ast
|   |   |   |-- ReBindings.bs.js
|   |   |   |-- ReBindings.cmi
|   |   |   |-- ReBindings.cmj
|   |   |   |-- ReBindings.cmt
|   |   |   |-- ReBindings.res
|   |   |   |-- ServiceWorker.ast
|   |   |   |-- ServiceWorker.bs.js
|   |   |   |-- ServiceWorker.cmi
|   |   |   |-- ServiceWorker.cmj
|   |   |   |-- ServiceWorker.cmt
|   |   |   |-- ServiceWorker.res
|   |   |   |-- ServiceWorkerMain.ast
|   |   |   |-- ServiceWorkerMain.bs.js
|   |   |   |-- ServiceWorkerMain.cmi
|   |   |   |-- ServiceWorkerMain.cmj
|   |   |   |-- ServiceWorkerMain.cmt
|   |   |   |-- ServiceWorkerMain.res
|   |   |   |-- components
|   |   |   |   |-- ErrorFallbackUI.ast
|   |   |   |   |-- ErrorFallbackUI.bs.js
|   |   |   |   |-- ErrorFallbackUI.cmi
|   |   |   |   |-- ErrorFallbackUI.cmj
|   |   |   |   |-- ErrorFallbackUI.cmt
|   |   |   |   |-- ErrorFallbackUI.res
|   |   |   |   |-- HotspotManager.ast
|   |   |   |   |-- HotspotManager.bs.js
|   |   |   |   |-- HotspotManager.cmi
|   |   |   |   |-- HotspotManager.cmj
|   |   |   |   |-- HotspotManager.cmt
|   |   |   |   |-- HotspotManager.res
|   |   |   |   |-- LabelMenu.ast
|   |   |   |   |-- LabelMenu.bs.js
|   |   |   |   |-- LabelMenu.cmi
|   |   |   |   |-- LabelMenu.cmj
|   |   |   |   |-- LabelMenu.cmt
|   |   |   |   |-- LabelMenu.res
|   |   |   |   |-- LinkModal.ast
|   |   |   |   |-- LinkModal.bs.js
|   |   |   |   |-- LinkModal.cmi
|   |   |   |   |-- LinkModal.cmj
|   |   |   |   |-- LinkModal.cmt
|   |   |   |   |-- LinkModal.res
|   |   |   |   |-- ModalContext.ast
|   |   |   |   |-- ModalContext.bs.js
|   |   |   |   |-- ModalContext.cmi
|   |   |   |   |-- ModalContext.cmj
|   |   |   |   |-- ModalContext.cmt
|   |   |   |   |-- ModalContext.res
|   |   |   |   |-- NotificationContext.ast
|   |   |   |   |-- NotificationContext.bs.js
|   |   |   |   |-- NotificationContext.cmi
|   |   |   |   |-- NotificationContext.cmj
|   |   |   |   |-- NotificationContext.cmt
|   |   |   |   |-- NotificationContext.res
|   |   |   |   |-- RemaxErrorBoundary.ast
|   |   |   |   |-- RemaxErrorBoundary.bs.js
|   |   |   |   |-- RemaxErrorBoundary.cmi
|   |   |   |   |-- RemaxErrorBoundary.cmj
|   |   |   |   |-- RemaxErrorBoundary.cmt
|   |   |   |   |-- RemaxErrorBoundary.res
|   |   |   |   |-- SceneList.ast
|   |   |   |   |-- SceneList.bs.js
|   |   |   |   |-- SceneList.cmi
|   |   |   |   |-- SceneList.cmj
|   |   |   |   |-- SceneList.cmt
|   |   |   |   |-- SceneList.res
|   |   |   |   |-- Sidebar.ast
|   |   |   |   |-- Sidebar.bs.js
|   |   |   |   |-- Sidebar.cmi
|   |   |   |   |-- Sidebar.cmj
|   |   |   |   |-- Sidebar.cmt
|   |   |   |   |-- Sidebar.res
|   |   |   |   |-- UploadReport.ast
|   |   |   |   |-- UploadReport.bs.js
|   |   |   |   |-- UploadReport.cmi
|   |   |   |   |-- UploadReport.cmj
|   |   |   |   |-- UploadReport.cmt
|   |   |   |   |-- UploadReport.res
|   |   |   |   |-- ViewerFollow.ast
|   |   |   |   |-- ViewerFollow.bs.js
|   |   |   |   |-- ViewerFollow.cmi
|   |   |   |   |-- ViewerFollow.cmj
|   |   |   |   |-- ViewerFollow.cmt
|   |   |   |   |-- ViewerFollow.res
|   |   |   |   |-- ViewerLoader.ast
|   |   |   |   |-- ViewerLoader.bs.js
|   |   |   |   |-- ViewerLoader.cmi
|   |   |   |   |-- ViewerLoader.cmj
|   |   |   |   |-- ViewerLoader.cmt
|   |   |   |   |-- ViewerLoader.res
|   |   |   |   |-- ViewerManager.ast
|   |   |   |   |-- ViewerManager.bs.js
|   |   |   |   |-- ViewerManager.cmi
|   |   |   |   |-- ViewerManager.cmj
|   |   |   |   |-- ViewerManager.cmt
|   |   |   |   |-- ViewerManager.res
|   |   |   |   |-- ViewerSnapshot.ast
|   |   |   |   |-- ViewerSnapshot.bs.js
|   |   |   |   |-- ViewerSnapshot.cmi
|   |   |   |   |-- ViewerSnapshot.cmj
|   |   |   |   |-- ViewerSnapshot.cmt
|   |   |   |   |-- ViewerSnapshot.res
|   |   |   |   |-- ViewerState.ast
|   |   |   |   |-- ViewerState.bs.js
|   |   |   |   |-- ViewerState.cmi
|   |   |   |   |-- ViewerState.cmj
|   |   |   |   |-- ViewerState.cmt
|   |   |   |   |-- ViewerState.res
|   |   |   |   |-- ViewerTypes.ast
|   |   |   |   |-- ViewerTypes.bs.js
|   |   |   |   |-- ViewerTypes.cmi
|   |   |   |   |-- ViewerTypes.cmj
|   |   |   |   |-- ViewerTypes.cmt
|   |   |   |   |-- ViewerTypes.res
|   |   |   |   |-- ViewerUI.ast
|   |   |   |   |-- ViewerUI.bs.js
|   |   |   |   |-- ViewerUI.cmi
|   |   |   |   |-- ViewerUI.cmj
|   |   |   |   |-- ViewerUI.cmt
|   |   |   |   |-- ViewerUI.res
|   |   |   |   |-- VisualPipeline.ast
|   |   |   |   |-- VisualPipeline.bs.js
|   |   |   |   |-- VisualPipeline.cmi
|   |   |   |   |-- VisualPipeline.cmj
|   |   |   |   |-- VisualPipeline.cmt
|   |   |   |   `-- VisualPipeline.res
|   |   |   |-- core
|   |   |   |   |-- Actions.ast
|   |   |   |   |-- Actions.bs.js
|   |   |   |   |-- Actions.cmi
|   |   |   |   |-- Actions.cmj
|   |   |   |   |-- Actions.cmt
|   |   |   |   |-- Actions.res
|   |   |   |   |-- AppContext.ast
|   |   |   |   |-- AppContext.bs.js
|   |   |   |   |-- AppContext.cmi
|   |   |   |   |-- AppContext.cmj
|   |   |   |   |-- AppContext.cmt
|   |   |   |   |-- AppContext.res
|   |   |   |   |-- GlobalStateBridge.ast
|   |   |   |   |-- GlobalStateBridge.bs.js
|   |   |   |   |-- GlobalStateBridge.cmi
|   |   |   |   |-- GlobalStateBridge.cmj
|   |   |   |   |-- GlobalStateBridge.cmt
|   |   |   |   |-- GlobalStateBridge.res
|   |   |   |   |-- JsonTypes.ast
|   |   |   |   |-- JsonTypes.bs.js
|   |   |   |   |-- JsonTypes.cmi
|   |   |   |   |-- JsonTypes.cmj
|   |   |   |   |-- JsonTypes.cmt
|   |   |   |   |-- JsonTypes.res
|   |   |   |   |-- Reducer.ast
|   |   |   |   |-- Reducer.bs.js
|   |   |   |   |-- Reducer.cmi
|   |   |   |   |-- Reducer.cmj
|   |   |   |   |-- Reducer.cmt
|   |   |   |   |-- Reducer.res
|   |   |   |   |-- ReducerHelpers.ast
|   |   |   |   |-- ReducerHelpers.bs.js
|   |   |   |   |-- ReducerHelpers.cmi
|   |   |   |   |-- ReducerHelpers.cmj
|   |   |   |   |-- ReducerHelpers.cmt
|   |   |   |   |-- ReducerHelpers.res
|   |   |   |   |-- SharedTypes.ast
|   |   |   |   |-- SharedTypes.bs.js
|   |   |   |   |-- SharedTypes.cmi
|   |   |   |   |-- SharedTypes.cmj
|   |   |   |   |-- SharedTypes.cmt
|   |   |   |   |-- SharedTypes.res
|   |   |   |   |-- State.ast
|   |   |   |   |-- State.bs.js
|   |   |   |   |-- State.cmi
|   |   |   |   |-- State.cmj
|   |   |   |   |-- State.cmt
|   |   |   |   |-- State.res
|   |   |   |   |-- Types.ast
|   |   |   |   |-- Types.bs.js
|   |   |   |   |-- Types.cmi
|   |   |   |   |-- Types.cmj
|   |   |   |   |-- Types.cmt
|   |   |   |   |-- Types.res
|   |   |   |   `-- reducers
|   |   |   |       |-- HotspotReducer.ast
|   |   |   |       |-- HotspotReducer.bs.js
|   |   |   |       |-- HotspotReducer.cmi
|   |   |   |       |-- HotspotReducer.cmj
|   |   |   |       |-- HotspotReducer.cmt
|   |   |   |       |-- HotspotReducer.res
|   |   |   |       |-- NavigationReducer.ast
|   |   |   |       |-- NavigationReducer.bs.js
|   |   |   |       |-- NavigationReducer.cmi
|   |   |   |       |-- NavigationReducer.cmj
|   |   |   |       |-- NavigationReducer.cmt
|   |   |   |       |-- NavigationReducer.res
|   |   |   |       |-- ProjectReducer.ast
|   |   |   |       |-- ProjectReducer.bs.js
|   |   |   |       |-- ProjectReducer.cmi
|   |   |   |       |-- ProjectReducer.cmj
|   |   |   |       |-- ProjectReducer.cmt
|   |   |   |       |-- ProjectReducer.res
|   |   |   |       |-- RootReducer.ast
|   |   |   |       |-- RootReducer.bs.js
|   |   |   |       |-- RootReducer.cmi
|   |   |   |       |-- RootReducer.cmj
|   |   |   |       |-- RootReducer.cmt
|   |   |   |       |-- RootReducer.res
|   |   |   |       |-- SceneReducer.ast
|   |   |   |       |-- SceneReducer.bs.js
|   |   |   |       |-- SceneReducer.cmi
|   |   |   |       |-- SceneReducer.cmj
|   |   |   |       |-- SceneReducer.cmt
|   |   |   |       |-- SceneReducer.res
|   |   |   |       |-- SimulationReducer.ast
|   |   |   |       |-- SimulationReducer.bs.js
|   |   |   |       |-- SimulationReducer.cmi
|   |   |   |       |-- SimulationReducer.cmj
|   |   |   |       |-- SimulationReducer.cmt
|   |   |   |       |-- SimulationReducer.res
|   |   |   |       |-- TimelineReducer.ast
|   |   |   |       |-- TimelineReducer.bs.js
|   |   |   |       |-- TimelineReducer.cmi
|   |   |   |       |-- TimelineReducer.cmj
|   |   |   |       |-- TimelineReducer.cmt
|   |   |   |       |-- TimelineReducer.res
|   |   |   |       |-- UiReducer.ast
|   |   |   |       |-- UiReducer.bs.js
|   |   |   |       |-- UiReducer.cmi
|   |   |   |       |-- UiReducer.cmj
|   |   |   |       |-- UiReducer.cmt
|   |   |   |       |-- UiReducer.res
|   |   |   |       |-- mod.ast
|   |   |   |       |-- mod.bs.js
|   |   |   |       |-- mod.cmi
|   |   |   |       |-- mod.cmj
|   |   |   |       |-- mod.cmt
|   |   |   |       `-- mod.res
|   |   |   |-- systems
|   |   |   |   |-- AudioManager.ast
|   |   |   |   |-- AudioManager.bs.js
|   |   |   |   |-- AudioManager.cmi
|   |   |   |   |-- AudioManager.cmj
|   |   |   |   |-- AudioManager.cmt
|   |   |   |   |-- AudioManager.res
|   |   |   |   |-- BackendApi.ast
|   |   |   |   |-- BackendApi.bs.js
|   |   |   |   |-- BackendApi.cmi
|   |   |   |   |-- BackendApi.cmj
|   |   |   |   |-- BackendApi.cmt
|   |   |   |   |-- BackendApi.res
|   |   |   |   |-- DownloadSystem.ast
|   |   |   |   |-- DownloadSystem.bs.js
|   |   |   |   |-- DownloadSystem.cmi
|   |   |   |   |-- DownloadSystem.cmj
|   |   |   |   |-- DownloadSystem.cmt
|   |   |   |   |-- DownloadSystem.res
|   |   |   |   |-- EventBus.ast
|   |   |   |   |-- EventBus.bs.js
|   |   |   |   |-- EventBus.cmi
|   |   |   |   |-- EventBus.cmj
|   |   |   |   |-- EventBus.cmt
|   |   |   |   |-- EventBus.res
|   |   |   |   |-- ExifParser.ast
|   |   |   |   |-- ExifParser.bs.js
|   |   |   |   |-- ExifParser.cmi
|   |   |   |   |-- ExifParser.cmj
|   |   |   |   |-- ExifParser.cmt
|   |   |   |   |-- ExifParser.res
|   |   |   |   |-- ExifReportGenerator.ast
|   |   |   |   |-- ExifReportGenerator.bs.js
|   |   |   |   |-- ExifReportGenerator.cmi
|   |   |   |   |-- ExifReportGenerator.cmj
|   |   |   |   |-- ExifReportGenerator.cmt
|   |   |   |   |-- ExifReportGenerator.res
|   |   |   |   |-- Exporter.ast
|   |   |   |   |-- Exporter.bs.js
|   |   |   |   |-- Exporter.cmi
|   |   |   |   |-- Exporter.cmj
|   |   |   |   |-- Exporter.cmt
|   |   |   |   |-- Exporter.res
|   |   |   |   |-- HotspotLine.ast
|   |   |   |   |-- HotspotLine.bs.js
|   |   |   |   |-- HotspotLine.cmi
|   |   |   |   |-- HotspotLine.cmj
|   |   |   |   |-- HotspotLine.cmt
|   |   |   |   |-- HotspotLine.res
|   |   |   |   |-- InputSystem.ast
|   |   |   |   |-- InputSystem.bs.js
|   |   |   |   |-- InputSystem.cmi
|   |   |   |   |-- InputSystem.cmj
|   |   |   |   |-- InputSystem.cmt
|   |   |   |   |-- InputSystem.res
|   |   |   |   |-- Navigation.ast
|   |   |   |   |-- Navigation.bs.js
|   |   |   |   |-- Navigation.cmi
|   |   |   |   |-- Navigation.cmj
|   |   |   |   |-- Navigation.cmt
|   |   |   |   |-- Navigation.res
|   |   |   |   |-- NavigationController.ast
|   |   |   |   |-- NavigationController.bs.js
|   |   |   |   |-- NavigationController.cmi
|   |   |   |   |-- NavigationController.cmj
|   |   |   |   |-- NavigationController.cmt
|   |   |   |   |-- NavigationController.res
|   |   |   |   |-- NavigationRenderer.ast
|   |   |   |   |-- NavigationRenderer.bs.js
|   |   |   |   |-- NavigationRenderer.cmi
|   |   |   |   |-- NavigationRenderer.cmj
|   |   |   |   |-- NavigationRenderer.cmt
|   |   |   |   |-- NavigationRenderer.res
|   |   |   |   |-- NavigationUI.ast
|   |   |   |   |-- NavigationUI.bs.js
|   |   |   |   |-- NavigationUI.cmi
|   |   |   |   |-- NavigationUI.cmj
|   |   |   |   |-- NavigationUI.cmt
|   |   |   |   |-- NavigationUI.res
|   |   |   |   |-- ProjectData.ast
|   |   |   |   |-- ProjectData.bs.js
|   |   |   |   |-- ProjectData.cmi
|   |   |   |   |-- ProjectData.cmj
|   |   |   |   |-- ProjectData.cmt
|   |   |   |   |-- ProjectData.res
|   |   |   |   |-- ProjectManager.ast
|   |   |   |   |-- ProjectManager.bs.js
|   |   |   |   |-- ProjectManager.cmi
|   |   |   |   |-- ProjectManager.cmj
|   |   |   |   |-- ProjectManager.cmt
|   |   |   |   |-- ProjectManager.res
|   |   |   |   |-- Resizer.ast
|   |   |   |   |-- Resizer.bs.js
|   |   |   |   |-- Resizer.cmi
|   |   |   |   |-- Resizer.cmj
|   |   |   |   |-- Resizer.cmt
|   |   |   |   |-- Resizer.res
|   |   |   |   |-- ServerTeaser.ast
|   |   |   |   |-- ServerTeaser.bs.js
|   |   |   |   |-- ServerTeaser.cmi
|   |   |   |   |-- ServerTeaser.cmj
|   |   |   |   |-- ServerTeaser.cmt
|   |   |   |   |-- ServerTeaser.res
|   |   |   |   |-- SimulationChainSkipper.ast
|   |   |   |   |-- SimulationChainSkipper.bs.js
|   |   |   |   |-- SimulationChainSkipper.cmi
|   |   |   |   |-- SimulationChainSkipper.cmj
|   |   |   |   |-- SimulationChainSkipper.cmt
|   |   |   |   |-- SimulationChainSkipper.res
|   |   |   |   |-- SimulationDriver.ast
|   |   |   |   |-- SimulationDriver.bs.js
|   |   |   |   |-- SimulationDriver.cmi
|   |   |   |   |-- SimulationDriver.cmj
|   |   |   |   |-- SimulationDriver.cmt
|   |   |   |   |-- SimulationDriver.res
|   |   |   |   |-- SimulationLogic.ast
|   |   |   |   |-- SimulationLogic.bs.js
|   |   |   |   |-- SimulationLogic.cmi
|   |   |   |   |-- SimulationLogic.cmj
|   |   |   |   |-- SimulationLogic.cmt
|   |   |   |   |-- SimulationLogic.res
|   |   |   |   |-- SimulationNavigation.ast
|   |   |   |   |-- SimulationNavigation.bs.js
|   |   |   |   |-- SimulationNavigation.cmi
|   |   |   |   |-- SimulationNavigation.cmj
|   |   |   |   |-- SimulationNavigation.cmt
|   |   |   |   |-- SimulationNavigation.res
|   |   |   |   |-- SimulationPathGenerator.ast
|   |   |   |   |-- SimulationPathGenerator.bs.js
|   |   |   |   |-- SimulationPathGenerator.cmi
|   |   |   |   |-- SimulationPathGenerator.cmj
|   |   |   |   |-- SimulationPathGenerator.cmt
|   |   |   |   |-- SimulationPathGenerator.res
|   |   |   |   |-- TeaserManager.ast
|   |   |   |   |-- TeaserManager.bs.js
|   |   |   |   |-- TeaserManager.cmi
|   |   |   |   |-- TeaserManager.cmj
|   |   |   |   |-- TeaserManager.cmt
|   |   |   |   |-- TeaserManager.res
|   |   |   |   |-- TeaserPathfinder.ast
|   |   |   |   |-- TeaserPathfinder.bs.js
|   |   |   |   |-- TeaserPathfinder.cmi
|   |   |   |   |-- TeaserPathfinder.cmj
|   |   |   |   |-- TeaserPathfinder.cmt
|   |   |   |   |-- TeaserPathfinder.res
|   |   |   |   |-- TeaserRecorder.ast
|   |   |   |   |-- TeaserRecorder.bs.js
|   |   |   |   |-- TeaserRecorder.cmi
|   |   |   |   |-- TeaserRecorder.cmj
|   |   |   |   |-- TeaserRecorder.cmt
|   |   |   |   |-- TeaserRecorder.res
|   |   |   |   |-- TourTemplateAssets.ast
|   |   |   |   |-- TourTemplateAssets.bs.js
|   |   |   |   |-- TourTemplateAssets.cmi
|   |   |   |   |-- TourTemplateAssets.cmj
|   |   |   |   |-- TourTemplateAssets.cmt
|   |   |   |   |-- TourTemplateAssets.res
|   |   |   |   |-- TourTemplateScripts.ast
|   |   |   |   |-- TourTemplateScripts.bs.js
|   |   |   |   |-- TourTemplateScripts.cmi
|   |   |   |   |-- TourTemplateScripts.cmj
|   |   |   |   |-- TourTemplateScripts.cmt
|   |   |   |   |-- TourTemplateScripts.res
|   |   |   |   |-- TourTemplateStyles.ast
|   |   |   |   |-- TourTemplateStyles.bs.js
|   |   |   |   |-- TourTemplateStyles.cmi
|   |   |   |   |-- TourTemplateStyles.cmj
|   |   |   |   |-- TourTemplateStyles.cmt
|   |   |   |   |-- TourTemplateStyles.res
|   |   |   |   |-- TourTemplates.ast
|   |   |   |   |-- TourTemplates.bs.js
|   |   |   |   |-- TourTemplates.cmi
|   |   |   |   |-- TourTemplates.cmj
|   |   |   |   |-- TourTemplates.cmt
|   |   |   |   |-- TourTemplates.res
|   |   |   |   |-- UploadProcessor.ast
|   |   |   |   |-- UploadProcessor.bs.js
|   |   |   |   |-- UploadProcessor.cmi
|   |   |   |   |-- UploadProcessor.cmj
|   |   |   |   |-- UploadProcessor.cmt
|   |   |   |   |-- UploadProcessor.res
|   |   |   |   |-- VideoEncoder.ast
|   |   |   |   |-- VideoEncoder.bs.js
|   |   |   |   |-- VideoEncoder.cmi
|   |   |   |   |-- VideoEncoder.cmj
|   |   |   |   |-- VideoEncoder.cmt
|   |   |   |   `-- VideoEncoder.res
|   |   |   `-- utils
|   |   |       |-- ColorPalette.ast
|   |   |       |-- ColorPalette.bs.js
|   |   |       |-- ColorPalette.cmi
|   |   |       |-- ColorPalette.cmj
|   |   |       |-- ColorPalette.cmt
|   |   |       |-- ColorPalette.res
|   |   |       |-- Constants.ast
|   |   |       |-- Constants.bs.js
|   |   |       |-- Constants.cmi
|   |   |       |-- Constants.cmj
|   |   |       |-- Constants.cmt
|   |   |       |-- Constants.res
|   |   |       |-- GeoUtils.ast
|   |   |       |-- GeoUtils.bs.js
|   |   |       |-- GeoUtils.cmi
|   |   |       |-- GeoUtils.cmj
|   |   |       |-- GeoUtils.cmt
|   |   |       |-- GeoUtils.res
|   |   |       |-- ImageOptimizer.ast
|   |   |       |-- ImageOptimizer.bs.js
|   |   |       |-- ImageOptimizer.cmi
|   |   |       |-- ImageOptimizer.cmj
|   |   |       |-- ImageOptimizer.cmt
|   |   |       |-- ImageOptimizer.cmti
|   |   |       |-- ImageOptimizer.iast
|   |   |       |-- ImageOptimizer.res
|   |   |       |-- ImageOptimizer.resi
|   |   |       |-- LazyLoad.ast
|   |   |       |-- LazyLoad.bs.js
|   |   |       |-- LazyLoad.cmi
|   |   |       |-- LazyLoad.cmj
|   |   |       |-- LazyLoad.cmt
|   |   |       |-- LazyLoad.res
|   |   |       |-- Logger.ast
|   |   |       |-- Logger.bs.js
|   |   |       |-- Logger.cmi
|   |   |       |-- Logger.cmj
|   |   |       |-- Logger.cmt
|   |   |       |-- Logger.res
|   |   |       |-- PathInterpolation.ast
|   |   |       |-- PathInterpolation.bs.js
|   |   |       |-- PathInterpolation.cmi
|   |   |       |-- PathInterpolation.cmj
|   |   |       |-- PathInterpolation.cmt
|   |   |       |-- PathInterpolation.res
|   |   |       |-- ProgressBar.ast
|   |   |       |-- ProgressBar.bs.js
|   |   |       |-- ProgressBar.cmi
|   |   |       |-- ProgressBar.cmj
|   |   |       |-- ProgressBar.cmt
|   |   |       |-- ProgressBar.res
|   |   |       |-- RequestQueue.ast
|   |   |       |-- RequestQueue.bs.js
|   |   |       |-- RequestQueue.cmi
|   |   |       |-- RequestQueue.cmj
|   |   |       |-- RequestQueue.cmt
|   |   |       |-- RequestQueue.res
|   |   |       |-- SessionStore.ast
|   |   |       |-- SessionStore.bs.js
|   |   |       |-- SessionStore.cmi
|   |   |       |-- SessionStore.cmj
|   |   |       |-- SessionStore.cmt
|   |   |       |-- SessionStore.res
|   |   |       |-- StateInspector.ast
|   |   |       |-- StateInspector.bs.js
|   |   |       |-- StateInspector.cmi
|   |   |       |-- StateInspector.cmj
|   |   |       |-- StateInspector.cmt
|   |   |       |-- StateInspector.res
|   |   |       |-- TourLogic.ast
|   |   |       |-- TourLogic.bs.js
|   |   |       |-- TourLogic.cmi
|   |   |       |-- TourLogic.cmj
|   |   |       |-- TourLogic.cmt
|   |   |       |-- TourLogic.res
|   |   |       |-- UrlUtils.ast
|   |   |       |-- UrlUtils.bs.js
|   |   |       |-- UrlUtils.cmi
|   |   |       |-- UrlUtils.cmj
|   |   |       |-- UrlUtils.cmt
|   |   |       |-- UrlUtils.res
|   |   |       |-- Version.ast
|   |   |       |-- Version.bs.js
|   |   |       |-- Version.cmi
|   |   |       |-- Version.cmj
|   |   |       |-- Version.cmt
|   |   |       |-- Version.res
|   |   |       |-- VersionData.ast
|   |   |       |-- VersionData.bs.js
|   |   |       |-- VersionData.cmi
|   |   |       |-- VersionData.cmj
|   |   |       |-- VersionData.cmt
|   |   |       `-- VersionData.res
|   |   `-- tests
|   |       |-- TestRunner.ast
|   |       |-- TestRunner.bs.js
|   |       |-- TestRunner.cmi
|   |       |-- TestRunner.cmj
|   |       |-- TestRunner.cmt
|   |       |-- TestRunner.res
|   |       `-- unit
|   |           |-- ActionsTest.ast
|   |           |-- ActionsTest.bs.js
|   |           |-- ActionsTest.cmi
|   |           |-- ActionsTest.cmj
|   |           |-- ActionsTest.cmt
|   |           |-- ActionsTest.res
|   |           |-- AppContextTest.ast
|   |           |-- AppContextTest.bs.js
|   |           |-- AppContextTest.cmi
|   |           |-- AppContextTest.cmj
|   |           |-- AppContextTest.cmt
|   |           |-- AppContextTest.res
|   |           |-- AppTest.ast
|   |           |-- AppTest.bs.js
|   |           |-- AppTest.cmi
|   |           |-- AppTest.cmj
|   |           |-- AppTest.cmt
|   |           |-- AppTest.res
|   |           |-- AudioManagerTest.ast
|   |           |-- AudioManagerTest.bs.js
|   |           |-- AudioManagerTest.cmi
|   |           |-- AudioManagerTest.cmj
|   |           |-- AudioManagerTest.cmt
|   |           |-- AudioManagerTest.res
|   |           |-- BackendApiTest.ast
|   |           |-- BackendApiTest.bs.js
|   |           |-- BackendApiTest.cmi
|   |           |-- BackendApiTest.cmj
|   |           |-- BackendApiTest.cmt
|   |           |-- BackendApiTest.res
|   |           |-- ConstantsTest.ast
|   |           |-- ConstantsTest.bs.js
|   |           |-- ConstantsTest.cmi
|   |           |-- ConstantsTest.cmj
|   |           |-- ConstantsTest.cmt
|   |           |-- ConstantsTest.res
|   |           |-- DownloadSystemTest.ast
|   |           |-- DownloadSystemTest.bs.js
|   |           |-- DownloadSystemTest.cmi
|   |           |-- DownloadSystemTest.cmj
|   |           |-- DownloadSystemTest.cmt
|   |           |-- DownloadSystemTest.res
|   |           |-- EventBusTest.ast
|   |           |-- EventBusTest.bs.js
|   |           |-- EventBusTest.cmi
|   |           |-- EventBusTest.cmj
|   |           |-- EventBusTest.cmt
|   |           |-- EventBusTest.res
|   |           |-- ExifParserTest.ast
|   |           |-- ExifParserTest.bs.js
|   |           |-- ExifParserTest.cmi
|   |           |-- ExifParserTest.cmj
|   |           |-- ExifParserTest.cmt
|   |           |-- ExifParserTest.res
|   |           |-- ExifReportGeneratorTest.ast
|   |           |-- ExifReportGeneratorTest.bs.js
|   |           |-- ExifReportGeneratorTest.cmi
|   |           |-- ExifReportGeneratorTest.cmj
|   |           |-- ExifReportGeneratorTest.cmt
|   |           |-- ExifReportGeneratorTest.res
|   |           |-- ExporterTest.ast
|   |           |-- ExporterTest.bs.js
|   |           |-- ExporterTest.cmi
|   |           |-- ExporterTest.cmj
|   |           |-- ExporterTest.cmt
|   |           |-- ExporterTest.res
|   |           |-- GeoUtilsTest.ast
|   |           |-- GeoUtilsTest.bs.js
|   |           |-- GeoUtilsTest.cmi
|   |           |-- GeoUtilsTest.cmj
|   |           |-- GeoUtilsTest.cmt
|   |           |-- GeoUtilsTest.res
|   |           |-- GlobalStateBridgeTest.ast
|   |           |-- GlobalStateBridgeTest.bs.js
|   |           |-- GlobalStateBridgeTest.cmi
|   |           |-- GlobalStateBridgeTest.cmj
|   |           |-- GlobalStateBridgeTest.cmt
|   |           |-- GlobalStateBridgeTest.res
|   |           |-- HotspotLine.test.ast
|   |           |-- HotspotLine.test.bs.js
|   |           |-- HotspotLine.test.cmi
|   |           |-- HotspotLine.test.cmj
|   |           |-- HotspotLine.test.cmt
|   |           |-- HotspotLine.test.res
|   |           |-- HotspotLine_v.test.ast
|   |           |-- HotspotLine_v.test.bs.js
|   |           |-- HotspotLine_v.test.cmi
|   |           |-- HotspotLine_v.test.cmj
|   |           |-- HotspotLine_v.test.cmt
|   |           |-- HotspotLine_v.test.res
|   |           |-- HotspotReducerTest.ast
|   |           |-- HotspotReducerTest.bs.js
|   |           |-- HotspotReducerTest.cmi
|   |           |-- HotspotReducerTest.cmj
|   |           |-- HotspotReducerTest.cmt
|   |           |-- HotspotReducerTest.res
|   |           |-- ImageOptimizerTest.ast
|   |           |-- ImageOptimizerTest.bs.js
|   |           |-- ImageOptimizerTest.cmi
|   |           |-- ImageOptimizerTest.cmj
|   |           |-- ImageOptimizerTest.cmt
|   |           |-- ImageOptimizerTest.res
|   |           |-- InputSystemTest.ast
|   |           |-- InputSystemTest.bs.js
|   |           |-- InputSystemTest.cmi
|   |           |-- InputSystemTest.cmj
|   |           |-- InputSystemTest.cmt
|   |           |-- InputSystemTest.res
|   |           |-- JsonTypesTest.ast
|   |           |-- JsonTypesTest.bs.js
|   |           |-- JsonTypesTest.cmi
|   |           |-- JsonTypesTest.cmj
|   |           |-- JsonTypesTest.cmt
|   |           |-- JsonTypesTest.res
|   |           |-- LazyLoadTest.ast
|   |           |-- LazyLoadTest.bs.js
|   |           |-- LazyLoadTest.cmi
|   |           |-- LazyLoadTest.cmj
|   |           |-- LazyLoadTest.cmt
|   |           |-- LazyLoadTest.res
|   |           |-- LoggerTest.ast
|   |           |-- LoggerTest.bs.js
|   |           |-- LoggerTest.cmi
|   |           |-- LoggerTest.cmj
|   |           |-- LoggerTest.cmt
|   |           |-- LoggerTest.res
|   |           |-- MainTest.ast
|   |           |-- MainTest.bs.js
|   |           |-- MainTest.cmi
|   |           |-- MainTest.cmj
|   |           |-- MainTest.cmt
|   |           |-- MainTest.res
|   |           |-- NavigationControllerTest.ast
|   |           |-- NavigationControllerTest.bs.js
|   |           |-- NavigationControllerTest.cmi
|   |           |-- NavigationControllerTest.cmj
|   |           |-- NavigationControllerTest.cmt
|   |           |-- NavigationControllerTest.res
|   |           |-- NavigationReducerTest.ast
|   |           |-- NavigationReducerTest.bs.js
|   |           |-- NavigationReducerTest.cmi
|   |           |-- NavigationReducerTest.cmj
|   |           |-- NavigationReducerTest.cmt
|   |           |-- NavigationReducerTest.res
|   |           |-- NavigationRendererTest.ast
|   |           |-- NavigationRendererTest.bs.js
|   |           |-- NavigationRendererTest.cmi
|   |           |-- NavigationRendererTest.cmj
|   |           |-- NavigationRendererTest.cmt
|   |           |-- NavigationRendererTest.res
|   |           |-- NavigationTest.ast
|   |           |-- NavigationTest.bs.js
|   |           |-- NavigationTest.cmi
|   |           |-- NavigationTest.cmj
|   |           |-- NavigationTest.cmt
|   |           |-- NavigationTest.res
|   |           |-- PathInterpolationTest.ast
|   |           |-- PathInterpolationTest.bs.js
|   |           |-- PathInterpolationTest.cmi
|   |           |-- PathInterpolationTest.cmj
|   |           |-- PathInterpolationTest.cmt
|   |           |-- PathInterpolationTest.res
|   |           |-- ProgressBarTest.ast
|   |           |-- ProgressBarTest.bs.js
|   |           |-- ProgressBarTest.cmi
|   |           |-- ProgressBarTest.cmj
|   |           |-- ProgressBarTest.cmt
|   |           |-- ProgressBarTest.res
|   |           |-- ProjectDataTest.ast
|   |           |-- ProjectDataTest.bs.js
|   |           |-- ProjectDataTest.cmi
|   |           |-- ProjectDataTest.cmj
|   |           |-- ProjectDataTest.cmt
|   |           |-- ProjectDataTest.res
|   |           |-- ProjectManagerTest.ast
|   |           |-- ProjectManagerTest.bs.js
|   |           |-- ProjectManagerTest.cmi
|   |           |-- ProjectManagerTest.cmj
|   |           |-- ProjectManagerTest.cmt
|   |           |-- ProjectManagerTest.res
|   |           |-- ProjectReducerTest.ast
|   |           |-- ProjectReducerTest.bs.js
|   |           |-- ProjectReducerTest.cmi
|   |           |-- ProjectReducerTest.cmj
|   |           |-- ProjectReducerTest.cmt
|   |           |-- ProjectReducerTest.res
|   |           |-- ReBindingsTest.ast
|   |           |-- ReBindingsTest.bs.js
|   |           |-- ReBindingsTest.cmi
|   |           |-- ReBindingsTest.cmj
|   |           |-- ReBindingsTest.cmt
|   |           |-- ReBindingsTest.res
|   |           |-- ReducerHelpersTest.ast
|   |           |-- ReducerHelpersTest.bs.js
|   |           |-- ReducerHelpersTest.cmi
|   |           |-- ReducerHelpersTest.cmj
|   |           |-- ReducerHelpersTest.cmt
|   |           |-- ReducerHelpersTest.res
|   |           |-- ReducerTest.ast
|   |           |-- ReducerTest.bs.js
|   |           |-- ReducerTest.cmi
|   |           |-- ReducerTest.cmj
|   |           |-- ReducerTest.cmt
|   |           |-- ReducerTest.res
|   |           |-- RequestQueueTest.ast
|   |           |-- RequestQueueTest.bs.js
|   |           |-- RequestQueueTest.cmi
|   |           |-- RequestQueueTest.cmj
|   |           |-- RequestQueueTest.cmt
|   |           |-- RequestQueueTest.res
|   |           |-- ResizerTest.ast
|   |           |-- ResizerTest.bs.js
|   |           |-- ResizerTest.cmi
|   |           |-- ResizerTest.cmj
|   |           |-- ResizerTest.cmt
|   |           |-- ResizerTest.res
|   |           |-- RootReducerTest.ast
|   |           |-- RootReducerTest.bs.js
|   |           |-- RootReducerTest.cmi
|   |           |-- RootReducerTest.cmj
|   |           |-- RootReducerTest.cmt
|   |           |-- RootReducerTest.res
|   |           |-- SceneReducerTest.ast
|   |           |-- SceneReducerTest.bs.js
|   |           |-- SceneReducerTest.cmi
|   |           |-- SceneReducerTest.cmj
|   |           |-- SceneReducerTest.cmt
|   |           |-- SceneReducerTest.res
|   |           |-- ServerTeaserTest.ast
|   |           |-- ServerTeaserTest.bs.js
|   |           |-- ServerTeaserTest.cmi
|   |           |-- ServerTeaserTest.cmj
|   |           |-- ServerTeaserTest.cmt
|   |           |-- ServerTeaserTest.res
|   |           |-- ServiceWorkerMainTest.ast
|   |           |-- ServiceWorkerMainTest.bs.js
|   |           |-- ServiceWorkerMainTest.cmi
|   |           |-- ServiceWorkerMainTest.cmj
|   |           |-- ServiceWorkerMainTest.cmt
|   |           |-- ServiceWorkerMainTest.res
|   |           |-- ServiceWorkerTest.ast
|   |           |-- ServiceWorkerTest.bs.js
|   |           |-- ServiceWorkerTest.cmi
|   |           |-- ServiceWorkerTest.cmj
|   |           |-- ServiceWorkerTest.cmt
|   |           |-- ServiceWorkerTest.res
|   |           |-- SessionStoreTest.ast
|   |           |-- SessionStoreTest.bs.js
|   |           |-- SessionStoreTest.cmi
|   |           |-- SessionStoreTest.cmj
|   |           |-- SessionStoreTest.cmt
|   |           |-- SessionStoreTest.res
|   |           |-- SharedTypesTest.ast
|   |           |-- SharedTypesTest.bs.js
|   |           |-- SharedTypesTest.cmi
|   |           |-- SharedTypesTest.cmj
|   |           |-- SharedTypesTest.cmt
|   |           |-- SharedTypesTest.res
|   |           |-- SimulationChainSkipperTest.ast
|   |           |-- SimulationChainSkipperTest.bs.js
|   |           |-- SimulationChainSkipperTest.cmi
|   |           |-- SimulationChainSkipperTest.cmj
|   |           |-- SimulationChainSkipperTest.cmt
|   |           |-- SimulationChainSkipperTest.res
|   |           |-- SimulationDriverTest.ast
|   |           |-- SimulationDriverTest.bs.js
|   |           |-- SimulationDriverTest.cmi
|   |           |-- SimulationDriverTest.cmj
|   |           |-- SimulationDriverTest.cmt
|   |           |-- SimulationDriverTest.res
|   |           |-- SimulationLogicTest.ast
|   |           |-- SimulationLogicTest.bs.js
|   |           |-- SimulationLogicTest.cmi
|   |           |-- SimulationLogicTest.cmj
|   |           |-- SimulationLogicTest.cmt
|   |           |-- SimulationLogicTest.res
|   |           |-- SimulationNavigationTest.ast
|   |           |-- SimulationNavigationTest.bs.js
|   |           |-- SimulationNavigationTest.cmi
|   |           |-- SimulationNavigationTest.cmj
|   |           |-- SimulationNavigationTest.cmt
|   |           |-- SimulationNavigationTest.res
|   |           |-- SimulationPathGeneratorTest.ast
|   |           |-- SimulationPathGeneratorTest.bs.js
|   |           |-- SimulationPathGeneratorTest.cmi
|   |           |-- SimulationPathGeneratorTest.cmj
|   |           |-- SimulationPathGeneratorTest.cmt
|   |           |-- SimulationPathGeneratorTest.res
|   |           |-- SimulationReducerTest.ast
|   |           |-- SimulationReducerTest.bs.js
|   |           |-- SimulationReducerTest.cmi
|   |           |-- SimulationReducerTest.cmj
|   |           |-- SimulationReducerTest.cmt
|   |           |-- SimulationReducerTest.res
|   |           |-- StateInspectorTest.ast
|   |           |-- StateInspectorTest.bs.js
|   |           |-- StateInspectorTest.cmi
|   |           |-- StateInspectorTest.cmj
|   |           |-- StateInspectorTest.cmt
|   |           |-- StateInspectorTest.res
|   |           |-- TeaserManagerTest.ast
|   |           |-- TeaserManagerTest.bs.js
|   |           |-- TeaserManagerTest.cmi
|   |           |-- TeaserManagerTest.cmj
|   |           |-- TeaserManagerTest.cmt
|   |           |-- TeaserManagerTest.res
|   |           |-- TeaserPathfinderTest.ast
|   |           |-- TeaserPathfinderTest.bs.js
|   |           |-- TeaserPathfinderTest.cmi
|   |           |-- TeaserPathfinderTest.cmj
|   |           |-- TeaserPathfinderTest.cmt
|   |           |-- TeaserPathfinderTest.res
|   |           |-- TeaserRecorderTest.ast
|   |           |-- TeaserRecorderTest.bs.js
|   |           |-- TeaserRecorderTest.cmi
|   |           |-- TeaserRecorderTest.cmj
|   |           |-- TeaserRecorderTest.cmt
|   |           |-- TeaserRecorderTest.res
|   |           |-- TimelineReducerTest.ast
|   |           |-- TimelineReducerTest.bs.js
|   |           |-- TimelineReducerTest.cmi
|   |           |-- TimelineReducerTest.cmj
|   |           |-- TimelineReducerTest.cmt
|   |           |-- TimelineReducerTest.res
|   |           |-- TourLogicTest.ast
|   |           |-- TourLogicTest.bs.js
|   |           |-- TourLogicTest.cmi
|   |           |-- TourLogicTest.cmj
|   |           |-- TourLogicTest.cmt
|   |           |-- TourLogicTest.res
|   |           |-- TourTemplateAssetsTest.ast
|   |           |-- TourTemplateAssetsTest.bs.js
|   |           |-- TourTemplateAssetsTest.cmi
|   |           |-- TourTemplateAssetsTest.cmj
|   |           |-- TourTemplateAssetsTest.cmt
|   |           |-- TourTemplateAssetsTest.res
|   |           |-- TourTemplateScriptsTest.ast
|   |           |-- TourTemplateScriptsTest.bs.js
|   |           |-- TourTemplateScriptsTest.cmi
|   |           |-- TourTemplateScriptsTest.cmj
|   |           |-- TourTemplateScriptsTest.cmt
|   |           |-- TourTemplateScriptsTest.res
|   |           |-- TourTemplateStylesTest.ast
|   |           |-- TourTemplateStylesTest.bs.js
|   |           |-- TourTemplateStylesTest.cmi
|   |           |-- TourTemplateStylesTest.cmj
|   |           |-- TourTemplateStylesTest.cmt
|   |           |-- TourTemplateStylesTest.res
|   |           |-- TourTemplatesTest.ast
|   |           |-- TourTemplatesTest.bs.js
|   |           |-- TourTemplatesTest.cmi
|   |           |-- TourTemplatesTest.cmj
|   |           |-- TourTemplatesTest.cmt
|   |           |-- TourTemplatesTest.res
|   |           |-- UiReducerTest.ast
|   |           |-- UiReducerTest.bs.js
|   |           |-- UiReducerTest.cmi
|   |           |-- UiReducerTest.cmj
|   |           |-- UiReducerTest.cmt
|   |           |-- UiReducerTest.res
|   |           |-- UploadProcessorTest.ast
|   |           |-- UploadProcessorTest.bs.js
|   |           |-- UploadProcessorTest.cmi
|   |           |-- UploadProcessorTest.cmj
|   |           |-- UploadProcessorTest.cmt
|   |           |-- UploadProcessorTest.res
|   |           |-- UrlUtilsTest.ast
|   |           |-- UrlUtilsTest.bs.js
|   |           |-- UrlUtilsTest.cmi
|   |           |-- UrlUtilsTest.cmj
|   |           |-- UrlUtilsTest.cmt
|   |           |-- UrlUtilsTest.res
|   |           |-- VersionDataTest.ast
|   |           |-- VersionDataTest.bs.js
|   |           |-- VersionDataTest.cmi
|   |           |-- VersionDataTest.cmj
|   |           |-- VersionDataTest.cmt
|   |           |-- VersionDataTest.res
|   |           |-- VersionTest.ast
|   |           |-- VersionTest.bs.js
|   |           |-- VersionTest.cmi
|   |           |-- VersionTest.cmj
|   |           |-- VersionTest.cmt
|   |           |-- VersionTest.res
|   |           |-- VideoEncoderTest.ast
|   |           |-- VideoEncoderTest.bs.js
|   |           |-- VideoEncoderTest.cmi
|   |           |-- VideoEncoderTest.cmj
|   |           |-- VideoEncoderTest.cmt
|   |           |-- VideoEncoderTest.res
|   |           |-- ViewerLoaderTest.ast
|   |           |-- ViewerLoaderTest.bs.js
|   |           |-- ViewerLoaderTest.cmi
|   |           |-- ViewerLoaderTest.cmj
|   |           |-- ViewerLoaderTest.cmt
|   |           |-- ViewerLoaderTest.res
|   |           |-- VitestSmoke.test.ast
|   |           |-- VitestSmoke.test.bs.js
|   |           |-- VitestSmoke.test.cmi
|   |           |-- VitestSmoke.test.cmj
|   |           |-- VitestSmoke.test.cmt
|   |           `-- VitestSmoke.test.res
|   |-- ocaml
|   |   |-- Actions.ast
|   |   |-- Actions.cmi
|   |   |-- Actions.cmj
|   |   |-- Actions.cmt
|   |   |-- Actions.res
|   |   |-- ActionsTest.ast
|   |   |-- ActionsTest.cmi
|   |   |-- ActionsTest.cmj
|   |   |-- ActionsTest.cmt
|   |   |-- ActionsTest.res
|   |   |-- App.ast
|   |   |-- App.cmi
|   |   |-- App.cmj
|   |   |-- App.cmt
|   |   |-- App.res
|   |   |-- AppContext.ast
|   |   |-- AppContext.cmi
|   |   |-- AppContext.cmj
|   |   |-- AppContext.cmt
|   |   |-- AppContext.res
|   |   |-- AppContextTest.ast
|   |   |-- AppContextTest.cmi
|   |   |-- AppContextTest.cmj
|   |   |-- AppContextTest.cmt
|   |   |-- AppContextTest.res
|   |   |-- AppTest.ast
|   |   |-- AppTest.cmi
|   |   |-- AppTest.cmj
|   |   |-- AppTest.cmt
|   |   |-- AppTest.res
|   |   |-- AudioManager.ast
|   |   |-- AudioManager.cmi
|   |   |-- AudioManager.cmj
|   |   |-- AudioManager.cmt
|   |   |-- AudioManager.res
|   |   |-- AudioManagerTest.ast
|   |   |-- AudioManagerTest.cmi
|   |   |-- AudioManagerTest.cmj
|   |   |-- AudioManagerTest.cmt
|   |   |-- AudioManagerTest.res
|   |   |-- BackendApi.ast
|   |   |-- BackendApi.cmi
|   |   |-- BackendApi.cmj
|   |   |-- BackendApi.cmt
|   |   |-- BackendApi.res
|   |   |-- BackendApiTest.ast
|   |   |-- BackendApiTest.cmi
|   |   |-- BackendApiTest.cmj
|   |   |-- BackendApiTest.cmt
|   |   |-- BackendApiTest.res
|   |   |-- ColorPalette.ast
|   |   |-- ColorPalette.cmi
|   |   |-- ColorPalette.cmj
|   |   |-- ColorPalette.cmt
|   |   |-- ColorPalette.res
|   |   |-- Constants.ast
|   |   |-- Constants.cmi
|   |   |-- Constants.cmj
|   |   |-- Constants.cmt
|   |   |-- Constants.res
|   |   |-- ConstantsTest.ast
|   |   |-- ConstantsTest.cmi
|   |   |-- ConstantsTest.cmj
|   |   |-- ConstantsTest.cmt
|   |   |-- ConstantsTest.res
|   |   |-- DownloadSystem.ast
|   |   |-- DownloadSystem.cmi
|   |   |-- DownloadSystem.cmj
|   |   |-- DownloadSystem.cmt
|   |   |-- DownloadSystem.res
|   |   |-- DownloadSystemTest.ast
|   |   |-- DownloadSystemTest.cmi
|   |   |-- DownloadSystemTest.cmj
|   |   |-- DownloadSystemTest.cmt
|   |   |-- DownloadSystemTest.res
|   |   |-- ErrorFallbackUI.ast
|   |   |-- ErrorFallbackUI.cmi
|   |   |-- ErrorFallbackUI.cmj
|   |   |-- ErrorFallbackUI.cmt
|   |   |-- ErrorFallbackUI.res
|   |   |-- EventBus.ast
|   |   |-- EventBus.cmi
|   |   |-- EventBus.cmj
|   |   |-- EventBus.cmt
|   |   |-- EventBus.res
|   |   |-- EventBusTest.ast
|   |   |-- EventBusTest.cmi
|   |   |-- EventBusTest.cmj
|   |   |-- EventBusTest.cmt
|   |   |-- EventBusTest.res
|   |   |-- ExifParser.ast
|   |   |-- ExifParser.cmi
|   |   |-- ExifParser.cmj
|   |   |-- ExifParser.cmt
|   |   |-- ExifParser.res
|   |   |-- ExifParserTest.ast
|   |   |-- ExifParserTest.cmi
|   |   |-- ExifParserTest.cmj
|   |   |-- ExifParserTest.cmt
|   |   |-- ExifParserTest.res
|   |   |-- ExifReportGenerator.ast
|   |   |-- ExifReportGenerator.cmi
|   |   |-- ExifReportGenerator.cmj
|   |   |-- ExifReportGenerator.cmt
|   |   |-- ExifReportGenerator.res
|   |   |-- ExifReportGeneratorTest.ast
|   |   |-- ExifReportGeneratorTest.cmi
|   |   |-- ExifReportGeneratorTest.cmj
|   |   |-- ExifReportGeneratorTest.cmt
|   |   |-- ExifReportGeneratorTest.res
|   |   |-- Exporter.ast
|   |   |-- Exporter.cmi
|   |   |-- Exporter.cmj
|   |   |-- Exporter.cmt
|   |   |-- Exporter.res
|   |   |-- ExporterTest.ast
|   |   |-- ExporterTest.cmi
|   |   |-- ExporterTest.cmj
|   |   |-- ExporterTest.cmt
|   |   |-- ExporterTest.res
|   |   |-- GeoUtils.ast
|   |   |-- GeoUtils.cmi
|   |   |-- GeoUtils.cmj
|   |   |-- GeoUtils.cmt
|   |   |-- GeoUtils.res
|   |   |-- GeoUtilsTest.ast
|   |   |-- GeoUtilsTest.cmi
|   |   |-- GeoUtilsTest.cmj
|   |   |-- GeoUtilsTest.cmt
|   |   |-- GeoUtilsTest.res
|   |   |-- GlobalStateBridge.ast
|   |   |-- GlobalStateBridge.cmi
|   |   |-- GlobalStateBridge.cmj
|   |   |-- GlobalStateBridge.cmt
|   |   |-- GlobalStateBridge.res
|   |   |-- GlobalStateBridgeTest.ast
|   |   |-- GlobalStateBridgeTest.cmi
|   |   |-- GlobalStateBridgeTest.cmj
|   |   |-- GlobalStateBridgeTest.cmt
|   |   |-- GlobalStateBridgeTest.res
|   |   |-- HotspotLine.ast
|   |   |-- HotspotLine.cmi
|   |   |-- HotspotLine.cmj
|   |   |-- HotspotLine.cmt
|   |   |-- HotspotLine.res
|   |   |-- HotspotLine.test.ast
|   |   |-- HotspotLine.test.cmi
|   |   |-- HotspotLine.test.cmj
|   |   |-- HotspotLine.test.cmt
|   |   |-- HotspotLine.test.res
|   |   |-- HotspotLine_v.test.ast
|   |   |-- HotspotLine_v.test.cmi
|   |   |-- HotspotLine_v.test.cmj
|   |   |-- HotspotLine_v.test.cmt
|   |   |-- HotspotLine_v.test.res
|   |   |-- HotspotManager.ast
|   |   |-- HotspotManager.cmi
|   |   |-- HotspotManager.cmj
|   |   |-- HotspotManager.cmt
|   |   |-- HotspotManager.res
|   |   |-- HotspotReducer.ast
|   |   |-- HotspotReducer.cmi
|   |   |-- HotspotReducer.cmj
|   |   |-- HotspotReducer.cmt
|   |   |-- HotspotReducer.res
|   |   |-- HotspotReducerTest.ast
|   |   |-- HotspotReducerTest.cmi
|   |   |-- HotspotReducerTest.cmj
|   |   |-- HotspotReducerTest.cmt
|   |   |-- HotspotReducerTest.res
|   |   |-- ImageOptimizer.ast
|   |   |-- ImageOptimizer.cmi
|   |   |-- ImageOptimizer.cmj
|   |   |-- ImageOptimizer.cmt
|   |   |-- ImageOptimizer.cmti
|   |   |-- ImageOptimizer.iast
|   |   |-- ImageOptimizer.res
|   |   |-- ImageOptimizer.resi
|   |   |-- ImageOptimizerTest.ast
|   |   |-- ImageOptimizerTest.cmi
|   |   |-- ImageOptimizerTest.cmj
|   |   |-- ImageOptimizerTest.cmt
|   |   |-- ImageOptimizerTest.res
|   |   |-- InputSystem.ast
|   |   |-- InputSystem.cmi
|   |   |-- InputSystem.cmj
|   |   |-- InputSystem.cmt
|   |   |-- InputSystem.res
|   |   |-- InputSystemTest.ast
|   |   |-- InputSystemTest.cmi
|   |   |-- InputSystemTest.cmj
|   |   |-- InputSystemTest.cmt
|   |   |-- InputSystemTest.res
|   |   |-- JsonTypes.ast
|   |   |-- JsonTypes.cmi
|   |   |-- JsonTypes.cmj
|   |   |-- JsonTypes.cmt
|   |   |-- JsonTypes.res
|   |   |-- JsonTypesTest.ast
|   |   |-- JsonTypesTest.cmi
|   |   |-- JsonTypesTest.cmj
|   |   |-- JsonTypesTest.cmt
|   |   |-- JsonTypesTest.res
|   |   |-- LabelMenu.ast
|   |   |-- LabelMenu.cmi
|   |   |-- LabelMenu.cmj
|   |   |-- LabelMenu.cmt
|   |   |-- LabelMenu.res
|   |   |-- LazyLoad.ast
|   |   |-- LazyLoad.cmi
|   |   |-- LazyLoad.cmj
|   |   |-- LazyLoad.cmt
|   |   |-- LazyLoad.res
|   |   |-- LazyLoadTest.ast
|   |   |-- LazyLoadTest.cmi
|   |   |-- LazyLoadTest.cmj
|   |   |-- LazyLoadTest.cmt
|   |   |-- LazyLoadTest.res
|   |   |-- LinkModal.ast
|   |   |-- LinkModal.cmi
|   |   |-- LinkModal.cmj
|   |   |-- LinkModal.cmt
|   |   |-- LinkModal.res
|   |   |-- Logger.ast
|   |   |-- Logger.cmi
|   |   |-- Logger.cmj
|   |   |-- Logger.cmt
|   |   |-- Logger.res
|   |   |-- LoggerTest.ast
|   |   |-- LoggerTest.cmi
|   |   |-- LoggerTest.cmj
|   |   |-- LoggerTest.cmt
|   |   |-- LoggerTest.res
|   |   |-- Main.ast
|   |   |-- Main.cmi
|   |   |-- Main.cmj
|   |   |-- Main.cmt
|   |   |-- Main.res
|   |   |-- MainTest.ast
|   |   |-- MainTest.cmi
|   |   |-- MainTest.cmj
|   |   |-- MainTest.cmt
|   |   |-- MainTest.res
|   |   |-- ModalContext.ast
|   |   |-- ModalContext.cmi
|   |   |-- ModalContext.cmj
|   |   |-- ModalContext.cmt
|   |   |-- ModalContext.res
|   |   |-- Navigation.ast
|   |   |-- Navigation.cmi
|   |   |-- Navigation.cmj
|   |   |-- Navigation.cmt
|   |   |-- Navigation.res
|   |   |-- NavigationController.ast
|   |   |-- NavigationController.cmi
|   |   |-- NavigationController.cmj
|   |   |-- NavigationController.cmt
|   |   |-- NavigationController.res
|   |   |-- NavigationControllerTest.ast
|   |   |-- NavigationControllerTest.cmi
|   |   |-- NavigationControllerTest.cmj
|   |   |-- NavigationControllerTest.cmt
|   |   |-- NavigationControllerTest.res
|   |   |-- NavigationReducer.ast
|   |   |-- NavigationReducer.cmi
|   |   |-- NavigationReducer.cmj
|   |   |-- NavigationReducer.cmt
|   |   |-- NavigationReducer.res
|   |   |-- NavigationReducerTest.ast
|   |   |-- NavigationReducerTest.cmi
|   |   |-- NavigationReducerTest.cmj
|   |   |-- NavigationReducerTest.cmt
|   |   |-- NavigationReducerTest.res
|   |   |-- NavigationRenderer.ast
|   |   |-- NavigationRenderer.cmi
|   |   |-- NavigationRenderer.cmj
|   |   |-- NavigationRenderer.cmt
|   |   |-- NavigationRenderer.res
|   |   |-- NavigationRendererTest.ast
|   |   |-- NavigationRendererTest.cmi
|   |   |-- NavigationRendererTest.cmj
|   |   |-- NavigationRendererTest.cmt
|   |   |-- NavigationRendererTest.res
|   |   |-- NavigationTest.ast
|   |   |-- NavigationTest.cmi
|   |   |-- NavigationTest.cmj
|   |   |-- NavigationTest.cmt
|   |   |-- NavigationTest.res
|   |   |-- NavigationUI.ast
|   |   |-- NavigationUI.cmi
|   |   |-- NavigationUI.cmj
|   |   |-- NavigationUI.cmt
|   |   |-- NavigationUI.res
|   |   |-- NotificationContext.ast
|   |   |-- NotificationContext.cmi
|   |   |-- NotificationContext.cmj
|   |   |-- NotificationContext.cmt
|   |   |-- NotificationContext.res
|   |   |-- PathInterpolation.ast
|   |   |-- PathInterpolation.cmi
|   |   |-- PathInterpolation.cmj
|   |   |-- PathInterpolation.cmt
|   |   |-- PathInterpolation.res
|   |   |-- PathInterpolationTest.ast
|   |   |-- PathInterpolationTest.cmi
|   |   |-- PathInterpolationTest.cmj
|   |   |-- PathInterpolationTest.cmt
|   |   |-- PathInterpolationTest.res
|   |   |-- ProgressBar.ast
|   |   |-- ProgressBar.cmi
|   |   |-- ProgressBar.cmj
|   |   |-- ProgressBar.cmt
|   |   |-- ProgressBar.res
|   |   |-- ProgressBarTest.ast
|   |   |-- ProgressBarTest.cmi
|   |   |-- ProgressBarTest.cmj
|   |   |-- ProgressBarTest.cmt
|   |   |-- ProgressBarTest.res
|   |   |-- ProjectData.ast
|   |   |-- ProjectData.cmi
|   |   |-- ProjectData.cmj
|   |   |-- ProjectData.cmt
|   |   |-- ProjectData.res
|   |   |-- ProjectDataTest.ast
|   |   |-- ProjectDataTest.cmi
|   |   |-- ProjectDataTest.cmj
|   |   |-- ProjectDataTest.cmt
|   |   |-- ProjectDataTest.res
|   |   |-- ProjectManager.ast
|   |   |-- ProjectManager.cmi
|   |   |-- ProjectManager.cmj
|   |   |-- ProjectManager.cmt
|   |   |-- ProjectManager.res
|   |   |-- ProjectManagerTest.ast
|   |   |-- ProjectManagerTest.cmi
|   |   |-- ProjectManagerTest.cmj
|   |   |-- ProjectManagerTest.cmt
|   |   |-- ProjectManagerTest.res
|   |   |-- ProjectReducer.ast
|   |   |-- ProjectReducer.cmi
|   |   |-- ProjectReducer.cmj
|   |   |-- ProjectReducer.cmt
|   |   |-- ProjectReducer.res
|   |   |-- ProjectReducerTest.ast
|   |   |-- ProjectReducerTest.cmi
|   |   |-- ProjectReducerTest.cmj
|   |   |-- ProjectReducerTest.cmt
|   |   |-- ProjectReducerTest.res
|   |   |-- ReBindings.ast
|   |   |-- ReBindings.cmi
|   |   |-- ReBindings.cmj
|   |   |-- ReBindings.cmt
|   |   |-- ReBindings.res
|   |   |-- ReBindingsTest.ast
|   |   |-- ReBindingsTest.cmi
|   |   |-- ReBindingsTest.cmj
|   |   |-- ReBindingsTest.cmt
|   |   |-- ReBindingsTest.res
|   |   |-- Reducer.ast
|   |   |-- Reducer.cmi
|   |   |-- Reducer.cmj
|   |   |-- Reducer.cmt
|   |   |-- Reducer.res
|   |   |-- ReducerHelpers.ast
|   |   |-- ReducerHelpers.cmi
|   |   |-- ReducerHelpers.cmj
|   |   |-- ReducerHelpers.cmt
|   |   |-- ReducerHelpers.res
|   |   |-- ReducerHelpersTest.ast
|   |   |-- ReducerHelpersTest.cmi
|   |   |-- ReducerHelpersTest.cmj
|   |   |-- ReducerHelpersTest.cmt
|   |   |-- ReducerHelpersTest.res
|   |   |-- ReducerTest.ast
|   |   |-- ReducerTest.cmi
|   |   |-- ReducerTest.cmj
|   |   |-- ReducerTest.cmt
|   |   |-- ReducerTest.res
|   |   |-- RemaxErrorBoundary.ast
|   |   |-- RemaxErrorBoundary.cmi
|   |   |-- RemaxErrorBoundary.cmj
|   |   |-- RemaxErrorBoundary.cmt
|   |   |-- RemaxErrorBoundary.res
|   |   |-- RequestQueue.ast
|   |   |-- RequestQueue.cmi
|   |   |-- RequestQueue.cmj
|   |   |-- RequestQueue.cmt
|   |   |-- RequestQueue.res
|   |   |-- RequestQueueTest.ast
|   |   |-- RequestQueueTest.cmi
|   |   |-- RequestQueueTest.cmj
|   |   |-- RequestQueueTest.cmt
|   |   |-- RequestQueueTest.res
|   |   |-- Resizer.ast
|   |   |-- Resizer.cmi
|   |   |-- Resizer.cmj
|   |   |-- Resizer.cmt
|   |   |-- Resizer.res
|   |   |-- ResizerTest.ast
|   |   |-- ResizerTest.cmi
|   |   |-- ResizerTest.cmj
|   |   |-- ResizerTest.cmt
|   |   |-- ResizerTest.res
|   |   |-- RootReducer.ast
|   |   |-- RootReducer.cmi
|   |   |-- RootReducer.cmj
|   |   |-- RootReducer.cmt
|   |   |-- RootReducer.res
|   |   |-- RootReducerTest.ast
|   |   |-- RootReducerTest.cmi
|   |   |-- RootReducerTest.cmj
|   |   |-- RootReducerTest.cmt
|   |   |-- RootReducerTest.res
|   |   |-- SceneList.ast
|   |   |-- SceneList.cmi
|   |   |-- SceneList.cmj
|   |   |-- SceneList.cmt
|   |   |-- SceneList.res
|   |   |-- SceneReducer.ast
|   |   |-- SceneReducer.cmi
|   |   |-- SceneReducer.cmj
|   |   |-- SceneReducer.cmt
|   |   |-- SceneReducer.res
|   |   |-- SceneReducerTest.ast
|   |   |-- SceneReducerTest.cmi
|   |   |-- SceneReducerTest.cmj
|   |   |-- SceneReducerTest.cmt
|   |   |-- SceneReducerTest.res
|   |   |-- ServerTeaser.ast
|   |   |-- ServerTeaser.cmi
|   |   |-- ServerTeaser.cmj
|   |   |-- ServerTeaser.cmt
|   |   |-- ServerTeaser.res
|   |   |-- ServerTeaserTest.ast
|   |   |-- ServerTeaserTest.cmi
|   |   |-- ServerTeaserTest.cmj
|   |   |-- ServerTeaserTest.cmt
|   |   |-- ServerTeaserTest.res
|   |   |-- ServiceWorker.ast
|   |   |-- ServiceWorker.cmi
|   |   |-- ServiceWorker.cmj
|   |   |-- ServiceWorker.cmt
|   |   |-- ServiceWorker.res
|   |   |-- ServiceWorkerMain.ast
|   |   |-- ServiceWorkerMain.cmi
|   |   |-- ServiceWorkerMain.cmj
|   |   |-- ServiceWorkerMain.cmt
|   |   |-- ServiceWorkerMain.res
|   |   |-- ServiceWorkerMainTest.ast
|   |   |-- ServiceWorkerMainTest.cmi
|   |   |-- ServiceWorkerMainTest.cmj
|   |   |-- ServiceWorkerMainTest.cmt
|   |   |-- ServiceWorkerMainTest.res
|   |   |-- ServiceWorkerTest.ast
|   |   |-- ServiceWorkerTest.cmi
|   |   |-- ServiceWorkerTest.cmj
|   |   |-- ServiceWorkerTest.cmt
|   |   |-- ServiceWorkerTest.res
|   |   |-- SessionStore.ast
|   |   |-- SessionStore.cmi
|   |   |-- SessionStore.cmj
|   |   |-- SessionStore.cmt
|   |   |-- SessionStore.res
|   |   |-- SessionStoreTest.ast
|   |   |-- SessionStoreTest.cmi
|   |   |-- SessionStoreTest.cmj
|   |   |-- SessionStoreTest.cmt
|   |   |-- SessionStoreTest.res
|   |   |-- SharedTypes.ast
|   |   |-- SharedTypes.cmi
|   |   |-- SharedTypes.cmj
|   |   |-- SharedTypes.cmt
|   |   |-- SharedTypes.res
|   |   |-- SharedTypesTest.ast
|   |   |-- SharedTypesTest.cmi
|   |   |-- SharedTypesTest.cmj
|   |   |-- SharedTypesTest.cmt
|   |   |-- SharedTypesTest.res
|   |   |-- Sidebar.ast
|   |   |-- Sidebar.cmi
|   |   |-- Sidebar.cmj
|   |   |-- Sidebar.cmt
|   |   |-- Sidebar.res
|   |   |-- SimulationChainSkipper.ast
|   |   |-- SimulationChainSkipper.cmi
|   |   |-- SimulationChainSkipper.cmj
|   |   |-- SimulationChainSkipper.cmt
|   |   |-- SimulationChainSkipper.res
|   |   |-- SimulationChainSkipperTest.ast
|   |   |-- SimulationChainSkipperTest.cmi
|   |   |-- SimulationChainSkipperTest.cmj
|   |   |-- SimulationChainSkipperTest.cmt
|   |   |-- SimulationChainSkipperTest.res
|   |   |-- SimulationDriver.ast
|   |   |-- SimulationDriver.cmi
|   |   |-- SimulationDriver.cmj
|   |   |-- SimulationDriver.cmt
|   |   |-- SimulationDriver.res
|   |   |-- SimulationDriverTest.ast
|   |   |-- SimulationDriverTest.cmi
|   |   |-- SimulationDriverTest.cmj
|   |   |-- SimulationDriverTest.cmt
|   |   |-- SimulationDriverTest.res
|   |   |-- SimulationLogic.ast
|   |   |-- SimulationLogic.cmi
|   |   |-- SimulationLogic.cmj
|   |   |-- SimulationLogic.cmt
|   |   |-- SimulationLogic.res
|   |   |-- SimulationLogicTest.ast
|   |   |-- SimulationLogicTest.cmi
|   |   |-- SimulationLogicTest.cmj
|   |   |-- SimulationLogicTest.cmt
|   |   |-- SimulationLogicTest.res
|   |   |-- SimulationNavigation.ast
|   |   |-- SimulationNavigation.cmi
|   |   |-- SimulationNavigation.cmj
|   |   |-- SimulationNavigation.cmt
|   |   |-- SimulationNavigation.res
|   |   |-- SimulationNavigationTest.ast
|   |   |-- SimulationNavigationTest.cmi
|   |   |-- SimulationNavigationTest.cmj
|   |   |-- SimulationNavigationTest.cmt
|   |   |-- SimulationNavigationTest.res
|   |   |-- SimulationPathGenerator.ast
|   |   |-- SimulationPathGenerator.cmi
|   |   |-- SimulationPathGenerator.cmj
|   |   |-- SimulationPathGenerator.cmt
|   |   |-- SimulationPathGenerator.res
|   |   |-- SimulationPathGeneratorTest.ast
|   |   |-- SimulationPathGeneratorTest.cmi
|   |   |-- SimulationPathGeneratorTest.cmj
|   |   |-- SimulationPathGeneratorTest.cmt
|   |   |-- SimulationPathGeneratorTest.res
|   |   |-- SimulationReducer.ast
|   |   |-- SimulationReducer.cmi
|   |   |-- SimulationReducer.cmj
|   |   |-- SimulationReducer.cmt
|   |   |-- SimulationReducer.res
|   |   |-- SimulationReducerTest.ast
|   |   |-- SimulationReducerTest.cmi
|   |   |-- SimulationReducerTest.cmj
|   |   |-- SimulationReducerTest.cmt
|   |   |-- SimulationReducerTest.res
|   |   |-- State.ast
|   |   |-- State.cmi
|   |   |-- State.cmj
|   |   |-- State.cmt
|   |   |-- State.res
|   |   |-- StateInspector.ast
|   |   |-- StateInspector.cmi
|   |   |-- StateInspector.cmj
|   |   |-- StateInspector.cmt
|   |   |-- StateInspector.res
|   |   |-- StateInspectorTest.ast
|   |   |-- StateInspectorTest.cmi
|   |   |-- StateInspectorTest.cmj
|   |   |-- StateInspectorTest.cmt
|   |   |-- StateInspectorTest.res
|   |   |-- TeaserManager.ast
|   |   |-- TeaserManager.cmi
|   |   |-- TeaserManager.cmj
|   |   |-- TeaserManager.cmt
|   |   |-- TeaserManager.res
|   |   |-- TeaserManagerTest.ast
|   |   |-- TeaserManagerTest.cmi
|   |   |-- TeaserManagerTest.cmj
|   |   |-- TeaserManagerTest.cmt
|   |   |-- TeaserManagerTest.res
|   |   |-- TeaserPathfinder.ast
|   |   |-- TeaserPathfinder.cmi
|   |   |-- TeaserPathfinder.cmj
|   |   |-- TeaserPathfinder.cmt
|   |   |-- TeaserPathfinder.res
|   |   |-- TeaserPathfinderTest.ast
|   |   |-- TeaserPathfinderTest.cmi
|   |   |-- TeaserPathfinderTest.cmj
|   |   |-- TeaserPathfinderTest.cmt
|   |   |-- TeaserPathfinderTest.res
|   |   |-- TeaserRecorder.ast
|   |   |-- TeaserRecorder.cmi
|   |   |-- TeaserRecorder.cmj
|   |   |-- TeaserRecorder.cmt
|   |   |-- TeaserRecorder.res
|   |   |-- TeaserRecorderTest.ast
|   |   |-- TeaserRecorderTest.cmi
|   |   |-- TeaserRecorderTest.cmj
|   |   |-- TeaserRecorderTest.cmt
|   |   |-- TeaserRecorderTest.res
|   |   |-- TestRunner.ast
|   |   |-- TestRunner.cmi
|   |   |-- TestRunner.cmj
|   |   |-- TestRunner.cmt
|   |   |-- TestRunner.res
|   |   |-- TimelineReducer.ast
|   |   |-- TimelineReducer.cmi
|   |   |-- TimelineReducer.cmj
|   |   |-- TimelineReducer.cmt
|   |   |-- TimelineReducer.res
|   |   |-- TimelineReducerTest.ast
|   |   |-- TimelineReducerTest.cmi
|   |   |-- TimelineReducerTest.cmj
|   |   |-- TimelineReducerTest.cmt
|   |   |-- TimelineReducerTest.res
|   |   |-- TourLogic.ast
|   |   |-- TourLogic.cmi
|   |   |-- TourLogic.cmj
|   |   |-- TourLogic.cmt
|   |   |-- TourLogic.res
|   |   |-- TourLogicTest.ast
|   |   |-- TourLogicTest.cmi
|   |   |-- TourLogicTest.cmj
|   |   |-- TourLogicTest.cmt
|   |   |-- TourLogicTest.res
|   |   |-- TourTemplateAssets.ast
|   |   |-- TourTemplateAssets.cmi
|   |   |-- TourTemplateAssets.cmj
|   |   |-- TourTemplateAssets.cmt
|   |   |-- TourTemplateAssets.res
|   |   |-- TourTemplateAssetsTest.ast
|   |   |-- TourTemplateAssetsTest.cmi
|   |   |-- TourTemplateAssetsTest.cmj
|   |   |-- TourTemplateAssetsTest.cmt
|   |   |-- TourTemplateAssetsTest.res
|   |   |-- TourTemplateScripts.ast
|   |   |-- TourTemplateScripts.cmi
|   |   |-- TourTemplateScripts.cmj
|   |   |-- TourTemplateScripts.cmt
|   |   |-- TourTemplateScripts.res
|   |   |-- TourTemplateScriptsTest.ast
|   |   |-- TourTemplateScriptsTest.cmi
|   |   |-- TourTemplateScriptsTest.cmj
|   |   |-- TourTemplateScriptsTest.cmt
|   |   |-- TourTemplateScriptsTest.res
|   |   |-- TourTemplateStyles.ast
|   |   |-- TourTemplateStyles.cmi
|   |   |-- TourTemplateStyles.cmj
|   |   |-- TourTemplateStyles.cmt
|   |   |-- TourTemplateStyles.res
|   |   |-- TourTemplateStylesTest.ast
|   |   |-- TourTemplateStylesTest.cmi
|   |   |-- TourTemplateStylesTest.cmj
|   |   |-- TourTemplateStylesTest.cmt
|   |   |-- TourTemplateStylesTest.res
|   |   |-- TourTemplates.ast
|   |   |-- TourTemplates.cmi
|   |   |-- TourTemplates.cmj
|   |   |-- TourTemplates.cmt
|   |   |-- TourTemplates.res
|   |   |-- TourTemplatesTest.ast
|   |   |-- TourTemplatesTest.cmi
|   |   |-- TourTemplatesTest.cmj
|   |   |-- TourTemplatesTest.cmt
|   |   |-- TourTemplatesTest.res
|   |   |-- Types.ast
|   |   |-- Types.cmi
|   |   |-- Types.cmj
|   |   |-- Types.cmt
|   |   |-- Types.res
|   |   |-- UiReducer.ast
|   |   |-- UiReducer.cmi
|   |   |-- UiReducer.cmj
|   |   |-- UiReducer.cmt
|   |   |-- UiReducer.res
|   |   |-- UiReducerTest.ast
|   |   |-- UiReducerTest.cmi
|   |   |-- UiReducerTest.cmj
|   |   |-- UiReducerTest.cmt
|   |   |-- UiReducerTest.res
|   |   |-- UploadProcessor.ast
|   |   |-- UploadProcessor.cmi
|   |   |-- UploadProcessor.cmj
|   |   |-- UploadProcessor.cmt
|   |   |-- UploadProcessor.res
|   |   |-- UploadProcessorTest.ast
|   |   |-- UploadProcessorTest.cmi
|   |   |-- UploadProcessorTest.cmj
|   |   |-- UploadProcessorTest.cmt
|   |   |-- UploadProcessorTest.res
|   |   |-- UploadReport.ast
|   |   |-- UploadReport.cmi
|   |   |-- UploadReport.cmj
|   |   |-- UploadReport.cmt
|   |   |-- UploadReport.res
|   |   |-- UrlUtils.ast
|   |   |-- UrlUtils.cmi
|   |   |-- UrlUtils.cmj
|   |   |-- UrlUtils.cmt
|   |   |-- UrlUtils.res
|   |   |-- UrlUtilsTest.ast
|   |   |-- UrlUtilsTest.cmi
|   |   |-- UrlUtilsTest.cmj
|   |   |-- UrlUtilsTest.cmt
|   |   |-- UrlUtilsTest.res
|   |   |-- Version.ast
|   |   |-- Version.cmi
|   |   |-- Version.cmj
|   |   |-- Version.cmt
|   |   |-- Version.res
|   |   |-- VersionData.ast
|   |   |-- VersionData.cmi
|   |   |-- VersionData.cmj
|   |   |-- VersionData.cmt
|   |   |-- VersionData.res
|   |   |-- VersionDataTest.ast
|   |   |-- VersionDataTest.cmi
|   |   |-- VersionDataTest.cmj
|   |   |-- VersionDataTest.cmt
|   |   |-- VersionDataTest.res
|   |   |-- VersionTest.ast
|   |   |-- VersionTest.cmi
|   |   |-- VersionTest.cmj
|   |   |-- VersionTest.cmt
|   |   |-- VersionTest.res
|   |   |-- VideoEncoder.ast
|   |   |-- VideoEncoder.cmi
|   |   |-- VideoEncoder.cmj
|   |   |-- VideoEncoder.cmt
|   |   |-- VideoEncoder.res
|   |   |-- VideoEncoderTest.ast
|   |   |-- VideoEncoderTest.cmi
|   |   |-- VideoEncoderTest.cmj
|   |   |-- VideoEncoderTest.cmt
|   |   |-- VideoEncoderTest.res
|   |   |-- ViewerFollow.ast
|   |   |-- ViewerFollow.cmi
|   |   |-- ViewerFollow.cmj
|   |   |-- ViewerFollow.cmt
|   |   |-- ViewerFollow.res
|   |   |-- ViewerLoader.ast
|   |   |-- ViewerLoader.cmi
|   |   |-- ViewerLoader.cmj
|   |   |-- ViewerLoader.cmt
|   |   |-- ViewerLoader.res
|   |   |-- ViewerLoaderTest.ast
|   |   |-- ViewerLoaderTest.cmi
|   |   |-- ViewerLoaderTest.cmj
|   |   |-- ViewerLoaderTest.cmt
|   |   |-- ViewerLoaderTest.res
|   |   |-- ViewerManager.ast
|   |   |-- ViewerManager.cmi
|   |   |-- ViewerManager.cmj
|   |   |-- ViewerManager.cmt
|   |   |-- ViewerManager.res
|   |   |-- ViewerSnapshot.ast
|   |   |-- ViewerSnapshot.cmi
|   |   |-- ViewerSnapshot.cmj
|   |   |-- ViewerSnapshot.cmt
|   |   |-- ViewerSnapshot.res
|   |   |-- ViewerState.ast
|   |   |-- ViewerState.cmi
|   |   |-- ViewerState.cmj
|   |   |-- ViewerState.cmt
|   |   |-- ViewerState.res
|   |   |-- ViewerTypes.ast
|   |   |-- ViewerTypes.cmi
|   |   |-- ViewerTypes.cmj
|   |   |-- ViewerTypes.cmt
|   |   |-- ViewerTypes.res
|   |   |-- ViewerUI.ast
|   |   |-- ViewerUI.cmi
|   |   |-- ViewerUI.cmj
|   |   |-- ViewerUI.cmt
|   |   |-- ViewerUI.res
|   |   |-- VisualPipeline.ast
|   |   |-- VisualPipeline.cmi
|   |   |-- VisualPipeline.cmj
|   |   |-- VisualPipeline.cmt
|   |   |-- VisualPipeline.res
|   |   |-- VitestSmoke.test.ast
|   |   |-- VitestSmoke.test.cmi
|   |   |-- VitestSmoke.test.cmj
|   |   |-- VitestSmoke.test.cmt
|   |   |-- VitestSmoke.test.res
|   |   |-- mod.ast
|   |   |-- mod.cmi
|   |   |-- mod.cmj
|   |   |-- mod.cmt
|   |   `-- mod.res
|   `-- rescript.lock
|-- logs
|   |-- error.log
|   |-- log_changes.txt
|   `-- telemetry.log
|-- package-lock.json
|-- package.json
|-- plans
|   |-- debug_telemetry_fix_plan.md
|   |-- logical_inconsistencies_analysis.md
|   `-- step1_cleanup_notes.md
|-- postcss.config.js
|-- public
|   |-- early-boot.js
|   |-- images
|   |   |-- icon-192.png
|   |   |-- icon-512.png
|   |   |-- logo.png
|   |   `-- og-preview.png
|   |-- libs
|   |   |-- FileSaver.min.js
|   |   |-- jszip.min.js
|   |   |-- pannellum.css
|   |   `-- pannellum.js
|   |-- manifest.json
|   |-- service-worker.js
|   `-- sounds
|       `-- click.wav
|-- rescript.json
|-- rsbuild.config.mjs
|-- scripts
|   |-- cleanup_logs.sh
|   |-- commit.sh
|   |-- debug-connectivity.js
|   |-- detect-missing-tests.js
|   |-- dev-mode.sh
|   |-- increment-build.js
|   |-- prune-snapshots.sh
|   |-- restore-snapshot.sh
|   |-- setup.sh
|   |-- sync-sw.cjs
|   |-- test-logging.js
|   |-- update-version.js
|   `-- watch-file-limits.sh
|-- src
|   |-- App.bs.js
|   |-- App.res
|   |-- Dummy.bs.js
|   |-- Main.bs.js
|   |-- Main.res
|   |-- ReBindings.bs.js
|   |-- ReBindings.res
|   |-- ServiceWorker.bs.js
|   |-- ServiceWorker.res
|   |-- ServiceWorkerMain.bs.js
|   |-- ServiceWorkerMain.res
|   |-- components
|   |   |-- ErrorFallbackUI.bs.js
|   |   |-- ErrorFallbackUI.res
|   |   |-- HotspotManager.bs.js
|   |   |-- HotspotManager.res
|   |   |-- LabelMenu.bs.js
|   |   |-- LabelMenu.res
|   |   |-- LinkModal.bs.js
|   |   |-- LinkModal.res
|   |   |-- ModalContext.bs.js
|   |   |-- ModalContext.res
|   |   |-- NotificationContext.bs.js
|   |   |-- NotificationContext.res
|   |   |-- RemaxErrorBoundary.bs.js
|   |   |-- RemaxErrorBoundary.res
|   |   |-- SceneList.bs.js
|   |   |-- SceneList.res
|   |   |-- Sidebar.bs.js
|   |   |-- Sidebar.res
|   |   |-- UploadReport.bs.js
|   |   |-- UploadReport.res
|   |   |-- ViewerFollow.bs.js
|   |   |-- ViewerFollow.res
|   |   |-- ViewerLoader.bs.js
|   |   |-- ViewerLoader.res
|   |   |-- ViewerManager.bs.js
|   |   |-- ViewerManager.res
|   |   |-- ViewerSnapshot.bs.js
|   |   |-- ViewerSnapshot.res
|   |   |-- ViewerState.bs.js
|   |   |-- ViewerState.res
|   |   |-- ViewerTypes.bs.js
|   |   |-- ViewerTypes.res
|   |   |-- ViewerUI.bs.js
|   |   |-- ViewerUI.res
|   |   |-- VisualPipeline.bs.js
|   |   `-- VisualPipeline.res
|   |-- core
|   |   |-- Actions.bs.js
|   |   |-- Actions.res
|   |   |-- AppContext.bs.js
|   |   |-- AppContext.res
|   |   |-- GlobalStateBridge.bs.js
|   |   |-- GlobalStateBridge.res
|   |   |-- JsonTypes.bs.js
|   |   |-- JsonTypes.res
|   |   |-- Reducer.bs.js
|   |   |-- Reducer.res
|   |   |-- ReducerHelpers.bs.js
|   |   |-- ReducerHelpers.res
|   |   |-- SharedTypes.bs.js
|   |   |-- SharedTypes.res
|   |   |-- State.bs.js
|   |   |-- State.res
|   |   |-- Types.bs.js
|   |   |-- Types.res
|   |   `-- reducers
|   |       |-- HotspotReducer.bs.js
|   |       |-- HotspotReducer.res
|   |       |-- NavigationReducer.bs.js
|   |       |-- NavigationReducer.res
|   |       |-- ProjectReducer.bs.js
|   |       |-- ProjectReducer.res
|   |       |-- RootReducer.bs.js
|   |       |-- RootReducer.res
|   |       |-- SceneReducer.bs.js
|   |       |-- SceneReducer.res
|   |       |-- SimulationReducer.bs.js
|   |       |-- SimulationReducer.res
|   |       |-- TimelineReducer.bs.js
|   |       |-- TimelineReducer.res
|   |       |-- UiReducer.bs.js
|   |       |-- UiReducer.res
|   |       |-- mod.bs.js
|   |       `-- mod.res
|   |-- index.js
|   |-- systems
|   |   |-- AudioManager.bs.js
|   |   |-- AudioManager.res
|   |   |-- BackendApi.bs.js
|   |   |-- BackendApi.res
|   |   |-- DownloadSystem.bs.js
|   |   |-- DownloadSystem.res
|   |   |-- EventBus.bs.js
|   |   |-- EventBus.res
|   |   |-- ExifParser.bs.js
|   |   |-- ExifParser.res
|   |   |-- ExifReportGenerator.bs.js
|   |   |-- ExifReportGenerator.res
|   |   |-- Exporter.bs.js
|   |   |-- Exporter.res
|   |   |-- HotspotLine.bs.js
|   |   |-- HotspotLine.res
|   |   |-- InputSystem.bs.js
|   |   |-- InputSystem.res
|   |   |-- Navigation.bs.js
|   |   |-- Navigation.res
|   |   |-- NavigationController.bs.js
|   |   |-- NavigationController.res
|   |   |-- NavigationRenderer.bs.js
|   |   |-- NavigationRenderer.res
|   |   |-- NavigationUI.bs.js
|   |   |-- NavigationUI.res
|   |   |-- ProjectData.bs.js
|   |   |-- ProjectData.res
|   |   |-- ProjectManager.bs.js
|   |   |-- ProjectManager.res
|   |   |-- Resizer.bs.js
|   |   |-- Resizer.res
|   |   |-- ServerTeaser.bs.js
|   |   |-- ServerTeaser.res
|   |   |-- SimulationChainSkipper.bs.js
|   |   |-- SimulationChainSkipper.res
|   |   |-- SimulationDriver.bs.js
|   |   |-- SimulationDriver.res
|   |   |-- SimulationLogic.bs.js
|   |   |-- SimulationLogic.res
|   |   |-- SimulationNavigation.bs.js
|   |   |-- SimulationNavigation.res
|   |   |-- SimulationPathGenerator.bs.js
|   |   |-- SimulationPathGenerator.res
|   |   |-- TeaserManager.bs.js
|   |   |-- TeaserManager.res
|   |   |-- TeaserPathfinder.bs.js
|   |   |-- TeaserPathfinder.res
|   |   |-- TeaserRecorder.bs.js
|   |   |-- TeaserRecorder.res
|   |   |-- TourTemplateAssets.bs.js
|   |   |-- TourTemplateAssets.res
|   |   |-- TourTemplateScripts.bs.js
|   |   |-- TourTemplateScripts.res
|   |   |-- TourTemplateStyles.bs.js
|   |   |-- TourTemplateStyles.res
|   |   |-- TourTemplates.bs.js
|   |   |-- TourTemplates.res
|   |   |-- UploadProcessor.bs.js
|   |   |-- UploadProcessor.res
|   |   |-- VideoEncoder.bs.js
|   |   `-- VideoEncoder.res
|   `-- utils
|       |-- ColorPalette.bs.js
|       |-- ColorPalette.res
|       |-- Constants.bs.js
|       |-- Constants.res
|       |-- GeoUtils.bs.js
|       |-- GeoUtils.res
|       |-- ImageOptimizer.bs.js
|       |-- ImageOptimizer.res
|       |-- ImageOptimizer.resi
|       |-- LazyLoad.bs.js
|       |-- LazyLoad.res
|       |-- Logger.bs.js
|       |-- Logger.res
|       |-- PathInterpolation.bs.js
|       |-- PathInterpolation.res
|       |-- ProgressBar.bs.js
|       |-- ProgressBar.res
|       |-- RequestQueue.bs.js
|       |-- RequestQueue.res
|       |-- SessionStore.bs.js
|       |-- SessionStore.res
|       |-- StateInspector.bs.js
|       |-- StateInspector.res
|       |-- TourLogic.bs.js
|       |-- TourLogic.res
|       |-- UrlUtils.bs.js
|       |-- UrlUtils.res
|       |-- Version.bs.js
|       |-- Version.res
|       |-- VersionData.bs.js
|       `-- VersionData.res
|-- start_prod.sh
|-- tailwind.config.js
|-- tasks
|   |-- TASKS.md
|   |-- active
|   |   `-- 270_auto_select_first_scene_on_start.md
|   |-- cancelled
|   |-- completed
|   |   |-- 175_fix_runtime_safety_getexn_REPORT.md
|   |   |-- 177_fix_error_handling_REPORT.md
|   |   |-- 194_Add_Tests_for_ServiceWorkerMain_REPORT.md
|   |   |-- 195_Add_Tests_for_UrlUtils_REPORT.md
|   |   |-- 196_Add_Tests_for_VersionData_REPORT.md
|   |   |-- 197_Refactor_RootReducer_Pipeline_REPORT.md
|   |   |-- 198_Implement_Session_Persistence_REPORT.md
|   |   |-- 199_Enhance_GlobalState_Safety_REPORT.md
|   |   |-- 200_Detailed_CSS_Styling_Comparison_REPORT.md
|   |   |-- 206_Comprehensive_Migration_Summary_REPORT.md
|   |   |-- 207_Comprehensive_Testing_And_QA_Summary_REPORT.md
|   |   |-- 208_Backend_Systems_And_Optimization_Summary_REPORT.md
|   |   |-- 209_Refactoring_Security_UX_Summary_REPORT.md
|   |   |-- 216_Fix_Waypoint_Persistence_And_Link_Default_REPORT.md
|   |   |-- 217_Fix_Path_Screen_Stickiness_And_Default_Link_REPORT.md
|   |   |-- 218_Fix_Waypoint_Sticking_To_Screen_REPORT.md
|   |   |-- 219_Fix_Hotspot_Disappearance_After_Save_REPORT.md
|   |   |-- 220_Fix_Hotspot_Disappearance_V2_REPORT.md
|   |   |-- 221_Fix_Invisible_Waypoint_After_Save_REPORT.md
|   |   |-- 222_restore_css_design_tokens_REPORT.md
|   |   |-- 223_restore_premium_ui_components_REPORT.md
|   |   |-- 224_restore_linking_mode_visuals_REPORT.md
|   |   |-- 225_restore_simulation_lockdown_REPORT.md
|   |   |-- 226_restore_premium_hotspots_REPORT.md
|   |   |-- 264_fix_upload_failure_REPORT.md
|   |   |-- 265_troubleshoot_yellow_rod_REPORT.md
|   |   |-- 266_refine_linking_visuals_REPORT.md
|   |   |-- 267_update_camera_movement_behavior_REPORT.md
|   |   `-- 268_verify_scenelist_virtualization_ABORTED.md
|   |-- current_refactor.md
|   `-- pending
|       |-- 176_fix_security_innerhtml.md
|       |-- 178_Restore_v420_Viewer_HUD_Labels_and_Prompts.md
|       |-- 179_Restore_v420_Visual_Pipeline.md
|       |-- 180_Restore_v420_Simulation_Advanced_Mechanics.md
|       |-- 181_extract_business_logic.md
|       |-- 186_implement_backend_geocoding_proxy.md
|       |-- 201_implement_backend_geocoding_cache.md
|       |-- 202_offload_image_similarity_to_backend.md
|       |-- 203_expand_test_coverage.md
|       |-- 204_Add_Tests_for_ImageOptimizer.md
|       |-- 205_re_evaluate_webp_quality.md
|       |-- 210_Add_Tests_for_AppContext.md
|       |-- 211_Add_Tests_for_UiReducer.md
|       |-- 212_Add_Tests_for_NavigationController.md
|       |-- 213_Add_Tests_for_SimulationDriver.md
|       |-- 214_Add_Tests_for_SimulationLogic.md
|       |-- 215_Add_Tests_for_SessionStore.md
|       |-- 269_Add_Tests_for_RequestQueue.md
|       |-- 271_refactor_sidebar_inline_styles.md
|       |-- 272_refactor_viewerui_inline_styles.md
|       |-- 273_centralize_rescript_styling_tokens.md
|       `-- 274_migrate_conditional_styles_to_classes.md
|-- tests
|   |-- TestRunner.bs.js
|   |-- TestRunner.res
|   |-- node-setup.js
|   `-- unit
|       |-- ActionsTest.bs.js
|       |-- ActionsTest.res
|       |-- AppContextTest.bs.js
|       |-- AppContextTest.res
|       |-- AppTest.bs.js
|       |-- AppTest.res
|       |-- AudioManagerTest.bs.js
|       |-- AudioManagerTest.res
|       |-- BackendApiTest.bs.js
|       |-- BackendApiTest.res
|       |-- ConstantsTest.bs.js
|       |-- ConstantsTest.res
|       |-- DownloadSystemTest.bs.js
|       |-- DownloadSystemTest.res
|       |-- EventBusTest.bs.js
|       |-- EventBusTest.res
|       |-- ExifParserTest.bs.js
|       |-- ExifParserTest.res
|       |-- ExifReportGeneratorTest.bs.js
|       |-- ExifReportGeneratorTest.res
|       |-- ExporterTest.bs.js
|       |-- ExporterTest.res
|       |-- GeoUtilsTest.bs.js
|       |-- GeoUtilsTest.res
|       |-- GlobalStateBridgeTest.bs.js
|       |-- GlobalStateBridgeTest.res
|       |-- HotspotLine.test.bs.js
|       |-- HotspotLine.test.res
|       |-- HotspotLine_v.test.bs.js
|       |-- HotspotLine_v.test.res
|       |-- HotspotReducerTest.bs.js
|       |-- HotspotReducerTest.res
|       |-- ImageOptimizerTest.bs.js
|       |-- ImageOptimizerTest.res
|       |-- InputSystemTest.bs.js
|       |-- InputSystemTest.res
|       |-- JsonTypesTest.bs.js
|       |-- JsonTypesTest.res
|       |-- LazyLoadTest.bs.js
|       |-- LazyLoadTest.res
|       |-- LoggerTest.bs.js
|       |-- LoggerTest.res
|       |-- MainTest.bs.js
|       |-- MainTest.res
|       |-- NavigationControllerTest.bs.js
|       |-- NavigationControllerTest.res
|       |-- NavigationReducerTest.bs.js
|       |-- NavigationReducerTest.res
|       |-- NavigationRendererTest.bs.js
|       |-- NavigationRendererTest.res
|       |-- NavigationTest.bs.js
|       |-- NavigationTest.res
|       |-- PathInterpolationTest.bs.js
|       |-- PathInterpolationTest.res
|       |-- ProgressBarTest.bs.js
|       |-- ProgressBarTest.res
|       |-- ProjectDataTest.bs.js
|       |-- ProjectDataTest.res
|       |-- ProjectManagerTest.bs.js
|       |-- ProjectManagerTest.res
|       |-- ProjectReducerTest.bs.js
|       |-- ProjectReducerTest.res
|       |-- ReBindingsTest.bs.js
|       |-- ReBindingsTest.res
|       |-- ReducerHelpersTest.bs.js
|       |-- ReducerHelpersTest.res
|       |-- ReducerTest.bs.js
|       |-- ReducerTest.res
|       |-- RequestQueueTest.bs.js
|       |-- RequestQueueTest.res
|       |-- ResizerTest.bs.js
|       |-- ResizerTest.res
|       |-- RootReducerTest.bs.js
|       |-- RootReducerTest.res
|       |-- SceneReducerTest.bs.js
|       |-- SceneReducerTest.res
|       |-- ServerTeaserTest.bs.js
|       |-- ServerTeaserTest.res
|       |-- ServiceWorkerMainTest.bs.js
|       |-- ServiceWorkerMainTest.res
|       |-- ServiceWorkerTest.bs.js
|       |-- ServiceWorkerTest.res
|       |-- SessionStoreTest.bs.js
|       |-- SessionStoreTest.res
|       |-- SharedTypesTest.bs.js
|       |-- SharedTypesTest.res
|       |-- SimulationChainSkipperTest.bs.js
|       |-- SimulationChainSkipperTest.res
|       |-- SimulationDriverTest.bs.js
|       |-- SimulationDriverTest.res
|       |-- SimulationLogicTest.bs.js
|       |-- SimulationLogicTest.res
|       |-- SimulationNavigationTest.bs.js
|       |-- SimulationNavigationTest.res
|       |-- SimulationPathGeneratorTest.bs.js
|       |-- SimulationPathGeneratorTest.res
|       |-- SimulationReducerTest.bs.js
|       |-- SimulationReducerTest.res
|       |-- StateInspectorTest.bs.js
|       |-- StateInspectorTest.res
|       |-- TeaserManagerTest.bs.js
|       |-- TeaserManagerTest.res
|       |-- TeaserPathfinderTest.bs.js
|       |-- TeaserPathfinderTest.res
|       |-- TeaserRecorderTest.bs.js
|       |-- TeaserRecorderTest.res
|       |-- TimelineReducerTest.bs.js
|       |-- TimelineReducerTest.res
|       |-- TourLogicTest.bs.js
|       |-- TourLogicTest.res
|       |-- TourTemplateAssetsTest.bs.js
|       |-- TourTemplateAssetsTest.res
|       |-- TourTemplateScriptsTest.bs.js
|       |-- TourTemplateScriptsTest.res
|       |-- TourTemplateStylesTest.bs.js
|       |-- TourTemplateStylesTest.res
|       |-- TourTemplatesTest.bs.js
|       |-- TourTemplatesTest.res
|       |-- UiReducerTest.bs.js
|       |-- UiReducerTest.res
|       |-- UploadProcessorTest.bs.js
|       |-- UploadProcessorTest.res
|       |-- UrlUtilsTest.bs.js
|       |-- UrlUtilsTest.res
|       |-- VersionDataTest.bs.js
|       |-- VersionDataTest.res
|       |-- VersionTest.bs.js
|       |-- VersionTest.res
|       |-- VideoEncoderTest.bs.js
|       |-- VideoEncoderTest.res
|       |-- ViewerLoaderTest.bs.js
|       |-- ViewerLoaderTest.res
|       |-- VitestSmoke.test.bs.js
|       `-- VitestSmoke.test.res
`-- vitest.config.mjs

49 directories, 2198 files
