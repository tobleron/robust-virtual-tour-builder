.
|-- GEMINI.md
|-- README.md
|-- backend
|   |-- Cargo.lock
|   |-- Cargo.toml
|   |-- backend.log
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
|   |-- startup_log.txt
|   `-- tests
|       `-- shutdown_test.rs
|-- bin
|   `-- tailwindcss
|-- cache
|   `-- geocoding.json
|-- css
|   |-- output.css
|   |-- style.css
|   `-- tailwind.css
|-- dev_prefs
|   |-- logging_debugging_system.md
|   `-- ui_preferences.md
|-- docs
|   |-- ACCESSIBILITY_AUDIT_RESULTS.md
|   |-- ACCESSIBILITY_GUIDE.md
|   |-- ARCHITECTURE_DIAGRAM.md
|   |-- AntiGravity\ Workflow\ Manual.md
|   |-- BACKEND_OPTIMIZATION_OPPORTUNITIES.md
|   |-- BACKEND_OPTIMIZATION_SUMMARY.md
|   |-- CONTAINER_BASED_FONT_SIZING.md
|   |-- DEBUGGING_GUIDE.md
|   |-- FONT_ANALYSIS.md
|   |-- FONT_IMPLEMENTATION.md
|   |-- FONT_SIZE_ANALYSIS.md
|   |-- FONT_SIZE_IMPLEMENTATION.md
|   |-- IMPROVEMENTS.md
|   |-- LOGGING_ARCHITECTURE.md
|   |-- LONG_TEXT_BEST_PRACTICES.md
|   |-- MANUAL_LOGGING_TEST.md
|   |-- MIGRATION_STATUS_ANALYSIS.md
|   |-- PERFORMANCE_ANALYSIS_FRONTEND_VS_BACKEND.md
|   |-- PERFORMANCE_OPTIMIZATIONS.md
|   |-- PRIORITY_RATIONALE.md
|   |-- PROFESSIONAL_METRICS_REPORT.md
|   |-- PROJECT_ANALYSIS_REPORT.md
|   |-- PROJECT_EVALUATION_2026.md
|   |-- PROJECT_STANDARDS_AND_WORKFLOWS.md
|   |-- RELEASE_v4.0.9.md
|   |-- RESPONSIVE_FONT_SIZING.md
|   |-- SECURITY_ANALYSIS_REPORT.md
|   |-- SECURITY_FIXES_COMPLETE.md
|   |-- SECURITY_FIXES_IMPLEMENTED.md
|   |-- SECURITY_UPGRADES_ADDITIONAL.md
|   |-- SIMULATION_MODE_IMPLEMENTATION.md
|   |-- SIMULATION_TELEMETRY.md
|   |-- TESTING_QUICK_REFERENCE.md
|   |-- TYPOGRAPHY.md
|   |-- UNIT_TESTING_INTEGRATION.md
|   |-- module_size_report.md
|   |-- navigation_improvements_applied.md
|   `-- openapi.yaml
|-- index.html
|-- lib
|   |-- bs
|   |   |-- build.ninja
|   |   |-- src
|   |   |   |-- App.ast
|   |   |   |-- Main.ast
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
|   |   |   |-- components
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
|   |   |   |   |-- Sidebar.ast
|   |   |   |   |-- UploadReport.ast
|   |   |   |   |-- ViewerFollow.ast
|   |   |   |   |-- ViewerFollow.bs.js
|   |   |   |   |-- ViewerFollow.cmi
|   |   |   |   |-- ViewerFollow.cmj
|   |   |   |   |-- ViewerFollow.cmt
|   |   |   |   |-- ViewerFollow.res
|   |   |   |   |-- ViewerLoader.ast
|   |   |   |   |-- ViewerManager.ast
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
|   |   |   |       `-- mod.ast
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
|   |   |   |   |-- Navigation.ast
|   |   |   |   |-- Navigation.bs.js
|   |   |   |   |-- Navigation.cmi
|   |   |   |   |-- Navigation.cmj
|   |   |   |   |-- Navigation.cmt
|   |   |   |   |-- Navigation.res
|   |   |   |   |-- NavigationController.ast
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
|   |   |   |   |-- SimulationNavigation.ast
|   |   |   |   |-- SimulationNavigation.bs.js
|   |   |   |   |-- SimulationNavigation.cmi
|   |   |   |   |-- SimulationNavigation.cmj
|   |   |   |   |-- SimulationNavigation.cmt
|   |   |   |   |-- SimulationNavigation.res
|   |   |   |   |-- SimulationPathGenerator.ast
|   |   |   |   |-- SimulationSystem.ast
|   |   |   |   |-- TeaserManager.ast
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
|   |   |       |-- Version.ast
|   |   |       |-- Version.bs.js
|   |   |       |-- Version.cmi
|   |   |       |-- Version.cmj
|   |   |       |-- Version.cmt
|   |   |       `-- Version.res
|   |   `-- tests
|   |       |-- TestRunner.ast
|   |       `-- unit
|   |           |-- ActionsTest.ast
|   |           |-- ActionsTest.bs.js
|   |           |-- ActionsTest.cmi
|   |           |-- ActionsTest.cmj
|   |           |-- ActionsTest.cmt
|   |           |-- ActionsTest.res
|   |           |-- AppTest.ast
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
|   |           |-- ExifReportGeneratorTest.ast
|   |           |-- ExporterTest.ast
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
|   |           |-- HotspotLine.test.cmt
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
|   |           |-- NavigationReducerTest.ast
|   |           |-- NavigationReducerTest.bs.js
|   |           |-- NavigationReducerTest.cmi
|   |           |-- NavigationReducerTest.cmj
|   |           |-- NavigationReducerTest.cmt
|   |           |-- NavigationReducerTest.res
|   |           |-- NavigationRendererTest.ast
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
|   |           |-- ResizerTest.ast
|   |           |-- ResizerTest.bs.js
|   |           |-- ResizerTest.cmi
|   |           |-- ResizerTest.cmj
|   |           |-- ResizerTest.cmt
|   |           |-- ResizerTest.res
|   |           |-- RootReducerTest.ast
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
|   |           |-- ServiceWorkerTest.ast
|   |           |-- ServiceWorkerTest.bs.js
|   |           |-- ServiceWorkerTest.cmi
|   |           |-- ServiceWorkerTest.cmj
|   |           |-- ServiceWorkerTest.cmt
|   |           |-- ServiceWorkerTest.res
|   |           |-- SharedTypesTest.ast
|   |           |-- SharedTypesTest.bs.js
|   |           |-- SharedTypesTest.cmi
|   |           |-- SharedTypesTest.cmj
|   |           |-- SharedTypesTest.cmt
|   |           |-- SharedTypesTest.res
|   |           |-- SimulationChainSkipperTest.ast
|   |           |-- SimulationNavigationTest.ast
|   |           |-- SimulationPathGeneratorTest.ast
|   |           |-- SimulationSystemTest.ast
|   |           |-- StateInspectorTest.ast
|   |           |-- TeaserManagerTest.ast
|   |           |-- TeaserPathfinderTest.ast
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
|   |           |-- UploadProcessorTest.ast
|   |           |-- UploadProcessorTest.bs.js
|   |           |-- UploadProcessorTest.cmi
|   |           |-- UploadProcessorTest.cmj
|   |           |-- UploadProcessorTest.cmt
|   |           |-- UploadProcessorTest.res
|   |           |-- VersionTest.ast
|   |           |-- VersionTest.bs.js
|   |           |-- VersionTest.cmi
|   |           |-- VersionTest.cmj
|   |           |-- VersionTest.cmt
|   |           |-- VersionTest.res
|   |           |-- VideoEncoderTest.ast
|   |           |-- ViewerLoaderTest.ast
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
|   |   |-- AppContext.ast
|   |   |-- AppTest.ast
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
|   |   |-- ExifReportGenerator.ast
|   |   |-- ExifReportGeneratorTest.ast
|   |   |-- Exporter.ast
|   |   |-- Exporter.cmi
|   |   |-- Exporter.cmj
|   |   |-- Exporter.cmt
|   |   |-- Exporter.res
|   |   |-- ExporterTest.ast
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
|   |   |-- InputSystem.ast
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
|   |   |-- MainTest.ast
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
|   |   |-- RemaxErrorBoundary.ast
|   |   |-- RemaxErrorBoundary.cmi
|   |   |-- RemaxErrorBoundary.cmj
|   |   |-- RemaxErrorBoundary.cmt
|   |   |-- RemaxErrorBoundary.res
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
|   |   |-- SceneList.ast
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
|   |   |-- ServiceWorkerTest.ast
|   |   |-- ServiceWorkerTest.cmi
|   |   |-- ServiceWorkerTest.cmj
|   |   |-- ServiceWorkerTest.cmt
|   |   |-- ServiceWorkerTest.res
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
|   |   |-- SimulationChainSkipper.ast
|   |   |-- SimulationChainSkipperTest.ast
|   |   |-- SimulationNavigation.ast
|   |   |-- SimulationNavigation.cmi
|   |   |-- SimulationNavigation.cmj
|   |   |-- SimulationNavigation.cmt
|   |   |-- SimulationNavigation.res
|   |   |-- SimulationNavigationTest.ast
|   |   |-- SimulationPathGenerator.ast
|   |   |-- SimulationPathGeneratorTest.ast
|   |   |-- SimulationSystem.ast
|   |   |-- SimulationSystemTest.ast
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
|   |   |-- TeaserManager.ast
|   |   |-- TeaserManagerTest.ast
|   |   |-- TeaserPathfinder.ast
|   |   |-- TeaserPathfinder.cmi
|   |   |-- TeaserPathfinder.cmj
|   |   |-- TeaserPathfinder.cmt
|   |   |-- TeaserPathfinder.res
|   |   |-- TeaserPathfinderTest.ast
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
|   |   |-- UploadProcessor.ast
|   |   |-- UploadProcessorTest.ast
|   |   |-- UploadProcessorTest.cmi
|   |   |-- UploadProcessorTest.cmj
|   |   |-- UploadProcessorTest.cmt
|   |   |-- UploadProcessorTest.res
|   |   |-- UploadReport.ast
|   |   |-- Version.ast
|   |   |-- Version.cmi
|   |   |-- Version.cmj
|   |   |-- Version.cmt
|   |   |-- Version.res
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
|   |   |-- ViewerFollow.ast
|   |   |-- ViewerFollow.cmi
|   |   |-- ViewerFollow.cmj
|   |   |-- ViewerFollow.cmt
|   |   |-- ViewerFollow.res
|   |   |-- ViewerLoader.ast
|   |   |-- ViewerLoaderTest.ast
|   |   |-- ViewerManager.ast
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
|   |   `-- mod.ast
|   `-- rescript.lock
|-- logs
|   |-- error.log
|   `-- log_changes.txt
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
|   `-- service-worker.js
|-- rescript.json
|-- rsbuild.config.mjs
|-- scripts
|   |-- cleanup_logs.sh
|   |-- commit.sh
|   |-- debug-connectivity.js
|   |-- detect-missing-tests.js
|   |-- dev-mode.sh
|   |-- ensure-watcher.sh
|   |-- increment-build.js
|   |-- prune-snapshots.sh
|   |-- restore-snapshot.sh
|   |-- setup.sh
|   |-- sync-sw.cjs
|   |-- test-logging.js
|   |-- update-version.js
|   `-- watch-file-limits.sh
|-- sounds
|   `-- click.wav
|-- src
|   |-- App.res
|   |-- Dummy.bs.js
|   |-- Main.res
|   |-- ReBindings.bs.js
|   |-- ReBindings.res
|   |-- ServiceWorker.bs.js
|   |-- ServiceWorker.res
|   |-- components
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
|   |   |-- SafeErrorBoundary.js
|   |   |-- SceneList.res
|   |   |-- Sidebar.res
|   |   |-- UploadReport.res
|   |   |-- ViewerFollow.bs.js
|   |   |-- ViewerFollow.res
|   |   |-- ViewerLoader.res
|   |   |-- ViewerManager.res
|   |   |-- ViewerSnapshot.bs.js
|   |   |-- ViewerSnapshot.res
|   |   |-- ViewerState.bs.js
|   |   |-- ViewerState.res
|   |   |-- ViewerTypes.bs.js
|   |   |-- ViewerTypes.res
|   |   |-- ViewerUI.res
|   |   |-- VisualPipeline.bs.js
|   |   `-- VisualPipeline.res
|   |-- core
|   |   |-- Actions.bs.js
|   |   |-- Actions.res
|   |   |-- AppContext.res
|   |   |-- GlobalStateBridge.bs.js
|   |   |-- GlobalStateBridge.res
|   |   |-- JsonTypes.bs.js
|   |   |-- JsonTypes.res
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
|   |       |-- TimelineReducer.bs.js
|   |       |-- TimelineReducer.res
|   |       |-- UiReducer.bs.js
|   |       |-- UiReducer.res
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
|   |   |-- ExifReportGenerator.res
|   |   |-- Exporter.bs.js
|   |   |-- Exporter.res
|   |   |-- HotspotLine.bs.js
|   |   |-- HotspotLine.res
|   |   |-- InputSystem.res
|   |   |-- Navigation.bs.js
|   |   |-- Navigation.res
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
|   |   |-- SimulationChainSkipper.res
|   |   |-- SimulationNavigation.bs.js
|   |   |-- SimulationNavigation.res
|   |   |-- SimulationPathGenerator.res
|   |   |-- SimulationSystem.res
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
|   |   |-- UploadProcessor.res
|   |   |-- VideoEncoder.bs.js
|   |   `-- VideoEncoder.res
|   |-- utils
|   |   |-- ColorPalette.bs.js
|   |   |-- ColorPalette.res
|   |   |-- Constants.bs.js
|   |   |-- Constants.res
|   |   |-- GeoUtils.bs.js
|   |   |-- GeoUtils.res
|   |   |-- LazyLoad.bs.js
|   |   |-- LazyLoad.res
|   |   |-- Logger.bs.js
|   |   |-- Logger.res
|   |   |-- PathInterpolation.bs.js
|   |   |-- PathInterpolation.res
|   |   |-- ProgressBar.bs.js
|   |   |-- ProgressBar.res
|   |   |-- StateInspector.bs.js
|   |   |-- StateInspector.res
|   |   |-- TourLogic.bs.js
|   |   |-- TourLogic.res
|   |   |-- Version.bs.js
|   |   `-- Version.res
|   `-- version.js
|-- start_prod.sh
|-- tailwind.config.js
|-- tasks
|   |-- TASKS.md
|   |-- active
|   |-- completed
|   |   |-- 01_Architecture_Functional_State_REPORT.md
|   |   |-- 02_Implement_App_Context_REPORT.md
|   |   |-- 03_Refactor_Components_REPORT.md
|   |   |-- 04_Functional_ProjectManager_REPORT.md
|   |   |-- 05_Purify_Navigation_REPORT.md
|   |   |-- 06_Final_Cleanup_REPORT.md
|   |   |-- 100_Add_Tests_for_SharedTypes.md
|   |   |-- 101_Add_Tests_for_BackendApi.md
|   |   |-- 101_Add_Tests_for_BackendApi_REPORT.md
|   |   |-- 102_Add_Tests_for_ProjectManager.md
|   |   |-- 102_Add_Tests_for_ProjectManager_REPORT.md
|   |   |-- 103_Add_Tests_for_Resizer.md
|   |   |-- 103_Add_Tests_for_Resizer_REPORT.md
|   |   |-- 104_Add_Tests_for_UploadProcessor.md
|   |   |-- 104_Add_Tests_for_UploadProcessor_REPORT.md
|   |   |-- 105_Install_Rsbuild.md
|   |   |-- 105_Install_Rsbuild_REPORT.md
|   |   |-- 106_Configure_Rsbuild_Entry.md
|   |   |-- 106_Configure_Rsbuild_Entry_REPORT.md
|   |   |-- 107_Integrate_Tailwind_Rsbuild.md
|   |   |-- 107_Integrate_Tailwind_Rsbuild_REPORT.md
|   |   |-- 108_Finalize_Rsbuild_Prod.md
|   |   |-- 108_Finalize_Rsbuild_Prod_REPORT.md
|   |   |-- 109_Cleanup_Legacy_Scripts.md
|   |   |-- 10_ReScript_Migrate_Resizer_REPORT.md
|   |   |-- 110_Add_Tests_for_TeaserManager_REPORT.md
|   |   |-- 111_Add_Tests_for_TourTemplateAssets_REPORT.md
|   |   |-- 112_Add_Tests_for_TourTemplateScripts_REPORT.md
|   |   |-- 113_Add_Tests_for_TourTemplateStyles_REPORT.md
|   |   |-- 114_Add_Tests_for_StateInspector_REPORT.md
|   |   |-- 115_Add_Tests_ViewerLoader_Navigation.md
|   |   |-- 116_Update_ServiceWorker_Cache_Paths.md
|   |   |-- 117_Add_OpenAPI_Documentation.md
|   |   |-- 118_Run_Accessibility_Audit.md
|   |   |-- 119_Eliminate_ObjMagic_Patterns_REPORT.md
|   |   |-- 11_ReScript_Migrate_ProjectManager_REPORT.md
|   |   |-- 120_Add_Meta_Description_OG_Tags.md
|   |   |-- 121_Add_Prometheus_Metrics_REPORT.md
|   |   |-- 122_Split_Large_Backend_Modules.md
|   |   |-- 123_Add_GitHub_Actions_CI.md
|   |   |-- 124_Add_Tests_for_ReBindings.md
|   |   |-- 125_Add_Tests_for_ExifReportGenerator.md
|   |   |-- 126_Add_Tests_for_TeaserRecorder.md
|   |   |-- 127_Add_Tests_for_Logger.md
|   |   |-- 128_Implement_SceneList_Virtualization.md
|   |   |-- 129_Accessibility_And_SEO_Improvements.md
|   |   |-- 12_ReScript_Migrate_UI_Components_REPORT.md
|   |   |-- 130_Reduce_Obj_Magic_Usage.md
|   |   |-- 131_Security_And_SW_Hardening.md
|   |   |-- 131_Security_And_SW_Hardening_REPORT.md
|   |   |-- 132_Comprehensive_Project_Analysis_REPORT.md
|   |   |-- 133_Add_Tests_for_JsonTypes.md
|   |   |-- 134_Add_Tests_for_ReducerHelpers.md
|   |   |-- 135_Add_Tests_for_AudioManager.md
|   |   |-- 136_Add_Tests_for_DownloadSystem_REPORT.md
|   |   |-- 137_Add_Tests_for_InputSystem_REPORT.md
|   |   |-- 138_Add_Tests_for_ProjectData_REPORT.md
|   |   |-- 139_Add_Tests_for_VideoEncoder_REPORT.md
|   |   |-- 140_Add_Tests_for_LazyLoad.md
|   |   |-- 141_Add_Tests_for_ProgressBar_REPORT.md
|   |   |-- 142_Add_Tests_for_Exporter.md
|   |   |-- 143_Add_Tests_for_Main_REPORT.md
|   |   |-- 144_Add_Tests_for_ServiceWorker_REPORT.md
|   |   |-- 145_Add_Tests_for_Actions_REPORT.md
|   |   |-- 146_Add_Tests_for_GlobalStateBridge_REPORT.md
|   |   |-- 147_Add_Tests_for_RootReducer_REPORT.md
|   |   |-- 148_Add_Tests_for_EventBus_REPORT.md
|   |   |-- 149_Add_Tests_for_NavigationReducer_REPORT.md
|   |   |-- 14_ReScript_Migrate_Viewer_REPORT.md
|   |   |-- 150_Add_Tests_for_ProjectReducer_REPORT.md
|   |   |-- 151_Add_Tests_for_TimelineReducer_REPORT.md
|   |   |-- 152_Add_Tests_for_NavigationRenderer_REPORT.md
|   |   |-- 153_Add_Tests_for_SimulationNavigation_REPORT.md
|   |   |-- 154_Add_Tests_for_SimulationPathGenerator_REPORT.md
|   |   |-- 155_Add_Tests_for_TeaserPathfinder_REPORT.md
|   |   |-- 156_Add_Tests_for_SimulationChainSkipper_REPORT.md
|   |   |-- 157_Add_Tests_for_ServerTeaser_REPORT.md
|   |   |-- 158_Add_Tests_for_TourTemplates_REPORT.md
|   |   |-- 159_Add_Tests_for_Constants.md
|   |   |-- 159_Add_Tests_for_Constants_Report.md
|   |   |-- 15_Backend_SingleZIP_Load_REPORT.md
|   |   |-- 160_Add_Tests_for_Version_REPORT.md
|   |   |-- 161_Setup_Vitest_Infrastructure.md
|   |   |-- 162_Add_React_Error_Boundary_REPORT.md
|   |   |-- 163_Secure_Production_Logging_REPORT.md
|   |   |-- 164_Fix_ReScript_Deprecations.md
|   |   |-- 164_Fix_ReScript_Deprecations_REPORT.md
|   |   |-- 165_Implement_Dynamic_SEO_REPORT.md
|   |   |-- 166_Add_Tests_for_App_REPORT.md
|   |   |-- 168_Add_Tests_for_HotspotLine_REPORT.md
|   |   |-- 16_Backend_Project_Validation_REPORT.md
|   |   |-- 174_Restore_v420_Linking_Mechanics_REPORT.md
|   |   |-- 17_Backend_Filename_Suggestion_REPORT.md
|   |   |-- 18_Frontend_SingleZIP_Integration_REPORT.md
|   |   |-- 19_Cleanup_Duplicate_Utilities_REPORT.md
|   |   |-- 20_Cleanup_Legacy_CSS_and_Backups_REPORT.md
|   |   |-- 21_Migrate_Viewer_Snapshot_System_REPORT.md
|   |   |-- 22_Migrate_Viewer_Dual_Pannellum_REPORT.md
|   |   |-- 23_Migrate_Visual_Pipeline_REPORT.md
|   |   |-- 24_Migrate_Exporter_Systems_REPORT.md
|   |   |-- 25_Migrate_Exif_Report_Generator.md
|   |   |-- 26_Unified_Backend_API_Module_REPORT.md
|   |   |-- 27_Migrate_Supporting_Systems_REPORT.md
|   |   |-- 28_Migrate_Cache_Video_Systems_REPORT.md
|   |   |-- 29_Refactor_Teaser_Logic_REPORT.md
|   |   |-- 30_Eliminate_JS_Adapters_REPORT.md
|   |   |-- 30_Logging_Backend_Endpoints_REPORT.md
|   |   |-- 31_Final_Polish_And_Cleanup_REPORT.md
|   |   |-- 31_Logging_Rust_Internal_Tracing_REPORT.md
|   |   |-- 32_Logging_Migrate_Navigation_REPORT.md
|   |   |-- 33_Logging_Migrate_ViewerLoader_REPORT.md
|   |   |-- 34_Logging_Migrate_HotspotManager_REPORT.md
|   |   |-- 34_Logging_Project_Persistence_REPORT.md
|   |   |-- 35_Logging_Migrate_SimulationSystem_REPORT.md
|   |   |-- 36_Logging_Migrate_Exporter_REPORT.md
|   |   |-- 37_Logging_Migrate_UploadProcessor_REPORT.md
|   |   |-- 38_Logging_Migrate_InputSystem_REPORT.md
|   |   |-- 39_Logging_Migrate_NavigationRenderer_REPORT.md
|   |   |-- 40_Logging_Migrate_VideoEncoder_REPORT.md
|   |   |-- 41_Logging_Migrate_Store_REPORT.md
|   |   |-- 42_Logging_Migrate_TeaserSystem_REPORT.md
|   |   |-- 43_Logging_Migrate_Sidebar_REPORT.md
|   |   |-- 44_Logging_Debug_Shortcuts_REPORT.md
|   |   |-- 45_Logging_Migrate_Remaining_Modules_REPORT.md
|   |   |-- 46_Logging_Rotation_Cleanup_REPORT.md
|   |   |-- 47_Logging_Integration_Tests_REPORT.md
|   |   |-- 48_Backend_Pure_Validation_Refactor_REPORT.md
|   |   |-- 49_Backend_Standardize_Logging_REPORT.md
|   |   |-- 50_Backend_Remove_Unwrap_REPORT.md
|   |   |-- 51_Backend_LogError_Endpoint_REPORT.md
|   |   |-- 52_Backend_Functional_Iterators_REPORT.md
|   |   |-- 53_Migrate_Logging_System_REPORT.md
|   |   |-- 54_Migrate_EventBus_REPORT.md
|   |   |-- 55_Migrate_UI_Contexts_REPORT.md
|   |   |-- 56_Backend_Project_Loading_REPORT.md
|   |   |-- 57_Backend_Pathfinding_REPORT.md
|   |   |-- 58_Migrate_Entry_Point_REPORT.md
|   |   |-- 59_Backend_Reverse_Geocoding_Endpoint_REPORT.md
|   |   |-- 60_Backend_Remove_Unwrap_Calls_REPORT.md
|   |   |-- 61_Backend_Geocoding_Cache_Layer_REPORT.md
|   |   |-- 62_Backend_Batch_Similarity_Endpoint_REPORT.md
|   |   |-- 63_Refactor_SimulationSystem_State_REPORT.md
|   |   |-- 64_Migrate_Constants_To_ReScript_REPORT.md
|   |   |-- 65_Cleanup_Dead_Code_REPORT.md
|   |   |-- 66_Extract_Backend_Domain_Types_REPORT.md
|   |   |-- 67_Extract_Media_Service_REPORT.md
|   |   |-- 68_Extract_Project_Service_REPORT.md
|   |   |-- 69_Extract_Geocoding_Service_REPORT.md
|   |   |-- 71_Pathfinder_Hardening_REPORT.md
|   |   |-- 73_Refactor_media_REPORT.md
|   |   |-- 74_Refactor_SimulationSystem_REPORT.md
|   |   |-- 75_Fix_IndexHTML_Critical_Bugs_REPORT.md
|   |   |-- 76_Fix_ReScript_Shadowing_Warnings_REPORT.md
|   |   |-- 77_Eliminate_ObjMagic_BackendApi_REPORT.md
|   |   |-- 78_Improve_Error_Handling_BackendApi_REPORT.md
|   |   |-- 79_Remove_Unused_Backend_Import_REPORT.md
|   |   |-- 80_Add_Frontend_Unit_Tests_REPORT.md
|   |   |-- 81_Expand_Backend_Test_Coverage_REPORT.md
|   |   |-- 82_Add_Rust_Documentation_Comments_REPORT.md
|   |   |-- 83_Implement_Code_Splitting_REPORT.md
|   |   |-- 84_Implement_Service_Worker_REPORT.md
|   |   |-- 85_Refactor_TourTemplates_Module_REPORT.md
|   |   |-- 86_Refactor_Reducer_Module.md
|   |   |-- 87_Centralized_Version_Management_REPORT.md
|   |   |-- 88_Eliminate_ObjMagic_Reducer_REPORT.md
|   |   |-- 89_Eliminate_ObjMagic_Main.md
|   |   |-- 90_Secure_GlobalStateBridge_REPORT.md
|   |   |-- 91_Implement_Reducer_Slicing_REPORT.md
|   |   |-- 92_Backend_Upload_Quota_System.md
|   |   |-- 93_Backend_Graceful_Shutdown_REPORT.md
|   |   |-- 94_Remove_Dead_ImageAnalysis.md
|   |   |-- 94_Remove_Dead_ImageAnalysis_REPORT.md
|   |   |-- 95_Wire_Backend_Similarity.md
|   |   |-- 95_Wire_Backend_Similarity_REPORT.md
|   |   |-- 96_Migrate_Constants_To_Rescript.md
|   |   |-- 96_Migrate_Constants_To_Rescript_REPORT.md
|   |   |-- 97_Migrate_To_Vite_ABORTED.md
|   |   |-- 97_Migrate_To_Vite_ABORTED_REPORT.md
|   |   |-- 98_Backend_Safety_Audit.md
|   |   |-- 98_Backend_Safety_Audit_REPORT.md
|   |   |-- 99_Unify_Types.md
|   |   |-- 99_Unify_Types_REPORT.md
|   |   `-- CONSOLIDATED_TASK_SUMMARIES_REPORT.md
|   `-- pending
|       |-- 175_Restore_v420_Viewer_HUD_Labels_and_Prompts.md
|       |-- 176_Restore_v420_Visual_Pipeline.md
|       `-- 177_Restore_v420_Simulation_Advanced_Mechanics.md
|-- tests
|   |-- TestRunner.res
|   |-- node-setup.js
|   `-- unit
|       |-- ActionsTest.bs.js
|       |-- ActionsTest.res
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
|       |-- ExifParserTest.res
|       |-- ExifReportGeneratorTest.res
|       |-- ExporterTest.res
|       |-- GeoUtilsTest.bs.js
|       |-- GeoUtilsTest.res
|       |-- GlobalStateBridgeTest.bs.js
|       |-- GlobalStateBridgeTest.res
|       |-- HotspotLine.test.res
|       |-- HotspotLine_v.test.bs.js
|       |-- HotspotLine_v.test.res
|       |-- HotspotReducerTest.bs.js
|       |-- HotspotReducerTest.res
|       |-- InputSystemTest.bs.js
|       |-- InputSystemTest.res
|       |-- JsonTypesTest.bs.js
|       |-- JsonTypesTest.res
|       |-- LazyLoadTest.bs.js
|       |-- LazyLoadTest.res
|       |-- LoggerTest.bs.js
|       |-- LoggerTest.res
|       |-- MainTest.res
|       |-- NavigationReducerTest.bs.js
|       |-- NavigationReducerTest.res
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
|       |-- ReducerTest.res
|       |-- ResizerTest.bs.js
|       |-- ResizerTest.res
|       |-- RootReducerTest.res
|       |-- SceneReducerTest.bs.js
|       |-- SceneReducerTest.res
|       |-- ServerTeaserTest.bs.js
|       |-- ServerTeaserTest.res
|       |-- ServiceWorkerTest.bs.js
|       |-- ServiceWorkerTest.res
|       |-- SharedTypesTest.bs.js
|       |-- SharedTypesTest.res
|       |-- SimulationChainSkipperTest.res
|       |-- SimulationNavigationTest.res
|       |-- SimulationPathGeneratorTest.res
|       |-- SimulationSystemTest.res
|       |-- StateInspectorTest.res
|       |-- TeaserManagerTest.res
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
|       |-- UploadProcessorTest.bs.js
|       |-- UploadProcessorTest.res
|       |-- VersionTest.bs.js
|       |-- VersionTest.res
|       |-- VideoEncoderTest.res
|       |-- ViewerLoaderTest.res
|       |-- VitestSmoke.test.bs.js
|       `-- VitestSmoke.test.res
`-- vitest.config.mjs

47 directories, 1695 files
